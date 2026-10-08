const K_TOKEN = 'partner_token';
const K_RESTAURANT_ID = 'partner_restaurant_id';
const K_APPROVAL_STATUS = 'partner_approval_status';
const K_RESTAURANT_NAME = 'partner_restaurant_name';

export interface SessionData {
  token: string | null;
  restaurantId: string | null;
  approvalStatus: string | null;
  restaurantName: string | null;
}

class SessionService {
  private data: SessionData = {
    token: null,
    restaurantId: null,
    approvalStatus: null,
    restaurantName: null,
  };

  private listeners: Array<(session: SessionData) => void> = [];

  constructor() {
    this.load();
  }

  load(): SessionData {
    try {
      this.data = {
        token: localStorage.getItem(K_TOKEN),
        restaurantId: localStorage.getItem(K_RESTAURANT_ID),
        approvalStatus: localStorage.getItem(K_APPROVAL_STATUS),
        restaurantName: localStorage.getItem(K_RESTAURANT_NAME),
      };
    } catch {
      // storage unavailable
    }
    return this.data;
  }

  get token(): string | null {
    return this.data.token;
  }

  get restaurantId(): string | null {
    return this.data.restaurantId;
  }

  get approvalStatus(): string | null {
    return this.data.approvalStatus;
  }

  get restaurantName(): string | null {
    return this.data.restaurantName;
  }

  get isLoggedIn(): boolean {
    return Boolean(this.data.token && this.data.restaurantId);
  }

  save(params: {
    token: string;
    restaurantId: string;
    approvalStatus?: string;
    restaurantName?: string;
  }): void {
    this.data.token = params.token;
    this.data.restaurantId = params.restaurantId;
    if (params.approvalStatus !== undefined) {
      this.data.approvalStatus = params.approvalStatus;
    }
    if (params.restaurantName !== undefined) {
      this.data.restaurantName = params.restaurantName;
    }

    try {
      localStorage.setItem(K_TOKEN, params.token);
      localStorage.setItem(K_RESTAURANT_ID, params.restaurantId);
      if (params.approvalStatus) {
        localStorage.setItem(K_APPROVAL_STATUS, params.approvalStatus);
      }
      if (params.restaurantName) {
        localStorage.setItem(K_RESTAURANT_NAME, params.restaurantName);
      }
    } catch {
      // ignore
    }

    this.notify();
  }

  clear(): void {
    this.data = {
      token: null,
      restaurantId: null,
      approvalStatus: null,
      restaurantName: null,
    };
    try {
      localStorage.removeItem(K_TOKEN);
      localStorage.removeItem(K_RESTAURANT_ID);
      localStorage.removeItem(K_APPROVAL_STATUS);
      localStorage.removeItem(K_RESTAURANT_NAME);
    } catch {
      // ignore
    }
    this.notify();
  }

  subscribe(listener: (session: SessionData) => void): () => void {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter((l) => l !== listener);
    };
  }

  private notify() {
    for (const listener of this.listeners) {
      listener({ ...this.data });
    }
  }

  // Preload a verified demo restaurant session for instant testing if needed
  setDemoSession(status: 'approved' | 'inReview' = 'approved'): void {
    this.save({
      token: 'demo-partner-token-' + Date.now(),
      restaurantId: 'REST-7890',
      approvalStatus: status,
      restaurantName: "Maa Sharda Grand Kitchen",
    });
  }
}

export const PartnerSession = new SessionService();
