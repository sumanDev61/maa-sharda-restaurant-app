# Maa Sharda Go - Merchant Portal

A modern, production-ready React + TypeScript partner portal for restaurant and kitchen operations. Ported from Flutter to React (Vite).

## Key Features

- **Live Kitchen Order Management**:
  - Four distinct order pipelines: `NEW`, `PREPARING`, `READY FOR PICKUP`, and `OUT FOR DELIVERY`.
  - Wait time badges and incoming order synthesizer audio chime alerts.
  - Interactive prep time modal dialog (10–45 mins) when accepting orders.
  - Driver assignment details and pickup OTP generation for delivery partners.
- **Order History**:
  - Filtered completed/delivered and cancelled orders with item breakdowns, customer details, and refund status.
- **Menu Management**:
  - Full catalog listing with categories (Main Course, Biryani, Starters, etc.).
  - Veg / Non-veg indicators and bestseller markers.
  - Quick availability toggle, modal for adding/editing items, and photo uploads.
- **Store & Branding**:
  - Live kitchen status toggle (Open/Closed).
  - Delivery time estimate slider (10–60 mins) and Pure Veg badge configuration.
  - Restaurant logo and cover banner image management.
  - Coupon management with public/private visibility controls and discount amounts.
- **Partner Profile & Manager Account**:
  - Verified merchant profile badge and Partner ID.
  - Payout bank account details.
  - Manager profile contact information.
  - Commission tier (10%) and active legal agreements.
  - 24/7 Support access (Phone, WhatsApp, Email).
- **Notifications**:
  - Real-time order alerts and unread status markers.
- **Authentication & Onboarding**:
  - Mobile phone OTP login and multi-step partner registration (Basic info, OpenStreetMap location pin, FSSAI/GST compliance, and document uploads).

## Development

```bash
npm install
npm run dev
```

The application runs on port `3000`.

