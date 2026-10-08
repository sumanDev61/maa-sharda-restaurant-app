import React, { useState } from 'react';
import {
  ReceiptText,
  History,
  UtensilsCrossed,
  Store,
  User,
  Bell,
  Menu as MenuIcon,
  X,
  Power,
  ExternalLink,
  ShieldCheck,
  Headphones,
} from 'lucide-react';

interface MerchantShellProps {
  currentTab: 'orders' | 'history' | 'menu' | 'store' | 'profile';
  onTabChange: (tab: 'orders' | 'history' | 'menu' | 'store' | 'profile') => void;
  onOpenNotifications: () => void;
  unreadCount?: number;
  onLogout?: () => void;
  restaurantName?: string;
  children: React.ReactNode;
}

export const MerchantShell: React.FC<MerchantShellProps> = ({
  currentTab,
  onTabChange,
  onOpenNotifications,
  unreadCount = 0,
  onLogout,
  restaurantName = 'Maa Sharda Go',
  children,
}) => {
  const [drawerOpen, setDrawerOpen] = useState(false);

  return (
    <div className="min-h-screen bg-[#0A1A0F] text-white flex flex-col justify-between selection:bg-[#00FF41] selection:text-[#003300]">
      {/* Top App Bar */}
      <header className="sticky top-0 z-40 bg-[#0A1A0F]/95 backdrop-blur border-b border-[#1B3D22] px-4 py-2.5">
        <div className="max-w-2xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <button
              onClick={() => setDrawerOpen(true)}
              className="p-1.5 -ml-1 text-[#00FF41] hover:bg-[#1B5E20]/30 rounded-lg transition-colors cursor-pointer"
              title="Open Navigation Menu"
            >
              <MenuIcon className="w-6 h-6" />
            </button>
            <div>
              <h1 className="text-base sm:text-lg font-extrabold tracking-tight text-white leading-none">
                {restaurantName || 'Maa Sharda Go'}
              </h1>
              <span className="text-[10px] font-bold tracking-widest text-[#00FF41] uppercase">
                MERCHANT PORTAL
              </span>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={onOpenNotifications}
              className="relative p-2 text-[#00FF41] hover:bg-[#1B5E20]/30 rounded-lg transition-colors cursor-pointer"
              title="Notifications"
            >
              <Bell className="w-6 h-6" />
              {unreadCount > 0 && (
                <span className="absolute top-1.5 right-1.5 w-2.5 h-2.5 bg-red-500 rounded-full ring-2 ring-[#0A1A0F] animate-pulse" />
              )}
            </button>
          </div>
        </div>
      </header>

      {/* Main Screen Content */}
      <main className="flex-1 max-w-2xl w-full mx-auto pb-24 overflow-y-auto">
        {children}
      </main>

      {/* Bottom Navigation Bar */}
      <nav className="fixed bottom-0 left-0 right-0 z-40 bg-[#0D1F12] border-t border-[#1B3D22] safe-area-inset-bottom">
        <div className="max-w-2xl mx-auto flex items-center justify-around py-1.5 px-2">
          <button
            onClick={() => onTabChange('orders')}
            className={`flex flex-col items-center justify-center py-1 px-3 rounded-xl transition-all cursor-pointer ${
              currentTab === 'orders' ? 'text-[#00FF41]' : 'text-[#9E9E9E] hover:text-white'
            }`}
          >
            <ReceiptText className={`w-5 h-5 ${currentTab === 'orders' ? 'stroke-[2.5]' : 'stroke-2'}`} />
            <span className={`text-[10px] tracking-wider mt-1 ${currentTab === 'orders' ? 'font-bold' : 'font-medium'}`}>
              ORDERS
            </span>
          </button>

          <button
            onClick={() => onTabChange('history')}
            className={`flex flex-col items-center justify-center py-1 px-3 rounded-xl transition-all cursor-pointer ${
              currentTab === 'history' ? 'text-[#00FF41]' : 'text-[#9E9E9E] hover:text-white'
            }`}
          >
            <History className={`w-5 h-5 ${currentTab === 'history' ? 'stroke-[2.5]' : 'stroke-2'}`} />
            <span className={`text-[10px] tracking-wider mt-1 ${currentTab === 'history' ? 'font-bold' : 'font-medium'}`}>
              HISTORY
            </span>
          </button>

          <button
            onClick={() => onTabChange('menu')}
            className={`flex flex-col items-center justify-center py-1 px-3 rounded-xl transition-all cursor-pointer ${
              currentTab === 'menu' ? 'text-[#00FF41]' : 'text-[#9E9E9E] hover:text-white'
            }`}
          >
            <UtensilsCrossed className={`w-5 h-5 ${currentTab === 'menu' ? 'stroke-[2.5]' : 'stroke-2'}`} />
            <span className={`text-[10px] tracking-wider mt-1 ${currentTab === 'menu' ? 'font-bold' : 'font-medium'}`}>
              MENU
            </span>
          </button>

          <button
            onClick={() => onTabChange('store')}
            className={`flex flex-col items-center justify-center py-1 px-3 rounded-xl transition-all cursor-pointer ${
              currentTab === 'store' ? 'text-[#00FF41]' : 'text-[#9E9E9E] hover:text-white'
            }`}
          >
            <Store className={`w-5 h-5 ${currentTab === 'store' ? 'stroke-[2.5]' : 'stroke-2'}`} />
            <span className={`text-[10px] tracking-wider mt-1 ${currentTab === 'store' ? 'font-bold' : 'font-medium'}`}>
              RESTAURANT
            </span>
          </button>

          <button
            onClick={() => onTabChange('profile')}
            className={`flex flex-col items-center justify-center py-1 px-3 rounded-xl transition-all cursor-pointer ${
              currentTab === 'profile' ? 'text-[#00FF41]' : 'text-[#9E9E9E] hover:text-white'
            }`}
          >
            <User className={`w-5 h-5 ${currentTab === 'profile' ? 'stroke-[2.5]' : 'stroke-2'}`} />
            <span className={`text-[10px] tracking-wider mt-1 ${currentTab === 'profile' ? 'font-bold' : 'font-medium'}`}>
              PROFILE
            </span>
          </button>
        </div>
      </nav>

      {/* Side Drawer Modal */}
      {drawerOpen && (
        <div className="fixed inset-0 z-50 flex">
          <div
            className="fixed inset-0 bg-black/70 backdrop-blur-xs transition-opacity"
            onClick={() => setDrawerOpen(false)}
          />
          <div className="relative w-72 max-w-[80vw] bg-[#0A1A0F] border-r border-[#1B3D22] p-5 flex flex-col justify-between z-10 shadow-2xl">
            <div>
              <div className="flex items-center justify-between pb-4 border-b border-[#1B3D22]">
                <div className="flex items-center gap-2.5">
                  <div className="w-9 h-9 rounded-xl bg-[#0D2B15] border border-[#1B5E20] flex items-center justify-center text-[#00FF41] font-extrabold text-sm">
                    MS
                  </div>
                  <div>
                    <h2 className="font-bold text-sm text-white">Maa Sharda Go</h2>
                    <p className="text-[11px] text-[#81C784]">Partner v1.0.0</p>
                  </div>
                </div>
                <button
                  onClick={() => setDrawerOpen(false)}
                  className="p-1 text-[#9E9E9E] hover:text-white rounded-md"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="py-4 space-y-1">
                <button
                  onClick={() => {
                    onTabChange('orders');
                    setDrawerOpen(false);
                  }}
                  className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-semibold transition-colors ${
                    currentTab === 'orders' ? 'bg-[#0D2B15] text-[#00FF41]' : 'text-gray-300 hover:bg-[#0D2B15]/60'
                  }`}
                >
                  <ReceiptText className="w-4 h-4 text-[#00FF41]" />
                  Active Orders
                </button>
                <button
                  onClick={() => {
                    onTabChange('history');
                    setDrawerOpen(false);
                  }}
                  className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-semibold transition-colors ${
                    currentTab === 'history' ? 'bg-[#0D2B15] text-[#00FF41]' : 'text-gray-300 hover:bg-[#0D2B15]/60'
                  }`}
                >
                  <History className="w-4 h-4 text-[#00FF41]" />
                  Order History
                </button>
                <button
                  onClick={() => {
                    onTabChange('menu');
                    setDrawerOpen(false);
                  }}
                  className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-semibold transition-colors ${
                    currentTab === 'menu' ? 'bg-[#0D2B15] text-[#00FF41]' : 'text-gray-300 hover:bg-[#0D2B15]/60'
                  }`}
                >
                  <UtensilsCrossed className="w-4 h-4 text-[#00FF41]" />
                  Menu Items
                </button>
                <button
                  onClick={() => {
                    onTabChange('store');
                    setDrawerOpen(false);
                  }}
                  className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-semibold transition-colors ${
                    currentTab === 'store' ? 'bg-[#0D2B15] text-[#00FF41]' : 'text-gray-300 hover:bg-[#0D2B15]/60'
                  }`}
                >
                  <Store className="w-4 h-4 text-[#00FF41]" />
                  Store & Coupons
                </button>
                <button
                  onClick={() => {
                    onTabChange('profile');
                    setDrawerOpen(false);
                  }}
                  className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-semibold transition-colors ${
                    currentTab === 'profile' ? 'bg-[#0D2B15] text-[#00FF41]' : 'text-gray-300 hover:bg-[#0D2B15]/60'
                  }`}
                >
                  <User className="w-4 h-4 text-[#00FF41]" />
                  Merchant Profile
                </button>
              </div>

              <div className="pt-2 border-t border-[#1B3D22] space-y-1">
                <button
                  onClick={() => {
                    onOpenNotifications();
                    setDrawerOpen(false);
                  }}
                  className="w-full flex items-center justify-between px-3 py-2 text-xs text-gray-300 hover:bg-[#0D2B15]/60 rounded-lg"
                >
                  <span className="flex items-center gap-2.5">
                    <Bell className="w-4 h-4 text-[#81C784]" />
                    Notifications
                  </span>
                  {unreadCount > 0 && (
                    <span className="bg-[#00FF41] text-[#003300] px-1.5 py-0.5 rounded text-[10px] font-bold">
                      {unreadCount}
                    </span>
                  )}
                </button>
              </div>
            </div>

            <div className="pt-4 border-t border-[#1B3D22]">
              {onLogout && (
                <button
                  onClick={() => {
                    setDrawerOpen(false);
                    onLogout();
                  }}
                  className="w-full flex items-center gap-2 px-3 py-2 text-sm text-red-400 hover:bg-red-500/10 rounded-lg transition-colors font-medium cursor-pointer"
                >
                  <Power className="w-4 h-4" />
                  Sign Out
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
