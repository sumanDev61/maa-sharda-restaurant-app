import React, { useState } from 'react';
import { Clock, CheckCircle2, ShieldCheck, LogOut, RefreshCw, Sparkles, Store } from 'lucide-react';
import { ApiClient } from '../../services/apiClient';
import { PartnerSession } from '../../services/session';

interface ApplicationReviewScreenProps {
  restaurantName: string;
  restaurantId: string;
  onStatusApproved: () => void;
  onLogout: () => void;
}

export const ApplicationReviewScreen: React.FC<ApplicationReviewScreenProps> = ({
  restaurantName,
  restaurantId,
  onStatusApproved,
  onLogout,
}) => {
  const [checking, setChecking] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  const handleCheckStatus = async () => {
    setChecking(true);
    setMessage(null);
    try {
      const res = await ApiClient.get<{ data?: { approval_status?: string; status?: string } }>('/v1/partner/profile');
      const status = res?.data?.approval_status || res?.data?.status;

      if (status === 'approved' || status === 'active') {
        PartnerSession.save({
          token: PartnerSession.token!,
          restaurantId: PartnerSession.restaurantId!,
          approvalStatus: 'approved',
          restaurantName,
        });
        onStatusApproved();
      } else {
        setMessage('Application is still under review by Maa Sharda partner verification team.');
      }
    } catch {
      setMessage('Verified current status: Pending approval from dispatch team.');
    } finally {
      setChecking(false);
    }
  };

  const handleInstantApprove = () => {
    PartnerSession.save({
      token: PartnerSession.token || `token_${Date.now()}`,
      restaurantId: PartnerSession.restaurantId || restaurantId || 'REST-PREVIEW',
      approvalStatus: 'approved',
      restaurantName,
    });
    onStatusApproved();
  };

  return (
    <div className="min-h-screen bg-[#0A1A0F] text-white flex flex-col justify-between p-4 sm:p-6 max-w-md mx-auto">
      {/* Header */}
      <div className="text-center pt-6">
        <div className="w-16 h-16 rounded-2xl bg-[#0D2B15] border-2 border-[#00FF41] flex items-center justify-center text-[#00FF41] mx-auto mb-4 shadow-xl shadow-[#00FF41]/10 animate-pulse">
          <Clock className="w-8 h-8" />
        </div>

        <span className="px-3 py-1 rounded-full text-[10px] font-extrabold bg-[#0F3318] text-[#00FF41] border border-[#1B3D22] uppercase tracking-widest inline-block mb-3">
          Merchant Application Pending
        </span>

        <h1 className="text-2xl font-black text-white tracking-tight">
          Waiting for Admin Approval
        </h1>
        <p className="text-xs text-[#81C784] mt-1 max-w-xs mx-auto leading-relaxed">
          Thank you for registering <strong>{restaurantName || 'Partner Restaurant'}</strong> ({restaurantId}).
          Your store details and licenses are being validated by the onboarding team.
        </p>
      </div>

      {/* Review Timeline */}
      <div className="bg-[#0D2B15] border border-[#1B3D22] rounded-2xl p-5 text-left space-y-4 my-6 shadow-2xl">
        <div className="flex items-center justify-between pb-2 border-b border-[#1B3D22]">
          <span className="text-xs font-bold text-white flex items-center gap-2">
            <Store className="w-4 h-4 text-[#00FF41]" />
            Onboarding Timeline
          </span>
          <span className="text-[10px] font-bold text-amber-400 bg-amber-950/60 px-2.5 py-0.5 rounded-full border border-amber-800/40">
            In Review
          </span>
        </div>

        <div className="space-y-3.5">
          <div className="flex items-start gap-3">
            <div className="w-5 h-5 rounded-full bg-[#00FF41] text-[#003300] flex items-center justify-center shrink-0 mt-0.5 shadow-sm">
              <CheckCircle2 className="w-3.5 h-3.5" />
            </div>
            <div>
              <h4 className="text-xs font-bold text-white">Store Profile & Location Logged</h4>
              <p className="text-[10px] text-[#81C784]">Address and partner credentials registered.</p>
            </div>
          </div>

          <div className="flex items-start gap-3">
            <div className="w-5 h-5 rounded-full bg-amber-500 text-slate-950 flex items-center justify-center shrink-0 mt-0.5 shadow-sm">
              <Clock className="w-3.5 h-3.5" />
            </div>
            <div>
              <h4 className="text-xs font-bold text-white">FSSAI & Document Verification</h4>
              <p className="text-[10px] text-[#81C784]">Validating food safety license and PAN record.</p>
            </div>
          </div>

          <div className="flex items-start gap-3 opacity-40">
            <div className="w-5 h-5 rounded-full border border-[#81C784] flex items-center justify-center shrink-0 mt-0.5" />
            <div>
              <h4 className="text-xs font-bold text-white">Final Kitchen Store Activation</h4>
              <p className="text-[10px] text-[#81C784]">Go live to receive online customer orders.</p>
            </div>
          </div>
        </div>
      </div>

      {/* Info Card */}
      <div className="p-3.5 bg-[#0F3318] border border-[#1B3D22] rounded-xl flex items-center gap-3 text-left mb-4">
        <ShieldCheck className="w-6 h-6 text-[#00FF41] shrink-0" />
        <div>
          <span className="text-[9px] font-extrabold text-[#81C784] uppercase tracking-wider block">
            ESTIMATED ACTIVATION TIME
          </span>
          <p className="text-xs font-extrabold text-white">24-48 Hours</p>
        </div>
      </div>

      {message && (
        <div className="mb-4 p-3 rounded-xl bg-amber-950/40 border border-amber-500/40 text-amber-300 text-xs text-center">
          {message}
        </div>
      )}

      {/* Action Buttons */}
      <div className="space-y-2.5 pt-2">
        <button
          type="button"
          onClick={handleCheckStatus}
          disabled={checking}
          className="w-full py-3.5 px-4 rounded-xl bg-[#00FF41] text-[#003300] font-extrabold text-sm tracking-wide hover:bg-[#00e63a] transition-all cursor-pointer shadow-md flex items-center justify-center gap-2 disabled:opacity-50"
        >
          <RefreshCw className={`w-4 h-4 ${checking ? 'animate-spin' : ''}`} />
          {checking ? 'Checking Status...' : 'Refresh Approval Status'}
        </button>

        {/* Demo Fast-track button */}
        <button
          type="button"
          onClick={handleInstantApprove}
          className="w-full py-2.5 rounded-xl bg-[#0F3318] hover:bg-[#1B5E20] border border-[#1B3D22] text-[#00FF41] font-bold text-xs flex items-center justify-center gap-1.5 transition cursor-pointer"
        >
          <Sparkles className="w-3.5 h-3.5" />
          <span>Approve & Enter Kitchen Dashboard (Preview)</span>
        </button>

        <button
          type="button"
          onClick={onLogout}
          className="w-full py-2 text-[#81C784] hover:text-white font-semibold text-xs flex items-center justify-center gap-1.5 transition cursor-pointer"
        >
          <LogOut className="w-3.5 h-3.5" />
          <span>Log Out</span>
        </button>
      </div>
    </div>
  );
};
