import React, { useState, useEffect } from 'react';
import { ArrowLeft, Bell, CheckCheck, RefreshCw } from 'lucide-react';
import { NotificationItem } from '../../types';
import { ApiClient } from '../../services/apiClient';

interface NotificationsScreenProps {
  onBack: () => void;
}

export const NotificationsScreen: React.FC<NotificationsScreenProps> = ({ onBack }) => {
  const [items, setItems] = useState<NotificationItem[]>([]);
  const [unreadCount, setUnreadCount] = useState<number>(0);
  const [loading, setLoading] = useState<boolean>(false);

  const loadNotifications = async () => {
    setLoading(true);
    try {
      const res = await ApiClient.get<{ data: { items: NotificationItem[]; unread_count: number } }>(
        '/v1/partner/notifications'
      );
      setItems(res?.data?.items || []);
      setUnreadCount(res?.data?.unread_count || 0);
    } catch {
      // error
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadNotifications();
  }, []);

  const markAllRead = async () => {
    try {
      await ApiClient.put('/v1/partner/notifications/read', { all: true });
      setItems((prev) => prev.map((n) => ({ ...n, read: true })));
      setUnreadCount(0);
    } catch {
      // error
    }
  };

  return (
    <div className="min-h-screen bg-[#0A1A0F] text-white">
      {/* Header */}
      <div className="sticky top-0 z-40 bg-[#0A1A0F]/95 backdrop-blur border-b border-[#1B3D22] px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            onClick={onBack}
            className="p-1.5 -ml-1 text-[#81C784] hover:text-[#00FF41] rounded-lg cursor-pointer"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <h2 className="text-base font-extrabold text-white">Notifications</h2>
        </div>

        <div className="flex items-center gap-2">
          {unreadCount > 0 && (
            <button
              onClick={markAllRead}
              className="flex items-center gap-1 text-xs font-bold text-[#00FF41] hover:underline cursor-pointer"
            >
              <CheckCheck className="w-4 h-4" />
              Mark all read
            </button>
          )}
          <button
            onClick={loadNotifications}
            disabled={loading}
            className="p-1.5 text-[#81C784] hover:text-[#00FF41] rounded-lg cursor-pointer"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="max-w-2xl mx-auto p-4 sm:p-5">
        {items.length === 0 ? (
          <div className="py-24 text-center">
            <Bell className="w-10 h-10 text-[#1B5E20] mx-auto mb-2" />
            <p className="text-sm text-[#9E9E9E]">No notifications yet</p>
          </div>
        ) : (
          <div className="space-y-3">
            {items.map((n) => (
              <div
                key={n.id}
                className={`p-4 rounded-xl border transition-all ${
                  n.read
                    ? 'bg-[#0D2B15] border-[#1B3D22]'
                    : 'bg-[#0F3318] border-[#1B5E20] shadow-md'
                }`}
              >
                <div className="flex items-center justify-between mb-1.5">
                  <h4 className="text-xs sm:text-sm font-bold text-white flex items-center gap-2">
                    {!n.read && (
                      <span className="w-2 h-2 rounded-full bg-[#00FF41] flex-shrink-0 animate-pulse" />
                    )}
                    {n.title}
                  </h4>
                  <span className="text-[10px] text-[#81C784] font-medium whitespace-nowrap">
                    {n.timestamp || 'Just now'}
                  </span>
                </div>
                <p className="text-xs text-[#81C784] leading-relaxed">
                  {n.message}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
