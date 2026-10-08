import React, { useState } from 'react';
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
    address: 'Commercial Arcade, Hazratganj, Lucknow, UP',
    latitude: 26.8467,
    longitude: 80.9462,
    fssaiNumber: '',
    gstNumber: '',
    panNumber: '',
    documents: {},
    documentsUrls: {},
  });

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Location search state
  const [locSearch, setLocSearch] = useState('');
  const [searchingLoc, setSearchingLoc] = useState(false);
  const [locResults, setLocResults] = useState<Array<{ display_name: string; lat: string; lon: string }>>([]);

  // Documents state
  const [docFiles, setDocFiles] = useState<Record<string, string>>({
    fssai: '',
    pan: '',
    gst: '',
    cancelled_cheque: '',
  });

  // Step 1: Continue
  const handleStep1Continue = () => {
    if (!draft.restaurantName.trim() || !draft.ownerName.trim() || !draft.email.trim()) {
      setError('Please fill in all required fields');
      return;
    }
    setError(null);
    setStep(2);
  };

  // Location search helper
  const handleSearchPlaces = async () => {
    if (!locSearch.trim()) return;
    setSearchingLoc(true);
    try {
      const res = await fetch(
        `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(
          locSearch.trim()
        )}&format=json&limit=4`,
        { headers: { 'User-Agent': 'maa-sharda-go-app' } }
      );
      if (res.ok) {
        const data = await res.json();
        setLocResults(data);
      }
    } catch {
      // ignore
    } finally {
      setSearchingLoc(false);
    }
  };

  // Step 2: Continue
  const handleStep2Continue = () => {
    if (!draft.address.trim() || !draft.fssaiNumber.trim()) {
      setError('Store address and FSSAI number are required');
      return;
    }
    setError(null);
    setStep(3);
  };

  // Mock document upload
  const handleUploadDoc = (key: string) => {
    setDocFiles((prev) => ({
      ...prev,
      [key]: `https://images.unsplash.com/photo-1568667256549-094345857637?w=400`,
    }));
  };

  // Step 3: Submit application
  const handleSubmitApplication = async () => {
    if (!draft.panNumber.trim()) {
      setError('PAN card number is required');
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      await ApiClient.post('/v1/partner/auth/register', {
        phone: draft.phone,
        name: draft.restaurantName,
        address: draft.address,
        owner_name: draft.ownerName,
        owner_email: draft.email,
        cuisines: [draft.cuisine],
        documents: {
          fssai: draft.fssaiNumber,
          pan: draft.panNumber,
          ...(draft.gstNumber ? { gst: draft.gstNumber } : {}),
        },
        documents_urls: docFiles,
      });

      // Save session in review
      PartnerSession.save({
        token: 'reg-tok-' + Date.now(),
        restaurantId: 'REST-DRAFT',
        approvalStatus: 'inReview',
        restaurantName: draft.restaurantName,
      });

      setStep(4);
    } catch (err: any) {
      setError(err?.message || 'Failed to submit application. Please try again.');
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
                    placeholder="e.g. Maa Sharda Grand Kitchen"
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
                    placeholder="Owner / Partner legal name"
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
                    placeholder="+91 98765 43210"
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
                    placeholder="kitchen@example.com"
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
                  Search Store Location
                </label>
                <div className="flex gap-2">
                  <div className="relative flex-1">
                    <Search className="w-4 h-4 absolute left-3 top-3 text-[#9E9E9E]" />
                    <input
                      type="text"
                      placeholder="Type area, street or landmark..."
                      value={locSearch}
                      onChange={(e) => setLocSearch(e.target.value)}
                      className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl pl-9 pr-3 py-2 text-xs text-white focus:outline-none focus:border-[#00FF41]"
                    />
                  </div>
                  <button
                    type="button"
                    onClick={handleSearchPlaces}
                    disabled={searchingLoc}
                    className="px-3 py-2 rounded-xl bg-[#0F3318] border border-[#1B3D22] text-[#00FF41] text-xs font-bold hover:bg-[#1B5E20] cursor-pointer"
                  >
                    {searchingLoc ? '...' : 'Search'}
                  </button>
                </div>

                {locResults.length > 0 && (
                  <div className="mt-2 bg-[#0F3318] border border-[#1B3D22] rounded-xl divide-y divide-[#1B3D22] max-h-36 overflow-y-auto">
                    {locResults.map((r, i) => (
                      <button
                        key={i}
                        type="button"
                        onClick={() => {
                          setDraft({
                            ...draft,
                            address: r.display_name,
                            latitude: parseFloat(r.lat),
                            longitude: parseFloat(r.lon),
                          });
                          setLocResults([]);
                        }}
                        className="w-full p-2.5 text-left text-xs text-[#81C784] hover:bg-[#1B5E20]/40 transition-colors"
                      >
                        {r.display_name}
                      </button>
                    ))}
                  </div>
                )}
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
                    Lat: {draft.latitude?.toFixed(4)}, Lon: {draft.longitude?.toFixed(4)}
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
                      {uploaded ? 'Re-upload' : 'Upload'}
                    </button>
                  </div>
                );
              })}
            </div>

            <div className="pt-4">
              <button
                type="button"
                onClick={handleSubmitApplication}
                disabled={submitting}
                className="w-full py-3.5 px-4 rounded-xl bg-[#00FF41] text-[#003300] font-extrabold text-sm tracking-wide hover:bg-[#00e63a] transition-all cursor-pointer shadow-md"
              >
                {submitting ? 'Submitting Application...' : 'Submit Application'}
              </button>
            </div>
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
                Go to Partner Dashboard (Approved Preview)
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
