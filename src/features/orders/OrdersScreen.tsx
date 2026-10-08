import React, { useState, useEffect, useRef, useCallback } from 'react';
import { RefreshCw, Volume2, VolumeX, Clock, ChevronDown } from 'lucide-react';
import { MerchantOrder, OrderStatus } from '../../types';
import { OrderCard } from '../../components/OrderCard';
import { ApiClient } from '../../services/apiClient';
import { PartnerSession } from '../../services/session';
import { Env } from '../../config/env';

export const OrdersScreen: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'incoming' | 'preparing' | 'ready' | 'outForDelivery'>('incoming');
  const [orders, setOrders] = useState<MerchantOrder[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [prepDialogOrder, setPrepDialogOrder] = useState<MerchantOrder | null>(null);
  const [selectedPrepTime, setSelectedPrepTime] = useState<number>(15);
  const [soundEnabled, setSoundEnabled] = useState<boolean>(true);
  const [showAllIncoming, setShowAllIncoming] = useState<boolean>(false);

  const audioCtxRef = useRef<AudioContext | null>(null);
  const ringIntervalRef = useRef<number | null>(null);
  const knownIncomingRef = useRef<Set<String>>(new Set());

  // Web Audio chime generator
  const playAlertChime = useCallback(() => {
    if (!soundEnabled) return;
    try {
      const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioCtx) return;
      if (!audioCtxRef.current || audioCtxRef.current.state === 'suspended') {
        audioCtxRef.current = new AudioCtx();
      }
      const ctx = audioCtxRef.current;
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(880, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(1760, ctx.currentTime + 0.15);
      gain.gain.setValueAtTime(0.3, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.35);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.35);
    } catch {
      // Audio autoplay policy might prevent before first interaction
    }
  }, [soundEnabled]);

  const startRinging = useCallback(() => {
    if (ringIntervalRef.current) return;
    playAlertChime();
    ringIntervalRef.current = window.setInterval(() => {
      playAlertChime();
    }, 3000);
  }, [playAlertChime]);

  const stopRinging = useCallback(() => {
    if (ringIntervalRef.current) {
      clearInterval(ringIntervalRef.current);
      ringIntervalRef.current = null;
    }
  }, []);

  const loadOrders = useCallback(async () => {
    setLoading(true);
    try {
      const rid = PartnerSession.restaurantId || '';
      const res = await ApiClient.get<{ data: MerchantOrder[] }>(`/v1/partner/orders?restaurant_id=${rid}`);
      const list = res?.data || [];
      setOrders(list);

      const incoming = list.filter((o) => o.status === 'incoming');
      if (incoming.length > 0) {
        startRinging();
      } else {
        stopRinging();
      }
    } catch {
      // handled by apiClient fallback
    } finally {
      setLoading(false);
    }
  }, [startRinging, stopRinging]);

  useEffect(() => {
    loadOrders();
    const interval = setInterval(loadOrders, 8000);
    return () => {
      clearInterval(interval);
      stopRinging();
    };
  }, [loadOrders, stopRinging]);

  // Connect to SSE stream if available
  useEffect(() => {
    const rid = PartnerSession.restaurantId || '';
    if (!rid) return;
    let es: EventSource | null = null;
    try {
      es = new EventSource(`${Env.apiBaseUrl}/v1/sse/partner?restaurant_id=${rid}`);
      es.onmessage = () => {
        loadOrders();
      };
    } catch {
      // SSE not supported or offline
    }
    return () => {
      es?.close();
    };
  }, [loadOrders]);

  const handleAcceptClick = (order: MerchantOrder) => {
    setPrepDialogOrder(order);
    setSelectedPrepTime(15);
  };

  const confirmAccept = async () => {
    if (!prepDialogOrder) return;
    const orderId = prepDialogOrder.orderId;
    setPrepDialogOrder(null);
    try {
      await ApiClient.put(`/v1/partner/orders/${orderId}`, {
        action: 'accept',
        prep_time_minutes: selectedPrepTime,
      });
      await loadOrders();
    } catch (err: any) {
      alert(err?.message || 'Failed to accept order on server.');
    }
  };

  const handleReject = async (order: MerchantOrder) => {
    if (!window.confirm(`Are you sure you want to reject order #${order.orderId}?`)) return;
    try {
      await ApiClient.put(`/v1/partner/orders/${order.orderId}`, {
        action: 'reject',
      });
      await loadOrders();
    } catch (err: any) {
      alert(err?.message || 'Failed to reject order on server.');
    }
  };

  const handleReady = async (order: MerchantOrder) => {
    try {
      if (order.status === 'preparing') {
        await ApiClient.put(`/v1/partner/orders/${order.orderId}`, {
          action: 'ready',
        });
      } else if (order.status === 'ready') {
        await ApiClient.put(`/v1/partner/orders/${order.orderId}`, {
          action: 'handover',
        });
      }
      await loadOrders();
    } catch (err: any) {
      alert(err?.message || 'Failed to update order status on server.');
    }
  };

  const newOrders = orders.filter((o) => o.status === 'incoming');
  const preparingOrders = orders.filter((o) => o.status === 'preparing');
  const readyOrders = orders.filter((o) => o.status === 'ready');
  const outForDeliveryOrders = orders.filter((o) => o.status === 'outForDelivery');

  let currentOrders: MerchantOrder[] = [];
  if (activeTab === 'incoming') currentOrders = newOrders;
  if (activeTab === 'preparing') currentOrders = preparingOrders;
  if (activeTab === 'ready') currentOrders = readyOrders;
  if (activeTab === 'outForDelivery') currentOrders = outForDeliveryOrders;

  // In Flutter orders screen, NEW tab shows 2 by default with a "VIEW MORE" expansion
  const displayedOrders =
    activeTab === 'incoming' && !showAllIncoming
      ? currentOrders.slice(0, 2)
      : currentOrders;

  return (
    <div>
      {/* Tab Bar */}
      <div className="sticky top-[53px] z-30 bg-[#0A1A0F] border-b border-[#1B3D22]">
        <div className="flex items-center justify-between border-b border-[#1B3D22]/60 px-4 py-2">
          <div className="flex items-center gap-2">
            <span className="text-xs font-bold text-[#81C784]">Active Kitchen Feed</span>
            {newOrders.length > 0 && (
              <span className="bg-[#00FF41] text-[#003300] text-[10px] font-black px-2 py-0.5 rounded-full animate-bounce">
                {newOrders.length} NEW
              </span>
            )}
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setSoundEnabled((prev) => !prev)}
              className="p-1.5 text-[#81C784] hover:text-[#00FF41] rounded-lg cursor-pointer"
              title={soundEnabled ? 'Mute alert sounds' : 'Unmute alert sounds'}
            >
              {soundEnabled ? <Volume2 className="w-4 h-4" /> : <VolumeX className="w-4 h-4 text-red-400" />}
            </button>
            <button
              onClick={loadOrders}
              disabled={loading}
              className="p-1.5 text-[#81C784] hover:text-[#00FF41] rounded-lg cursor-pointer"
              title="Refresh Orders"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>

        <div className="flex overflow-x-auto no-scrollbar scroll-smooth">
          <button
            onClick={() => setActiveTab('incoming')}
            className={`flex-1 min-w-[90px] py-3 text-center text-xs font-bold tracking-wider border-b-2 transition-all cursor-pointer ${
              activeTab === 'incoming'
                ? 'border-[#00FF41] text-[#00FF41]'
                : 'border-transparent text-[#9E9E9E] hover:text-white'
            }`}
          >
            NEW ({newOrders.length})
          </button>
          <button
            onClick={() => setActiveTab('preparing')}
            className={`flex-1 min-w-[110px] py-3 text-center text-xs font-bold tracking-wider border-b-2 transition-all cursor-pointer ${
              activeTab === 'preparing'
                ? 'border-[#00FF41] text-[#00FF41]'
                : 'border-transparent text-[#9E9E9E] hover:text-white'
            }`}
          >
            PREPARING ({preparingOrders.length})
          </button>
          <button
            onClick={() => setActiveTab('ready')}
            className={`flex-1 min-w-[90px] py-3 text-center text-xs font-bold tracking-wider border-b-2 transition-all cursor-pointer ${
              activeTab === 'ready'
                ? 'border-[#00FF41] text-[#00FF41]'
                : 'border-transparent text-[#9E9E9E] hover:text-white'
            }`}
          >
            READY ({readyOrders.length})
          </button>
          <button
            onClick={() => setActiveTab('outForDelivery')}
            className={`flex-1 min-w-[130px] py-3 text-center text-xs font-bold tracking-wider border-b-2 transition-all cursor-pointer ${
              activeTab === 'outForDelivery'
                ? 'border-[#00FF41] text-[#00FF41]'
                : 'border-transparent text-[#9E9E9E] hover:text-white'
            }`}
          >
            OUT FOR DELIVERY ({outForDeliveryOrders.length})
          </button>
        </div>
      </div>

      {/* Orders List */}
      <div className="p-4 sm:p-5">
        {currentOrders.length === 0 ? (
          <div className="py-20 text-center">
            <Clock className="w-12 h-12 text-[#1B5E20] mx-auto mb-3" />
            <h3 className="text-base font-bold text-white mb-1">No orders in this state</h3>
            <p className="text-xs text-[#81C784]">
              {activeTab === 'incoming'
                ? 'Waiting for new customer orders. Alerts will chime when an order arrives.'
                : 'Orders will move here as their status updates.'}
            </p>
          </div>
        ) : (
          <div>
            {displayedOrders.map((order) => (
              <OrderCard
                key={order.orderId}
                order={order}
                onAccept={handleAcceptClick}
                onReject={handleReject}
                onReady={handleReady}
              />
            ))}

            {activeTab === 'incoming' && !showAllIncoming && currentOrders.length > 2 && (
              <div className="text-center pt-2 pb-4">
                <p className="text-xs italic text-[#81C784] mb-2">
                  Showing 2 of {currentOrders.length} orders
                </p>
                <button
                  onClick={() => setShowAllIncoming(true)}
                  className="inline-flex items-center gap-1 text-xs font-black tracking-wider text-[#00FF41] hover:underline cursor-pointer"
                >
                  VIEW MORE <ChevronDown className="w-4 h-4" />
                </button>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Preparation Time Modal Dialog */}
      {prepDialogOrder && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-xs">
          <div className="bg-[#0D2B15] border border-[#1B5E20] rounded-2xl max-w-sm w-full p-5 shadow-2xl">
            <h3 className="text-lg font-extrabold text-white mb-1">
              Set Prep Time (minutes)
            </h3>
            <p className="text-xs text-[#81C784] mb-4">
              Estimated kitchen preparation time for order #{prepDialogOrder.orderId}
            </p>

            <div className="grid grid-cols-4 gap-2 mb-4">
              {[10, 15, 20, 25, 30, 35, 40, 45].map((m) => (
                <button
                  key={m}
                  onClick={() => setSelectedPrepTime(m)}
                  className={`py-2 px-1 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                    selectedPrepTime === m
                      ? 'bg-[#00FF41] text-[#003300] ring-2 ring-[#00FF41]'
                      : 'bg-[#0F3318] text-white hover:bg-[#1B5E20]'
                  }`}
                >
                  {m} min
                </button>
              ))}
            </div>

            <div className="bg-[#0F3318] rounded-xl p-3 border border-[#1B3D22] mb-5 text-center">
              <span className="text-xs text-[#81C784]">Selected preparation time: </span>
              <span className="text-sm font-extrabold text-[#00FF41] font-mono">
                {selectedPrepTime} minutes
              </span>
            </div>

            <div className="flex items-center gap-3">
              <button
                onClick={() => setPrepDialogOrder(null)}
                className="flex-1 py-2.5 rounded-xl border border-[#1B3D22] text-[#81C784] hover:bg-[#0F3318] text-xs font-bold transition-colors cursor-pointer"
              >
                Cancel
              </button>
              <button
                onClick={confirmAccept}
                className="flex-1 py-2.5 rounded-xl bg-[#00FF41] text-[#003300] text-xs font-extrabold hover:bg-[#00e63a] transition-all cursor-pointer shadow-md"
              >
                Confirm & Accept
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
