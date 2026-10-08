import React, { useState, useEffect } from 'react';
import { RefreshCw, CheckCircle2, XCircle } from 'lucide-react';
import { MerchantOrder } from '../../types';
import { ApiClient } from '../../services/apiClient';
import { PartnerSession } from '../../services/session';

export const HistoryScreen: React.FC = () => {
  const [orders, setOrders] = useState<MerchantOrder[]>([]);
  const [loading, setLoading] = useState<boolean>(false);

  const loadHistory = async () => {
    setLoading(true);
    try {
      const rid = PartnerSession.restaurantId || '';
      const res = await ApiClient.get<{ data: MerchantOrder[] }>(`/v1/partner/orders?restaurant_id=${rid}`);
      const list = res?.data || [];
      setOrders(list.filter((o) => o.status === 'delivered' || o.status === 'cancelled'));
    } catch {
      // fallback handled
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadHistory();
  }, []);

  return (
    <div className="p-4 sm:p-5">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-lg font-extrabold text-white">Order History</h2>
          <p className="text-xs text-[#81C784]">Completed and cancelled kitchen orders</p>
        </div>
        <button
          onClick={loadHistory}
          disabled={loading}
          className="p-2 text-[#81C784] hover:text-[#00FF41] rounded-lg transition-colors cursor-pointer"
          title="Refresh History"
        >
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
        </button>
      </div>

      {orders.length === 0 ? (
        <div className="py-24 text-center">
          <p className="text-sm text-[#9E9E9E]">No completed orders yet</p>
        </div>
      ) : (
        <div className="space-y-3.5">
          {orders.map((order) => {
            const isDelivered = order.status === 'delivered';
            const total = order.items.reduce((acc, it) => acc + it.price, 0);

            return (
              <div
                key={order.orderId}
                className="bg-[#0D2B15] border border-[#1B3D22] rounded-2xl p-4 sm:p-5 shadow-md"
              >
                <div className="flex items-center justify-between mb-2">
                  <span className="text-lg font-extrabold text-white">
                    #{order.orderId}
                  </span>
                  <span
                    className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-extrabold tracking-wider ${
                      isDelivered
                        ? 'bg-[#1B5E20] text-[#00FF41]'
                        : 'bg-red-500/15 text-red-400'
                    }`}
                  >
                    {isDelivered ? <CheckCircle2 className="w-3 h-3" /> : <XCircle className="w-3 h-3" />}
                    {isDelivered ? 'DELIVERED' : 'CANCELLED'}
                  </span>
                </div>

                <div className="text-xs text-[#81C784] mb-3 font-medium">
                  Customer: <span className="text-white font-semibold">{order.customerName}</span>
                </div>

                <div className="bg-[#0F3318] rounded-xl p-3 border border-[#1B3D22] mb-3 space-y-1">
                  {order.items.slice(0, 3).map((it, idx) => (
                    <div key={idx} className="flex justify-between text-xs text-[#81C784]">
                      <span>{it.quantity}x {it.name}</span>
                      <span className="text-white font-medium">₹{it.price.toFixed(0)}</span>
                    </div>
                  ))}
                  {order.items.length > 3 && (
                    <div className="text-[11px] text-[#9E9E9E] pt-1">
                      +{order.items.length - 3} more items
                    </div>
                  )}
                </div>

                {!isDelivered && order.refundStatus && (
                  <div className="text-xs text-[#81C784] mb-2 bg-red-950/20 border border-red-900/40 rounded-lg p-2">
                    <span className="font-semibold text-red-400">Refund: </span>
                    {order.refundStatus}
                  </div>
                )}

                <div className="flex justify-between items-center pt-1 border-t border-[#1B3D22]">
                  <span className="text-xs text-[#9E9E9E]">Total Bill</span>
                  <span className="text-sm font-extrabold text-white">
                    ₹{total.toFixed(0)}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
