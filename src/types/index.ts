export type OrderStatus =
  | 'incoming'
  | 'preparing'
  | 'ready'
  | 'outForDelivery'
  | 'delivered'
  | 'cancelled';

export type DeliveryType = 'priorityDelivery' | 'selfPickup' | 'delivery';

export interface OrderItem {
  name: string;
  quantity: number;
  price: number;
}

export interface MerchantOrder {
  orderId: string;
  customerName: string;
  deliveryType: DeliveryType;
  items: OrderItem[];
  waitTime: string;
  status: OrderStatus;
  statusRaw: string;
  pickupOtp?: string;
  driverName?: string;
  driverPhone?: string;
  driverStatus?: string;
  refundStatus?: string;
}

export interface PartnerMenuItem {
  id: string;
  name: string;
  category?: string;
  price: number;
  prepTimeMinutes: number;
  isVeg: boolean;
  isBestseller: boolean;
  status: 'Available' | 'Unavailable' | string;
  description?: string;
  imageUrl?: string;
}

export type CouponVisibility = 'public' | 'private';

export interface CouponItem {
  id: string;
  code: string;
  title: string;
  subtitle: string;
  discount: number;
  visibility: CouponVisibility;
  status: string;
}

export interface RegistrationDraft {
  phone: string;
  restaurantName: string;
  ownerName: string;
  ownerPhone: string;
  email: string;
  cuisine: string;
  address: string;
  latitude: number | null;
  longitude: number | null;
  fssaiNumber: string;
  gstNumber: string;
  panNumber: string;
  documents: Record<string, string>;
  documentsUrls: Record<string, string>;
}

export interface PartnerProfile {
  id: string;
  name: string;
  phone: string;
  address: string;
  owner_name: string;
  owner_email: string;
  image_url: string;
  cover_url?: string;
  status: string;
  delivery_minutes: number;
  is_pure_veg: boolean;
  approval_status: 'approved' | 'inReview' | 'rejected' | string;
}

export interface NotificationItem {
  id: string;
  title: string;
  message: string;
  read: boolean;
  timestamp: string;
}
