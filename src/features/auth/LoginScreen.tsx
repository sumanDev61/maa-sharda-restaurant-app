import React, { useState } from 'react';
import { Phone, KeyRound, AlertCircle, ArrowRight, Lock } from 'lucide-react';
import { ApiClient } from '../../services/apiClient';
import { PartnerSession } from '../../services/session';

interface LoginScreenProps {
  onSuccess: (status: string) => void;
  onRegisterRequired: (phone: string) => void;
}

export const LoginScreen: React.FC<LoginScreenProps> = ({
  onSuccess,
  onRegisterRequired,
}) => {
  const [authMode, setAuthMode] = useState<'otp' | 'password'>('otp');
  const [step, setStep] = useState<'phone' | 'otp'>('phone');

  // Phone/OTP state
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [restaurantId, setRestaurantId] = useState('');

  // ID/Password state
  const [loginId, setLoginId] = useState('');
  const [password, setPassword] = useState('');

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    const cleanPhone = phone.trim();
    if (cleanPhone.length < 8) {
      setError('Please enter a valid phone number');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const res = await ApiClient.post('/v1/partner/auth/login', { phone: cleanPhone });
      const data = res?.data || {};
      const rid = data.restaurant_id || '';
      if (!rid) {
        throw new Error('Restaurant ID not returned from server');
      }
      setRestaurantId(rid);
      setStep('otp');
    } catch (err: any) {
      if (err.statusCode === 404) {
        onRegisterRequired(cleanPhone);
        return;
      }
      setError(err?.message || 'Failed to send OTP. Please verify phone number or server connection.');
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (otp.trim().length < 4) {
      setError('Please enter the OTP code');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const res = await ApiClient.post('/v1/partner/auth/verify-otp', {
        restaurant_id: restaurantId,
        otp: otp.trim(),
      });
      const data = res?.data || {};
      const token = data.token;
      const rest = data.restaurant || {};
      const rid = rest.id || restaurantId;
      const name = rest.name || 'Maa Sharda Partner';
      const approval = rest.approval_status || 'approved';

      if (!token || !rid) {
        throw new Error('Invalid response from server during OTP verification');
      }

      PartnerSession.save({
        token,
        restaurantId: rid,
        approvalStatus: approval,
        restaurantName: name,
      });

      onSuccess(approval);
    } catch (err: any) {
      setError(err?.message || 'OTP Verification failed. Please check code and try again.');
    } finally {
      setLoading(false);
    }
  };

  const handlePasswordLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!loginId.trim() || !password) {
      setError('Please enter Restaurant ID and Password');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const res = await ApiClient.post('/v1/partner/login', {
        restaurant_id: loginId.trim(),
        password,
      });
      const data = res?.data || {};
      const token = data.token;
      const rest = data.restaurant || {};

      if (!token || !rest.id) {
        throw new Error('Authentication failed. Please check Restaurant ID and password.');
      }

      PartnerSession.save({
        token,
        restaurantId: rest.id,
        approvalStatus: 'approved',
        restaurantName: rest.name || 'Maa Sharda Partner',
      });

      onSuccess('approved');
    } catch (err: any) {
      setError(err?.message || 'Invalid Restaurant ID or Password.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#0A1A0F] text-white flex flex-col justify-center px-4 py-8">
      <div className="max-w-md w-full mx-auto">
        {/* Brand Header */}
        <div className="text-center mb-8">
          <div className="w-16 h-16 rounded-2xl bg-[#0D2B15] border-2 border-[#00FF41] flex items-center justify-center text-[#00FF41] font-black text-2xl mx-auto mb-3 shadow-lg shadow-[#00FF41]/10">
            MS
          </div>
          <h1 className="text-2xl font-extrabold text-white tracking-tight">
            Maa Sharda Go
          </h1>
          <p className="text-xs font-bold text-[#00FF41] uppercase tracking-widest mt-0.5">
            RESTAURANT PARTNER PORTAL
          </p>
        </div>

        {/* Card */}
        <div className="bg-[#0D2B15] border border-[#1B5E20] rounded-2xl p-6 shadow-2xl">
          {/* Auth Method Switcher */}
          <div className="flex bg-[#0F3318] p-1 rounded-xl border border-[#1B3D22] mb-5">
            <button
              type="button"
              onClick={() => {
                setAuthMode('otp');
                setError(null);
              }}
              className={`flex-1 py-1.5 text-xs font-bold rounded-lg transition-colors cursor-pointer ${
                authMode === 'otp'
                  ? 'bg-[#00FF41] text-[#003300]'
                  : 'text-[#81C784] hover:text-white'
              }`}
            >
              Mobile OTP
            </button>
            <button
              type="button"
              onClick={() => {
                setAuthMode('password');
                setError(null);
              }}
              className={`flex-1 py-1.5 text-xs font-bold rounded-lg transition-colors cursor-pointer ${
                authMode === 'password'
                  ? 'bg-[#00FF41] text-[#003300]'
                  : 'text-[#81C784] hover:text-white'
              }`}
            >
              ID & Password
            </button>
          </div>

          {error && (
            <div className="mb-4 p-3 rounded-xl bg-red-950/40 border border-red-500/40 text-red-300 text-xs flex items-center gap-2">
              <AlertCircle className="w-4 h-4 flex-shrink-0 text-red-400" />
              <span>{error}</span>
            </div>
          )}

          {authMode === 'otp' ? (
            step === 'phone' ? (
              <form onSubmit={handleSendOtp} className="space-y-4">
                <div>
                  <h2 className="text-lg font-extrabold text-white mb-1">
                    Partner Login
                  </h2>
                  <p className="text-xs text-[#81C784]">
                    Enter your registered mobile number to manage orders and kitchen operations.
                  </p>
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#81C784] mb-1.5">
                    Mobile Number
                  </label>
                  <div className="relative">
                    <Phone className="w-4 h-4 absolute left-3.5 top-3 text-[#9E9E9E]" />
                    <input
                      type="tel"
                      placeholder="+91 98765 43210"
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      required
                      className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl pl-10 pr-3 py-2.5 text-sm text-white placeholder-[#9E9E9E] focus:outline-none focus:border-[#00FF41]"
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 px-4 rounded-xl bg-[#00FF41] text-[#003300] font-extrabold text-sm tracking-wide hover:bg-[#00e63a] transition-all cursor-pointer shadow-md flex items-center justify-center gap-2 disabled:opacity-50"
                >
                  {loading ? 'Sending OTP...' : 'Send OTP'}
                  <ArrowRight className="w-4 h-4" />
                </button>

                <div className="pt-2 text-center">
                  <button
                    type="button"
                    onClick={() => onRegisterRequired(phone || '+91 98765 43210')}
                    className="text-xs text-[#81C784] hover:text-[#00FF41] underline cursor-pointer"
                  >
                    New restaurant? Register as Partner
                  </button>
                </div>
              </form>
            ) : (
              <form onSubmit={handleVerifyOtp} className="space-y-4">
                <div>
                  <h2 className="text-lg font-extrabold text-white mb-1">
                    Verify OTP
                  </h2>
                  <p className="text-xs text-[#81C784]">
                    Enter the OTP code sent to <span className="font-bold text-white">{phone}</span>
                  </p>
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#81C784] mb-1.5">
                    Verification Code
                  </label>
                  <div className="relative">
                    <KeyRound className="w-4 h-4 absolute left-3.5 top-3 text-[#9E9E9E]" />
                    <input
                      type="text"
                      maxLength={6}
                      placeholder="Enter OTP"
                      value={otp}
                      onChange={(e) => setOtp(e.target.value)}
                      required
                      className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl pl-10 pr-3 py-2.5 text-base tracking-widest font-mono text-white placeholder-[#9E9E9E] focus:outline-none focus:border-[#00FF41]"
                    />
                  </div>
                </div>

                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => setStep('phone')}
                    className="py-3 px-3 rounded-xl border border-[#1B3D22] text-[#81C784] hover:bg-[#0F3318] text-xs font-bold cursor-pointer"
                  >
                    Back
                  </button>
                  <button
                    type="submit"
                    disabled={loading}
                    className="flex-1 py-3 px-4 rounded-xl bg-[#00FF41] text-[#003300] font-extrabold text-sm tracking-wide hover:bg-[#00e63a] transition-all cursor-pointer shadow-md disabled:opacity-50"
                  >
                    {loading ? 'Verifying...' : 'Verify & Continue'}
                  </button>
                </div>
              </form>
            )
          ) : (
            <form onSubmit={handlePasswordLogin} className="space-y-4">
              <div>
                <h2 className="text-lg font-extrabold text-white mb-1">
                  ID & Password Login
                </h2>
                <p className="text-xs text-[#81C784]">
                  Sign in with your assigned Restaurant ID and Partner Password.
                </p>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1.5">
                  Restaurant ID / Login ID
                </label>
                <input
                  type="text"
                  placeholder="e.g. REST-7890 or testrestaurant"
                  value={loginId}
                  onChange={(e) => setLoginId(e.target.value)}
                  required
                  className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3.5 py-2.5 text-sm text-white placeholder-[#9E9E9E] focus:outline-none focus:border-[#00FF41]"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1.5">
                  Password
                </label>
                <div className="relative">
                  <Lock className="w-4 h-4 absolute left-3.5 top-3 text-[#9E9E9E]" />
                  <input
                    type="password"
                    placeholder="Enter password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl pl-10 pr-3 py-2.5 text-sm text-white placeholder-[#9E9E9E] focus:outline-none focus:border-[#00FF41]"
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full py-3.5 px-4 rounded-xl bg-[#00FF41] text-[#003300] font-extrabold text-sm tracking-wide hover:bg-[#00e63a] transition-all cursor-pointer shadow-md disabled:opacity-50"
              >
                {loading ? 'Authenticating...' : 'Sign In'}
              </button>
            </form>
          )}
        </div>
      </div>
    </div>
  );
};
