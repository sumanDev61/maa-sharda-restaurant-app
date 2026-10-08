import React, { useState, useEffect } from 'react';
import { PartnerSession } from './services/session';
import { MerchantShell } from './components/MerchantShell';
import { OrdersScreen } from './features/orders/OrdersScreen';
import { HistoryScreen } from './features/orders/HistoryScreen';
import { MenuScreen } from './features/menu/MenuScreen';
import { StoreScreen } from './features/store/StoreScreen';
import { ProfileScreen } from './features/profile/ProfileScreen';
import { NotificationsScreen } from './features/notifications/NotificationsScreen';
import { LoginScreen } from './features/auth/LoginScreen';
import { RegistrationFlow } from './features/auth/RegistrationFlow';
import { ApplicationReviewScreen } from './features/auth/ApplicationReviewScreen';
import { ApiClient } from './services/apiClient';

export const App: React.FC = () => {
  const [session, setSession] = useState(PartnerSession.load());
  const [currentTab, setCurrentTab] = useState<'orders' | 'history' | 'menu' | 'store' | 'profile'>('orders');
  const [viewingNotifications, setViewingNotifications] = useState(false);
  const [isRegistering, setIsRegistering] = useState(false);
  const [registerPhone, setRegisterPhone] = useState('');
  const [unreadNotifications, setUnreadNotifications] = useState(0);

  useEffect(() => {
    const unsub = PartnerSession.subscribe((newSession) => {
      setSession(newSession);
    });
    return unsub;
  }, []);

  useEffect(() => {
    if (!session.token) return;
    const fetchUnread = async () => {
      try {
        const res = await ApiClient.get<{ data: { unread_count: number } }>('/v1/partner/notifications');
        if (res?.data?.unread_count !== undefined) {
          setUnreadNotifications(res.data.unread_count);
        }
      } catch {
        // ignore
      }
    };
    fetchUnread();
  }, [session.token, viewingNotifications]);

  const handleLogout = () => {
    PartnerSession.clear();
    setSession(PartnerSession.load());
    setIsRegistering(false);
    setViewingNotifications(false);
    setCurrentTab('orders');
  };

  // 1. If currently in registration flow
  if (isRegistering) {
    return (
      <RegistrationFlow
        initialPhone={registerPhone}
        onCompleted={() => {
          setIsRegistering(false);
          setSession(PartnerSession.load());
        }}
        onCancel={() => setIsRegistering(false)}
      />
    );
  }

  // 2. If not logged in -> Show Login Screen
  if (!session.token) {
    return (
      <LoginScreen
        onSuccess={() => {
          setSession(PartnerSession.load());
        }}
        onRegisterRequired={(phone) => {
          setRegisterPhone(phone);
          setIsRegistering(true);
        }}
      />
    );
  }

  // 3. If logged in but approvalStatus is pending or inReview (Waiting for Admin Approval)
  if (session.approvalStatus === 'inReview' || session.approvalStatus === 'pending') {
    return (
      <ApplicationReviewScreen
        restaurantName={session.restaurantName || 'Partner Restaurant'}
        restaurantId={session.restaurantId || ''}
        onStatusApproved={() => {
          setSession(PartnerSession.load());
        }}
        onLogout={handleLogout}
      />
    );
  }

  // 4. If viewing notifications screen
  if (viewingNotifications) {
    return (
      <NotificationsScreen
        onBack={() => setViewingNotifications(false)}
      />
    );
  }

  // 4. Main Authenticated Merchant Shell
  return (
    <MerchantShell
      currentTab={currentTab}
      onTabChange={(tab) => setCurrentTab(tab)}
      onOpenNotifications={() => setViewingNotifications(true)}
      unreadCount={unreadNotifications}
      onLogout={handleLogout}
      restaurantName={session.restaurantName || 'Maa Sharda Go'}
    >
      {currentTab === 'orders' && <OrdersScreen />}
      {currentTab === 'history' && <HistoryScreen />}
      {currentTab === 'menu' && <MenuScreen />}
      {currentTab === 'store' && <StoreScreen />}
      {currentTab === 'profile' && (
        <ProfileScreen
          onLogout={handleLogout}
          onNavigateToReview={() => setIsRegistering(true)}
        />
      )}
    </MerchantShell>
  );
};

export default App;
