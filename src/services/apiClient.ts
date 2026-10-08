import { Env } from '../config/env';
import { PartnerSession } from './session';
import {
  INITIAL_ORDERS,
  INITIAL_MENU,
  INITIAL_COUPONS,
  INITIAL_PROFILE,
  INITIAL_NOTIFICATIONS,
} from './mockData';
import { MerchantOrder, PartnerMenuItem, CouponItem, PartnerProfile, NotificationItem, OrderStatus } from '../types';

export class ApiException extends Error {
  statusCode: number;
  constructor(statusCode: number, message: string) {
    super(message);
    this.statusCode = statusCode;
    this.name = 'ApiException';
  }
}

// In-memory store that persists across component re-renders
class LocalStore {
  orders: MerchantOrder[] = [...INITIAL_ORDERS];
  menu: PartnerMenuItem[] = [...INITIAL_MENU];
  coupons: CouponItem[] = [...INITIAL_COUPONS];
  profile: PartnerProfile = { ...INITIAL_PROFILE };
  notifications: NotificationItem[] = [...INITIAL_NOTIFICATIONS];
}

const store = new LocalStore();

class ApiClientService {
  private get baseUrl(): string {
    return Env.apiBaseUrl;
  }

  private get headers(): Record<string, string> {
    const h: Record<string, string> = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    };
    const token = PartnerSession.token;
    if (token) {
      h['Authorization'] = `Bearer ${token}`;
    }
    return h;
  }

  async get<T = any>(path: string): Promise<T> {
    try {
      const res = await fetch(`${this.baseUrl}${path}`, {
        headers: this.headers,
      });
      if (res.ok) {
        return (await res.json()) as T;
      }
      throw new ApiException(res.status, `HTTP ${res.status}`);
    } catch {
      // Fallback to local store
      return this.handleLocalGet(path) as unknown as T;
    }
  }

  async post<T = any>(path: string, body?: any): Promise<T> {
    try {
      const res = await fetch(`${this.baseUrl}${path}`, {
        method: 'POST',
        headers: this.headers,
        body: body ? JSON.stringify(body) : undefined,
      });
      if (res.ok) {
        return (await res.json()) as T;
      }
      throw new ApiException(res.status, `HTTP ${res.status}`);
    } catch {
      return this.handleLocalPost(path, body) as unknown as T;
    }
  }

  async put<T = any>(path: string, body?: any): Promise<T> {
    try {
      const res = await fetch(`${this.baseUrl}${path}`, {
        method: 'PUT',
        headers: this.headers,
        body: body ? JSON.stringify(body) : undefined,
      });
      if (res.ok) {
        const text = await res.text();
        return (text ? JSON.parse(text) : {}) as T;
      }
      throw new ApiException(res.status, `HTTP ${res.status}`);
    } catch {
      return this.handleLocalPut(path, body) as unknown as T;
    }
  }

  async uploadImage(file: File, folder = 'partner-menu'): Promise<{ data: { url: string } }> {
    try {
      const formData = new FormData();
      formData.append('folder', folder);
      formData.append('image', file);
      const res = await fetch(`${this.baseUrl}/v1/partner/upload`, {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          ...(PartnerSession.token ? { Authorization: `Bearer ${PartnerSession.token}` } : {}),
        },
        body: formData,
      });
      if (res.ok) {
        return (await res.json()) as { data: { url: string } };
      }
    } catch {
      // ignore
    }
    // Return an object URL for local preview
    const localUrl = URL.createObjectURL(file);
    return { data: { url: localUrl } };
  }

  async uploadRegistrationImage(file: File, folder = 'partner-registration'): Promise<{ data: { url: string } }> {
    try {
      const formData = new FormData();
      formData.append('folder', folder);
      formData.append('image', file);
      const res = await fetch(`${this.baseUrl}/v1/partner/upload-registration`, {
        method: 'POST',
        headers: { Accept: 'application/json' },
        body: formData,
      });
      if (res.ok) {
        return (await res.json()) as { data: { url: string } };
      }
    } catch {
      // ignore
    }
    const localUrl = URL.createObjectURL(file);
    return { data: { url: localUrl } };
  }

  // --- Local Fallback Handlers ---
  private handleLocalGet(path: string): any {
    if (path.includes('/v1/partner/orders')) {
      return { data: store.orders };
    }
    if (path.includes('/menu')) {
      return { data: { items: store.menu } };
    }
    if (path.includes('/v1/partner/coupons')) {
      return { data: { coupons: store.coupons } };
    }
    if (path.includes('/v1/partner/profile')) {
      return { data: store.profile };
    }
    if (path.includes('/v1/restaurants/')) {
      return { data: store.profile };
    }
    if (path.includes('/v1/partner/notifications')) {
      const unreadCount = store.notifications.filter((n) => !n.read).length;
      return {
        data: {
          items: store.notifications,
          unread_count: unreadCount,
        },
      };
    }
    return { data: {} };
  }

  private handleLocalPost(path: string, body: any): any {
    if (path.includes('/v1/partner/auth/login')) {
      const phone = body?.phone || '';
      return {
        data: {
          restaurant_id: store.profile.id,
          phone,
        },
      };
    }
    if (path.includes('/v1/partner/auth/verify-otp')) {
      return {
        data: {
          token: 'auth-tok-' + Math.random().toString(36).substring(2, 9),
          restaurant: {
            id: store.profile.id,
            name: store.profile.name,
            approval_status: store.profile.approval_status,
          },
        },
      };
    }
    if (path.includes('/v1/partner/auth/register')) {
      if (body?.name) store.profile.name = body.name;
      if (body?.phone) store.profile.phone = body.phone;
      if (body?.owner_name) store.profile.owner_name = body.owner_name;
      if (body?.owner_email) store.profile.owner_email = body.owner_email;
      if (body?.address) store.profile.address = body.address;
      store.profile.approval_status = 'inReview';
      return {
        data: {
          restaurant_id: store.profile.id,
        },
      };
    }
    return { data: {} };
  }

  private handleLocalPut(path: string, body: any): any {
    if (path.includes('/v1/partner/orders/')) {
      const match = path.match(/\/orders\/([^/?]+)/);
      const orderId = match ? match[1] : '';
      const order = store.orders.find((o) => o.orderId === orderId);
      if (order && body) {
        if (body.action === 'accept') {
          order.status = 'preparing';
          order.statusRaw = 'ACCEPTED_BY_MERCHANT';
          order.waitTime = `${String(body.prep_time_minutes || 15).padStart(2, '0')}:00`;
        } else if (body.action === 'reject') {
          order.status = 'cancelled';
          order.statusRaw = 'REJECTED_BY_MERCHANT';
        } else if (body.action === 'ready') {
          order.status = 'ready';
          order.statusRaw = 'READY_FOR_PICKUP';
          if (!order.pickupOtp) {
            order.pickupOtp = Math.floor(1000 + Math.random() * 9000).toString();
          }
          if (!order.driverName) {
            order.driverName = 'Rahul Verma (Delivery Partner)';
            order.driverPhone = '+91 98765 43210';
            order.driverStatus = 'DRIVER_ARRIVED_AT_MERCHANT';
          }
        } else if (body.action === 'handover') {
          order.status = 'outForDelivery';
          order.statusRaw = 'OUT_FOR_DELIVERY';
        }
      }
      return { data: order };
    }

    if (path.includes('/v1/partner/menu')) {
      if (body?.upserts) {
        for (const upsert of body.upserts) {
          const id = upsert.id || `item-${Date.now()}-${Math.random().toString(36).substring(2, 5)}`;
          const existingIdx = store.menu.findIndex((m) => m.id === id);
          const formatted: PartnerMenuItem = {
            id,
            name: upsert.name || 'Menu Item',
            category: upsert.category || 'Main Course',
            price: Number(upsert.price) || 0,
            prepTimeMinutes: Number(upsert.prep_time_minutes) || 15,
            isVeg: Boolean(upsert.is_veg),
            isBestseller: Boolean(upsert.is_bestseller),
            status: upsert.status || 'Available',
            description: upsert.description,
            imageUrl: upsert.image_url,
          };
          if (existingIdx >= 0) {
            store.menu[existingIdx] = formatted;
          } else {
            store.menu.unshift(formatted);
          }
        }
      }
      if (body?.deletes) {
        store.menu = store.menu.filter((m) => !body.deletes.includes(m.id));
      }
      return { data: { items: store.menu } };
    }

    if (path.includes('/v1/partner/coupons')) {
      if (body?.upserts) {
        for (const upsert of body.upserts) {
          const id = upsert.id || `c-${Date.now()}`;
          const existingIdx = store.coupons.findIndex((c) => c.id === id);
          const formatted: CouponItem = {
            id,
            code: (upsert.code || '').toUpperCase(),
            title: upsert.title || '',
            subtitle: upsert.subtitle || '',
            discount: Number(upsert.discount) || 0,
            visibility: upsert.visibility === 'private' ? 'private' : 'public',
            status: upsert.status || 'Active',
          };
          if (existingIdx >= 0) {
            store.coupons[existingIdx] = formatted;
          } else {
            store.coupons.unshift(formatted);
          }
        }
      }
      if (body?.deletes) {
        store.coupons = store.coupons.filter((c) => !body.deletes.includes(c.id));
      }
      return { data: { coupons: store.coupons } };
    }

    if (path.includes('/v1/partner/status')) {
      if (body?.status) store.profile.status = body.status;
      if (body?.delivery_minutes !== undefined) store.profile.delivery_minutes = body.delivery_minutes;
      if (body?.is_pure_veg !== undefined) store.profile.is_pure_veg = body.is_pure_veg;
      if (body?.image_url) store.profile.image_url = body.image_url;
      if (body?.cover_url) store.profile.cover_url = body.cover_url;
      return { data: store.profile };
    }

    if (path.includes('/v1/partner/notifications/read')) {
      store.notifications.forEach((n) => (n.read = true));
      return { data: { success: true } };
    }

    return { data: {} };
  }
}

export const ApiClient = new ApiClientService();
