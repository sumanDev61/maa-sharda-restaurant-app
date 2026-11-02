import React, { useState, useRef } from 'react';
import {
  ArrowLeft,
  Store,
  User,
  Phone,
  Mail,
  MapPin,
  FileText,
  Upload,
  CheckCircle,
  HelpCircle,
  Clock,
  ShieldCheck,
  Search,
  Navigation,
} from 'lucide-react';
import { RegistrationDraft } from '../../types';
import { ApiClient } from '../../services/apiClient';
import { PartnerSession } from '../../services/session';

const CUISINE_OPTIONS = [
  'North Indian',
  'South Indian',
  'Mughlai',
  'Chinese',
  'Biryani',
  'Fast Food & Burgers',
  'Bakery & Desserts',
  'Street Food & Chaat',
  'Italian & Pizza',
  'Pure Veg Thali',
];

interface RegistrationFlowProps {
  initialPhone?: string;
  onCompleted: () => void;
  onCancel: () => void;
}

export const RegistrationFlow: React.FC<RegistrationFlowProps> = ({
  initialPhone = '',
  onCompleted,
  onCancel,
}) => {
  const [step, setStep] = useState<1 | 2 | 3 | 4>(1);

  // Draft state
  const [draft, setDraft] = useState<RegistrationDraft>({
    phone: initialPhone,
    restaurantName: '',
    ownerName: '',
    ownerPhone: initialPhone,
    email: '',
    cuisine: CUISINE_OPTIONS[0],
    address: '',
    latitude: null,
    longitude: null,
    fssaiNumber: '',
    gstNumber: '',
    panNumber: '',
    documents: {},
    documentsUrls: {},
  });

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Real location state
  const [isLocating, setIsLocating] = useState(false);
  // OTP step after the application is submitted
  const [pendingRestaurantId, setPendingRestaurantId] = useState<string | null>(null);
  const [otp, setOtp] = useState('');
  const [uploadingKey, setUploadingKey] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const uploadKeyRef = useRef<string | null>(null);

  // Documents state
  const [docFiles, setDocFiles] = useState<Record<string, string>>({
    fssai: '',
    pan: '',
    gst: '',
    cancelled_cheque: '',
  });

  // Real location fetcher
  const handleFetchLocation = () => {
    if ('geolocation' in navigator) {
      setIsLocating(true);
      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          const { latitude, longitude } = pos.coords;
          try {
            const res = await fetch(
              `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}`
            );
            if (res.ok) {
              const data = await res.json();
              const sub = data?.address?.suburb || data?.address?.neighbourhood || data?.address?.road || '';
              const city = data?.address?.city || data?.address?.town || data?.address?.county || '';
              const state = data?.address?.state || '';
              const formatted = [sub, city, state].filter(Boolean).join(', ');
              setDraft((prev) => ({
                ...prev,
                address: formatted,
                latitude,
                longitude,
              }));
            } else {
              setDraft((prev) => ({ ...prev, latitude, longitude }));
            }
          } catch {
            // Coordinates are saved even if the address lookup fails; the owner types the address.
            setDraft((prev) => ({ ...prev, latitude, longitude }));
          } finally {
            setIsLocating(false);
          }
        },
        () => {
          setIsLocating(false);
          setError('Could not get your location. Please allow location access or type the address.');
        },
        { timeout: 10000, enableHighAccuracy: true }
      );
    } else {
      setError('Location is not available on this device. Please type the address.');
    }
  };

  // Step 1: Continue
  const handleStep1Continue = () => {
    if (!draft.restaurantName.trim() || !draft.ownerName.trim() || !draft.email.trim()) {
      setError('Please fill in all required fields');
      return;
    }
    // The contact number is the login number: OTPs are sent to it.
    const digits = String(draft.ownerPhone || '').replace(/\D/g, '').slice(-10);
    if (!/^[6-9]\d{9}$/.test(digits)) {
      setError('Please enter a valid 10-digit mobile number');
      return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(draft.email.trim())) {
      setError('Please enter a valid email address');
      return;
    }
    setDraft((d) => ({ ...d, phone: digits, ownerPhone: digits }));
    setError(null);
    setStep(2);
  };

  // Step 2: Continue
  const handleStep2Continue = () => {
    if (!draft.address.trim() || !draft.fssaiNumber.trim()) {
      setError('Store address and FSSAI number are required');
      return;
    }
    if (!/^\d{14}$/.test(draft.fssaiNumber.trim())) {
      setError('FSSAI license number must be 14 digits');
      return;
    }
    if (draft.latitude == null || draft.longitude == null) {
      setError('Please tap "Fetch Current Location" at your store so riders can find you');
      return;
    }
    setError(null);
    setStep(3);
  };

  // Real document upload (image or PDF) to the backend / Cloudinary
  const handleUploadDoc = (key: string) => {
    uploadKeyRef.current = key;
    fileInputRef.current?.click();
  };

  const onDocFileChosen = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    const key = uploadKeyRef.current;
    e.target.value = '';
    if (!file || !key) return;
    setUploadingKey(key);
    setError(null);
    try {
      const res = await ApiClient.uploadRegistrationImage(file);
      if (!res?.data?.url) throw new Error('Upload failed');
      setDocFiles((prev) => ({ ...prev, [key]: res.data.url }));
    } catch (err: any) {
      setError(err?.message || 'Document upload failed. Please try again.');
    } finally {
      setUploadingKey(null);
    }
  };

  // Step 3: Submit application
  const handleSubmitApplication = async () => {
    if (!/^[A-Z]{5}\d{4}[A-Z]$/.test(draft.panNumber.trim().toUpperCase())) {
      setError('Please enter a valid PAN (e.g. ABCDE1234F)');
      return;
    }
    if (!docFiles.fssai || !docFiles.pan) {
      setError('Please upload your FSSAI certificate and PAN card');
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const res = await ApiClient.post<{ data: { restaurant_id: string; token?: string } }>('/v1/partner/auth/register', {
        phone: draft.phone,
        name: draft.restaurantName,
        address: draft.address,
        owner_name: draft.ownerName,
        owner_email: draft.email,
        cuisines: [draft.cuisine],
        documents: {
          fssai: draft.fssaiNumber.trim(),
          pan: draft.panNumber.trim().toUpperCase(),
          ...(draft.gstNumber ? { gst: draft.gstNumber.trim().toUpperCase() } : {}),
        },
        documents_urls: Object.fromEntries(Object.entries(docFiles).filter(([, v]) => Boolean(v))),
        lat: draft.latitude,
        lng: draft.longitude,
      });
      const rid = res?.data?.restaurant_id;
      if (!rid) throw new Error('Registration failed. Please try again.');
      // The server sends an OTP to the registered phone; the session is created only after it is verified.
      setPendingRestaurantId(rid);
    } catch (err: any) {
      setError(err?.message || 'Could not submit application. Please check your internet and try again.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleVerifyRegistrationOtp = async () => {
    if (!pendingRestaurantId || otp.trim().length < 4) {
      setError('Enter the OTP sent to your phone');
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const res = await ApiClient.post<{ data: { token: string; restaurant: { id: string; name: string; approval_status: string } } }>(
        '/v1/partner/auth/verify-otp',
        { restaurant_id: pendingRestaurantId, otp: otp.trim() }
      );
      if (!res?.data?.token) throw new Error('Verification failed');
      PartnerSession.save({
        token: res.data.token,
        restaurantId: res.data.restaurant.id,
        approvalStatus: res.data.restaurant.approval_status || 'inReview',
        restaurantName: res.data.restaurant.name || draft.restaurantName,
      });
      setStep(4);
    } catch (err: any) {
      setError(err?.message || 'Invalid OTP');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#0A1A0F] text-white flex flex-col justify-between">
      {/* Top Header */}
      <div className="sticky top-0 z-40 bg-[#0A1A0F]/95 backdrop-blur border-b border-[#1B3D22] px-4 py-3 flex items-center justify-between">
        <button
          onClick={step === 1 ? onCancel : () => setStep((s) => (s - 1) as any)}
          className="p-1.5 -ml-1 text-[#81C784] hover:text-[#00FF41] rounded-lg cursor-pointer"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <h2 className="text-sm font-extrabold text-white">Merchant Registration</h2>
        <span className="text-xs font-mono font-bold text-[#00FF41]">
          Step {step} of 4
        </span>
      </div>

      {/* Progress Bar */}
      <div className="w-full bg-[#0F3318] h-1.5">
        <div
          className="bg-[#00FF41] h-1.5 transition-all duration-300"
          style={{ width: `${(step / 4) * 100}%` }}
        />
      </div>

      <div className="flex-1 max-w-md w-full mx-auto p-4 sm:p-5 overflow-y-auto">
        {error && (
          <div className="mb-4 p-3 rounded-xl bg-red-950/40 border border-red-500/40 text-red-300 text-xs">
            {error}
          </div>
        )}

        {/* STEP 1: Basic Information */}
        {step === 1 && (
          <div className="space-y-4">
            <div>
              <h1 className="text-2xl font-extrabold text-white">
                Partner with Maa Sharda Go
              </h1>
              <p className="text-xs text-[#81C784] mt-1 leading-relaxed">
                Join our regional merchant network and scale your kitchen orders.
              </p>
            </div>

            <div className="space-y-3.5 pt-2">
              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Restaurant Name *
                </label>
                <div className="relative">
                  <Store className="w-4 h-4 absolute left-3.5 top-3 text-[#9E9E9E]" />
                  <input
                    type="text"
                    placeholder="Enter restaurant name"
                    value={draft.restaurantName}
                    onChange={(e) => setDraft({ ...draft, restaurantName: e.target.value })}
                    className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl pl-10 pr-3 py-2.5 text-sm text-white focus:outline-none focus:border-[#00FF41]"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Owner Full Name *
                </label>
                <div className="relative">
                  <User className="w-4 h-4 absolute left-3.5 top-3 text-[#9E9E9E]" />
                  <input
                    type="text"
                    placeholder="Enter your name"
                    value={draft.ownerName}
                    onChange={(e) => setDraft({ ...draft, ownerName: e.target.value })}
                    className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl pl-10 pr-3 py-2.5 text-sm text-white focus:outline-none focus:border-[#00FF41]"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Contact Mobile Number *
                </label>
                <div className="relative">
                  <Phone className="w-4 h-4 absolute left-3.5 top-3 text-[#9E9E9E]" />
                  <input
                    type="tel"
                    placeholder="Enter mobile number"
                    value={draft.ownerPhone}
                    onChange={(e) => setDraft({ ...draft, ownerPhone: e.target.value })}
                    className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl pl-10 pr-3 py-2.5 text-sm text-white focus:outline-none focus:border-[#00FF41]"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Business Email *
                </label>
                <div className="relative">
                  <Mail className="w-4 h-4 absolute left-3.5 top-3 text-[#9E9E9E]" />
                  <input
                    type="email"
                    placeholder="Enter business email"
                    value={draft.email}
                    onChange={(e) => setDraft({ ...draft, email: e.target.value })}
                    className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl pl-10 pr-3 py-2.5 text-sm text-white focus:outline-none focus:border-[#00FF41]"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Primary Cuisine *
                </label>
                <select
                  value={draft.cuisine}
                  onChange={(e) => setDraft({ ...draft, cuisine: e.target.value })}
                  className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3 py-2.5 text-sm text-white focus:outline-none focus:border-[#00FF41]"
                >
                  {CUISINE_OPTIONS.map((c) => (
                    <option key={c} value={c} className="bg-[#0D2B15] text-white">
                      {c}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="pt-4">
              <button
                type="button"
                onClick={handleStep1Continue}
                className="w-full py-3.5 px-4 rounded-xl bg-[#00FF41] text-[#003300] font-extrabold text-sm tracking-wide hover:bg-[#00e63a] transition-all cursor-pointer shadow-md"
              >
                Continue to Step 2
              </button>
            </div>
          </div>
        )}

        {/* STEP 2: Location & Compliance */}
        {step === 2 && (
          <div className="space-y-4">
            <div>
              <h1 className="text-2xl font-extrabold text-white">
                Location & Licenses
              </h1>
              <p className="text-xs text-[#81C784] mt-1 leading-relaxed">
                Pinpoint your store address and provide legal compliance details.
              </p>
            </div>

            <div className="space-y-3.5 pt-2">
              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Operating Location / Store Address *
                </label>
                <div className="space-y-2">
                  <button
                    type="button"
                    onClick={handleFetchLocation}
                    disabled={isLocating}
                    className="w-full py-3 px-4 rounded-xl bg-[#0F3318] hover:bg-[#1B5E20] border border-[#1B3D22] text-[#00FF41] text-xs font-extrabold flex items-center justify-center gap-2 cursor-pointer transition shadow-sm"
                  >
                    <Navigation className={`w-4 h-4 ${isLocating ? 'animate-spin' : ''}`} />
                    <span>{isLocating ? 'Locating real area...' : 'Fetch Current Location'}</span>
                  </button>

                  <textarea
                    rows={2}
                    value={draft.address}
                    onChange={(e) => setDraft({ ...draft, address: e.target.value })}
                    placeholder="Click 'Fetch Current Location' or type address"
                    className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-[#00FF41]"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Selected Store Address *
                </label>
                <textarea
                  rows={2}
                  value={draft.address}
                  onChange={(e) => setDraft({ ...draft, address: e.target.value })}
                  className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-[#00FF41]"
                />
              </div>

              {/* Map Preview Simulation */}
              <div className="h-32 rounded-xl bg-[#0D2B15] border border-[#1B3D22] relative overflow-hidden flex items-center justify-center">
                <div className="absolute inset-0 bg-[radial-gradient(#1B5E20_1px,transparent_1px)] [background-size:16px_16px] opacity-40" />
                <div className="relative text-center z-10">
                  <MapPin className="w-6 h-6 text-[#00FF41] mx-auto animate-bounce" />
                  <span className="text-[11px] font-bold text-white mt-1 block">
                    {draft.latitude != null && draft.longitude != null
                      ? `Lat: ${draft.latitude.toFixed(4)}, Lon: ${draft.longitude.toFixed(4)}`
                      : 'Location not captured yet'}
                  </span>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  FSSAI License Number (14 digits) *
                </label>
                <input
                  type="text"
                  maxLength={14}
                  placeholder="e.g. 10020051000123"
                  value={draft.fssaiNumber}
                  onChange={(e) => setDraft({ ...draft, fssaiNumber: e.target.value })}
                  className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3 py-2.5 text-sm font-mono text-white focus:outline-none focus:border-[#00FF41]"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  GSTIN (Optional)
                </label>
                <input
                  type="text"
                  placeholder="22AAAAA0000A1Z5"
                  value={draft.gstNumber}
                  onChange={(e) => setDraft({ ...draft, gstNumber: e.target.value })}
                  className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3 py-2.5 text-sm font-mono text-white focus:outline-none focus:border-[#00FF41]"
                />
              </div>
            </div>

            <div className="pt-4">
              <button
                type="button"
                onClick={handleStep2Continue}
                className="w-full py-3.5 px-4 rounded-xl bg-[#00FF41] text-[#003300] font-extrabold text-sm tracking-wide hover:bg-[#00e63a] transition-all cursor-pointer shadow-md"
              >
                Continue to Document Upload
              </button>
            </div>
          </div>
        )}

        {/* STEP 3: Documents Verification */}
        {step === 3 && (
          <div className="space-y-4">
            <div>
              <h1 className="text-2xl font-extrabold text-white">
                Document Verification
              </h1>
              <p className="text-xs text-[#81C784] mt-1 leading-relaxed">
                Upload clear government-approved business records for merchant onboarding.
              </p>
            </div>

            <div className="space-y-3 pt-2">
              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Owner PAN Number *
                </label>
                <input
                  type="text"
                  maxLength={10}
                  placeholder="ABCDE1234F"
                  value={draft.panNumber}
                  onChange={(e) => setDraft({ ...draft, panNumber: e.target.value.toUpperCase() })}
                  className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3 py-2.5 text-sm font-mono text-white focus:outline-none focus:border-[#00FF41]"
                />
              </div>

              {/* Document tiles */}
              {[
                { key: 'fssai', title: 'FSSAI License Certificate', req: true },
                { key: 'pan', title: 'PAN Card of Proprietor', req: true },
                { key: 'gst', title: 'GST Registration Certificate', req: false },
                { key: 'cancelled_cheque', title: 'Cancelled Cheque for Payouts', req: false },
              ].map((doc) => {
                const uploaded = Boolean(docFiles[doc.key]);
                return (
                  <div
                    key={doc.key}
                    className="p-3.5 rounded-xl bg-[#0D2B15] border border-[#1B3D22] flex items-center justify-between"
                  >
                    <div>
                      <h4 className="text-xs font-bold text-white flex items-center gap-1.5">
                        {doc.title}
                        {doc.req && <span className="text-red-400 font-extrabold">*</span>}
                      </h4>
                      <p className={`text-[11px] mt-0.5 ${uploaded ? 'text-[#00FF41]' : 'text-[#9E9E9E]'}`}>
                        {uploaded ? '✓ Document Uploaded' : 'Pending upload'}
                      </p>
                    </div>

                    <button
                      type="button"
                      onClick={() => handleUploadDoc(doc.key)}
                      className={`px-3 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1 cursor-pointer transition-colors ${
                        uploaded
                          ? 'bg-[#1B5E20] text-[#00FF41]'
                          : 'bg-[#00FF41] text-[#003300] hover:bg-[#00e63a]'
                      }`}
                    >
                      <Upload className="w-3.5 h-3.5" />
                      {uploadingKey === doc.key ? 'Uploading…' : uploaded ? 'Re-upload' : 'Upload'}
                    </button>
                  </div>
                );
              })}
            </div>

            <input
              ref={fileInputRef}
              type="file"
              accept="image/*,application/pdf"
              className="hidden"
              onChange={onDocFileChosen}
            />

            {pendingRestaurantId ? (
              <div className="pt-4 space-y-3">
                <label className="block text-xs font-bold text-[#81C784]">
                  Enter the OTP sent to +91 {draft.phone.slice(-10)}
                </label>
                <input
                  type="text"
                  inputMode="numeric"
                  maxLength={6}
                  value={otp}
                  onChange={(e) => setOtp(e.target.value.replace(/\D/g, ''))}
                  className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3 py-2.5 text-lg tracking-[0.4em] font-mono text-white focus:outline-none focus:border-[#00FF41]"
                />
                <button
                  type="button"
                  onClick={handleVerifyRegistrationOtp}
                  disabled={submitting}
                  className="w-full py-3.5 px-4 rounded-xl bg-[#00FF41] text-[#003300] font-extrabold text-sm tracking-wide hover:bg-[#00e63a] transition-all cursor-pointer shadow-md"
                >
                  {submitting ? 'Verifying…' : 'Verify & Finish'}
                </button>
              </div>
            ) : (
              <div className="pt-4">
                <button
                  type="button"
                  onClick={handleSubmitApplication}
                  disabled={submitting || Boolean(uploadingKey)}
                  className="w-full py-3.5 px-4 rounded-xl bg-[#00FF41] text-[#003300] font-extrabold text-sm tracking-wide hover:bg-[#00e63a] transition-all cursor-pointer shadow-md"
                >
                  {submitting ? 'Submitting Application...' : 'Submit Application'}
                </button>
              </div>
            )}
          </div>
        )}

        {/* STEP 4: Application Review / Status Tracker */}
        {step === 4 && (
          <div className="space-y-5 text-center py-4">
            <div className="w-20 h-20 rounded-2xl bg-[#0D2B15] border-2 border-[#00FF41] flex items-center justify-center text-[#00FF41] mx-auto shadow-xl">
              <ShieldCheck className="w-10 h-10" />
            </div>

            <div>
              <h1 className="text-2xl font-extrabold text-white">
                Application Submitted!
              </h1>
              <p className="text-xs text-[#81C784] mt-1 max-w-xs mx-auto leading-relaxed">
                Our partner verification team will review your documents and activate your kitchen store.
              </p>
            </div>

            {/* Timeline */}
            <div className="bg-[#0D2B15] border border-[#1B3D22] rounded-2xl p-4 text-left space-y-3">
              <div className="flex items-start gap-3">
                <CheckCircle className="w-4 h-4 text-[#00FF41] mt-0.5" />
                <div>
                  <h4 className="text-xs font-bold text-white">1. Application Received</h4>
                  <p className="text-[11px] text-[#81C784]">Documents submitted and recorded</p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <Clock className="w-4 h-4 text-[#00FF41] mt-0.5" />
                <div>
                  <h4 className="text-xs font-bold text-white">2. In-Person Verification</h4>
                  <p className="text-[11px] text-[#9E9E9E]">Expect a visit within 2-3 business days</p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <Clock className="w-4 h-4 text-[#9E9E9E] mt-0.5" />
                <div>
                  <h4 className="text-xs font-bold text-white">3. Menu Setup & Training</h4>
                  <p className="text-[11px] text-[#9E9E9E]">Get your digital kitchen ready</p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <Clock className="w-4 h-4 text-[#9E9E9E] mt-0.5" />
                <div>
                  <h4 className="text-xs font-bold text-white">4. Go Live!</h4>
                  <p className="text-[11px] text-[#9E9E9E]">Start receiving orders from Maa Sharda Go</p>
                </div>
              </div>
            </div>

            <div className="space-y-2 pt-2">
              <button
                type="button"
                onClick={onCompleted}
                className="w-full py-3.5 px-4 rounded-xl bg-[#00FF41] text-[#003300] font-extrabold text-sm tracking-wide hover:bg-[#00e63a] transition-all cursor-pointer shadow-md"
              >
                Check Application Status
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
