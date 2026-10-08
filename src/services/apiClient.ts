import { Env } from '../config/env';
import { PartnerSession } from './session';

export class ApiException extends Error {
  statusCode: number;
  constructor(statusCode: number, message: string) {
    super(message);
    this.statusCode = statusCode;
    this.name = 'ApiException';
  }
}

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
    const res = await fetch(`${this.baseUrl}${path}`, {
      headers: this.headers,
    });
    if (res.ok) {
      return (await res.json()) as T;
    }
    const errBody = await res.json().catch(() => null);
    throw new ApiException(res.status, errBody?.message || errBody?.error || `HTTP ${res.status}`);
  }

  async post<T = any>(path: string, body?: any): Promise<T> {
    const res = await fetch(`${this.baseUrl}${path}`, {
      method: 'POST',
      headers: this.headers,
      body: body ? JSON.stringify(body) : undefined,
    });
    if (res.ok) {
      return (await res.json()) as T;
    }
    const errBody = await res.json().catch(() => null);
    throw new ApiException(res.status, errBody?.message || errBody?.error || `HTTP ${res.status}`);
  }

  async put<T = any>(path: string, body?: any): Promise<T> {
    const res = await fetch(`${this.baseUrl}${path}`, {
      method: 'PUT',
      headers: this.headers,
      body: body ? JSON.stringify(body) : undefined,
    });
    if (res.ok) {
      const text = await res.text();
      return (text ? JSON.parse(text) : {}) as T;
    }
    const errBody = await res.json().catch(() => null);
    throw new ApiException(res.status, errBody?.message || errBody?.error || `HTTP ${res.status}`);
  }

  async uploadImage(file: File, folder = 'partner-menu'): Promise<{ data: { url: string } }> {
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
    const errBody = await res.json().catch(() => null);
    throw new ApiException(res.status, errBody?.message || 'Image upload failed');
  }

  async uploadRegistrationImage(file: File, folder = 'partner-registration'): Promise<{ data: { url: string } }> {
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
    const errBody = await res.json().catch(() => null);
    throw new ApiException(res.status, errBody?.message || 'Registration document upload failed');
  }
}

export const ApiClient = new ApiClientService();
