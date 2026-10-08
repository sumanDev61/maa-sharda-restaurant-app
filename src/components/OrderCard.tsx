import React from 'react';
import { User, Phone, CheckCircle2 } from 'lucide-react';
import { MerchantOrder, OrderStatus } from '../types';

interface OrderCardProps {
  order: MerchantOrder;
  onAccept?: (order: MerchantOrder) => void;
  onReject?: (order: MerchantOrder) => void;
  onReady?: (order: MerchantOrder) => void;
}

export const OrderCard: React.FC<OrderCardProps> = ({
  order,
  onAccept,
  onReject,
  onReady,
}) => {
  const getStatusLabel = (status: OrderStatus): string => {
    switch (status) {
      case 'incoming':
        return 'INCOMING ORDER';
      case 'preparing':
        return 'PREPARING';
      case 'ready':
        return 'READY FOR PICKUP';
      case 'outForDelivery':
        return 'OUT FOR DELIVERY';
      case 'delivered':
        return 'DELIVERED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return String(status).toUpperCase();
    }
  };

  const getDeliveryTypeLabel = (type: string): string => {
    switch (type) {
      case 'priorityDelivery':
        return 'Priority Delivery';
      case 'selfPickup':
        return 'Self-Pickup';
      default:
        return 'Delivery';
    }
  };

  const getDriverStatusLabel = (raw: string): string => {
    const s = raw.toUpperCase();
    if (s === 'DRIVER_ASSIGNED') return 'DRIVER ASSIGNED';
    if (s === 'DRIVER_ARRIVED_AT_MERCHANT') return 'DRIVER ARRIVED AT KITCHEN';
    if (s === 'PICKED_UP') return 'ORDER PICKED UP';
    if (s === 'EN_ROUTE_TO_CUSTOMER') return 'OUT FOR DELIVERY';
    if (s === 'ARRIVED_AT_CUSTOMER') return 'ARRIVED AT CUSTOMER';
    if (s === 'DELIVERED') return 'DELIVERED';
    return 'IN TRANSIT';
  };

  const canHandover = Boolean(order.driverName);

  return (
    <div className="bg-[#0D2B15] border border-[#1B5E20] rounded-2xl p-4 sm:p-5 mb-4 shadow-lg transition-all">
      {/* Header: Status & Wait Time */}
      <div className="flex items-center justify-between mb-1.5">
        <span className="text-[11px] font-bold tracking-wider text-[#00FF41]">
          {getStatusLabel(order.status)}
        </span>
        <div className="text-right">
          <div
            className={`text-xl font-bold font-mono leading-none ${
              order.status === 'incoming' ? 'text-[#00FF41]' : 'text-[#81C784]'
            }`}
          >
            {order.waitTime}
          </div>
          <span className="text-[10px] font-medium tracking-wider text-[#9E9E9E] uppercase">
            WAIT TIME
          </span>
        </div>
      </div>

      {/* Order ID */}
      <h2 className="text-2xl sm:text-3xl font-extrabold text-white mb-3">
        #{order.orderId}
      </h2>

      {/* Customer Info */}
      <div className="flex items-center gap-3 mb-3">
        <div className="w-10 h-10 rounded-full bg-[#1B5E20] flex items-center justify-center text-[#81C784]">
          <User className="w-5 h-5" />
        </div>
        <div>
          <div className="font-bold text-white text-base leading-tight">
            {order.customerName}
          </div>
          <div className="text-xs text-[#81C784]">
            {getDeliveryTypeLabel(order.deliveryType)}
          </div>
        </div>
      </div>

      {/* Pickup OTP (if ready or out for delivery) */}
      {(order.status === 'ready' || order.status === 'outForDelivery') && order.pickupOtp && (
        <div className="bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3.5 py-2 mb-3 flex items-center justify-between">
          <span className="text-xs font-semibold text-[#81C784]">Pickup OTP</span>
          <span className="text-lg font-extrabold text-white tracking-widest font-mono">
            {order.pickupOtp}
          </span>
        </div>
      )}

      {/* Driver Info Banner (if assigned) */}
      {order.driverName && (
        <div className="bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3.5 py-2.5 mb-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 rounded-full bg-[#00FF41] animate-ping" />
            <span className="text-xs font-semibold text-[#81C784]">Driver Assigned</span>
          </div>
          <div className="text-right">
            <div className="text-sm font-extrabold text-white">{order.driverName}</div>
            {order.driverPhone && (
              <a
                href={`tel:${order.driverPhone}`}
                className="text-xs text-[#81C784] hover:underline flex items-center justify-end gap-1"
              >
                <Phone className="w-3 h-3" />
                {order.driverPhone}
              </a>
            )}
          </div>
        </div>
      )}

      {/* Items List */}
      <div className="bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3.5 py-3 mb-4 divide-y divide-[#1B3D22]">
        {order.items.map((item, idx) => (
          <div key={idx} className="flex items-center justify-between py-1.5 first:pt-0 last:pb-0 text-sm">
            <span className="text-[#81C784] font-medium">
              {item.quantity}x {item.name}
            </span>
            <span className="text-white font-semibold">
              ₹{item.price.toFixed(0)}
            </span>
          </div>
        ))}
      </div>

      {/* Action Buttons */}
      <div>
        {order.status === 'incoming' && (
          <div className="flex items-center gap-3">
            <button
              onClick={() => onReject?.(order)}
              className="px-5 py-3 rounded-xl border border-[#00FF41] text-[#00FF41] font-bold text-xs sm:text-sm tracking-wider hover:bg-[#00FF41]/10 transition-colors cursor-pointer"
            >
              REJECT
            </button>
            <button
              onClick={() => onAccept?.(order)}
              className="flex-1 py-3 px-4 rounded-xl bg-[#00FF41] text-[#003300] font-extrabold text-sm tracking-wider hover:bg-[#00e63a] active:scale-[0.99] transition-all cursor-pointer shadow-md"
            >
              ACCEPT ORDER
            </button>
          </div>
        )}

        {order.status === 'preparing' && (
          <button
            onClick={() => onReady?.(order)}
            className="w-full py-3.5 px-4 rounded-xl bg-[#00FF41] text-[#003300] font-extrabold text-sm tracking-wider hover:bg-[#00e63a] active:scale-[0.99] transition-all cursor-pointer shadow-md flex items-center justify-center gap-2"
          >
            <CheckCircle2 className="w-5 h-5" />
            MARK READY
          </button>
        )}

        {order.status === 'ready' && (
          <button
            onClick={canHandover ? () => onReady?.(order) : undefined}
            disabled={!canHandover}
            className={`w-full py-3.5 px-4 rounded-xl font-extrabold text-sm tracking-wider transition-all flex items-center justify-center gap-2 ${
              canHandover
                ? 'bg-[#00FF41] text-[#003300] hover:bg-[#00e63a] cursor-pointer shadow-md'
                : 'bg-[#1B5E20]/40 text-[#81C784]/60 border border-[#1B3D22] cursor-not-allowed'
            }`}
          >
            {canHandover ? 'HANDOVER TO DRIVER' : 'WAITING FOR DRIVER'}
          </button>
        )}

        {order.status === 'outForDelivery' && (
          <div className="w-full py-3 px-4 rounded-xl border border-[#1B3D22] bg-[#0A1A0F]/60 text-[#81C784] font-bold text-xs tracking-wider text-center uppercase">
            {getDriverStatusLabel(order.statusRaw)}
          </div>
        )}

        {order.status === 'delivered' && (
          <div className="w-full py-2.5 px-4 rounded-xl bg-[#1B5E20]/30 text-[#00FF41] font-bold text-xs tracking-wider text-center flex items-center justify-center gap-2">
            <CheckCircle2 className="w-4 h-4" />
            DELIVERED
          </div>
        )}

        {order.status === 'cancelled' && (
          <div className="w-full py-2.5 px-4 rounded-xl bg-red-500/10 text-red-400 font-bold text-xs tracking-wider text-center">
            CANCELLED {order.refundStatus ? `• ${order.refundStatus}` : ''}
          </div>
        )}
      </div>
    </div>
  );
};
