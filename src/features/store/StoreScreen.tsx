import React, { useState, useEffect, useRef } from 'react';
import {
  Upload,
  Plus,
  Trash2,
  Tag,
  CheckCircle,
  Clock,
  Sparkles,
  Save,
} from 'lucide-react';
import { CouponItem, CouponVisibility } from '../../types';
import { ApiClient } from '../../services/apiClient';
import { PartnerSession } from '../../services/session';

export const StoreScreen: React.FC = () => {
  const [isOpen, setIsOpen] = useState<boolean>(true);
  const [deliveryMinutes, setDeliveryMinutes] = useState<number>(25);
  const [pureVeg, setPureVeg] = useState<boolean>(false);
  const [logoUrl, setLogoUrl] = useState<string>('');
  const [coverUrl, setCoverUrl] = useState<string>('');
  const [coupons, setCoupons] = useState<CouponItem[]>([]);
  const [savingSettings, setSavingSettings] = useState<boolean>(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Upload states
  const [uploadingLogo, setUploadingLogo] = useState<boolean>(false);
  const [uploadingCover, setUploadingCover] = useState<boolean>(false);
  const logoInputRef = useRef<HTMLInputElement | null>(null);
  const coverInputRef = useRef<HTMLInputElement | null>(null);

  // Add Coupon Dialog
  const [showCouponDialog, setShowCouponDialog] = useState<boolean>(false);
  const [couponCode, setCouponCode] = useState('');
  const [couponTitle, setCouponTitle] = useState('');
  const [couponSubtitle, setCouponSubtitle] = useState('');
  const [couponDiscount, setCouponDiscount] = useState('');
  const [couponIsPublic, setCouponIsPublic] = useState(true);

  const loadStoreData = async () => {
    try {
      const rid = PartnerSession.restaurantId || '';
      const res = await ApiClient.get<{ data: any }>(`/v1/restaurants/${rid}`);
      const data = res?.data || {};
      setIsOpen(data.status === 'Active');
      setDeliveryMinutes(Number(data.delivery_minutes) || 25);
      setPureVeg(Boolean(data.is_pure_veg));
      setLogoUrl(data.image_url || '');
      setCoverUrl(data.cover_url || '');
    } catch {
      // error
    }

    try {
      const cRes = await ApiClient.get<{ data: { coupons: CouponItem[] } }>('/v1/partner/coupons');
      setCoupons(cRes?.data?.coupons || []);
    } catch {
      // error
    }
  };

  useEffect(() => {
    loadStoreData();
  }, []);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

  const saveSettings = async () => {
    setSavingSettings(true);
    try {
      await ApiClient.put('/v1/partner/status', {
        status: isOpen ? 'Active' : 'Closed',
        delivery_minutes: deliveryMinutes,
        is_pure_veg: pureVeg,
        image_url: logoUrl,
        cover_url: coverUrl,
      });
      showToast('Store settings saved successfully!');
    } catch {
      showToast('Failed to save settings.');
    } finally {
      setSavingSettings(false);
    }
  };

  const handleLogoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploadingLogo(true);
    try {
      const res = await ApiClient.uploadImage(file, 'partner-branding');
      if (res?.data?.url) {
        setLogoUrl(res.data.url);
        await ApiClient.put('/v1/partner/status', { image_url: res.data.url });
        showToast('Logo updated successfully!');
      }
    } catch {
      showToast('Logo upload failed.');
    } finally {
      setUploadingLogo(false);
    }
  };

  const handleCoverUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploadingCover(true);
    try {
      const res = await ApiClient.uploadImage(file, 'partner-branding');
      if (res?.data?.url) {
        setCoverUrl(res.data.url);
        await ApiClient.put('/v1/partner/status', { cover_url: res.data.url });
        showToast('Cover banner updated successfully!');
      }
    } catch {
      showToast('Cover banner upload failed.');
    } finally {
      setUploadingCover(false);
    }
  };

  const handleAddCoupon = async () => {
    if (!couponCode.trim() || !couponTitle.trim()) {
      alert('Coupon code and title are required');
      return;
    }
    const discountNum = parseFloat(couponDiscount) || 0;
    const newCoupon: CouponItem = {
      id: `c-${Date.now()}`,
      code: couponCode.trim().toUpperCase(),
      title: couponTitle.trim(),
      subtitle: couponSubtitle.trim() || 'Special discount offer',
      discount: discountNum,
      visibility: couponIsPublic ? 'public' : 'private',
      status: 'Active',
    };

    try {
      const res = await ApiClient.put<{ data: { coupons: CouponItem[] } }>('/v1/partner/coupons', {
        upserts: [newCoupon],
        deletes: [],
      });
      setCoupons(res?.data?.coupons || [...coupons, newCoupon]);
      setShowCouponDialog(false);
      setCouponCode('');
      setCouponTitle('');
      setCouponSubtitle('');
      setCouponDiscount('');
      showToast(`Coupon ${newCoupon.code} created!`);
    } catch {
      // error
    }
  };

  const toggleCouponVisibility = async (coupon: CouponItem) => {
    const nextVis: CouponVisibility = coupon.visibility === 'public' ? 'private' : 'public';
    try {
      const updated = { ...coupon, visibility: nextVis };
      await ApiClient.put('/v1/partner/coupons', {
        upserts: [updated],
        deletes: [],
      });
      setCoupons((prev) =>
        prev.map((c) => (c.id === coupon.id ? updated : c))
      );
      showToast(`Coupon set to ${nextVis}`);
    } catch {
      // error
    }
  };

  const deleteCoupon = async (coupon: CouponItem) => {
    if (!window.confirm(`Delete coupon ${coupon.code}?`)) return;
    try {
      await ApiClient.put('/v1/partner/coupons', {
        upserts: [],
        deletes: [coupon.id],
      });
      setCoupons((prev) => prev.filter((c) => c.id !== coupon.id));
      showToast('Coupon removed');
    } catch {
      // error
    }
  };

  return (
    <div className="p-4 sm:p-5 space-y-5">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed top-16 left-1/2 -translate-x-1/2 z-50 bg-[#00FF41] text-[#003300] px-4 py-2 rounded-xl text-xs font-extrabold shadow-lg flex items-center gap-2 animate-fade-in">
          <CheckCircle className="w-4 h-4 stroke-[3]" />
          {toastMessage}
        </div>
      )}

      {/* 1. Restaurant Settings Card */}
      <div className="bg-[#0D2B15] border border-[#1B5E20] rounded-2xl p-4 sm:p-5 shadow-lg">
        <h2 className="text-base font-extrabold text-white mb-4">
          Restaurant Settings
        </h2>

        {/* Open / Closed Switch */}
        <div className="flex items-center justify-between py-2 border-b border-[#1B3D22]">
          <div>
            <div className="text-sm font-bold text-white">
              {isOpen ? 'Open for orders' : 'Closed for orders'}
            </div>
            <p className="text-xs text-[#81C784]">
              {isOpen ? 'Store is live and visible to customers' : 'Store is paused, no new orders accepted'}
            </p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={isOpen}
              onChange={(e) => setIsOpen(e.target.checked)}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-[#0F3318] peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#00FF41]"></div>
          </label>
        </div>

        {/* Delivery Time Slider */}
        <div className="py-4 border-b border-[#1B3D22]">
          <div className="flex justify-between items-center mb-1.5">
            <span className="text-xs font-bold text-white flex items-center gap-1.5">
              <Clock className="w-4 h-4 text-[#00FF41]" />
              Estimated Delivery Time
            </span>
            <span className="text-sm font-extrabold text-[#00FF41] font-mono">
              {deliveryMinutes} mins
            </span>
          </div>
          <input
            type="range"
            min="10"
            max="60"
            step="5"
            value={deliveryMinutes}
            onChange={(e) => setDeliveryMinutes(Number(e.target.value))}
            className="w-full accent-[#00FF41] cursor-pointer"
          />
          <div className="flex justify-between text-[10px] text-[#9E9E9E] mt-1 font-mono">
            <span>10 min</span>
            <span>25 min</span>
            <span>40 min</span>
            <span>60 min</span>
          </div>
        </div>

        {/* Pure Veg Checkbox */}
        <div className="py-3">
          <label className="flex items-center gap-3 cursor-pointer">
            <input
              type="checkbox"
              checked={pureVeg}
              onChange={(e) => setPureVeg(e.target.checked)}
              className="w-4 h-4 rounded text-[#00FF41] focus:ring-0 cursor-pointer"
            />
            <div>
              <span className="text-sm font-bold text-white">Pure Veg Restaurant</span>
              <p className="text-xs text-[#81C784]">
                Show Pure Veg green emblem badge on store profile
              </p>
            </div>
          </label>
        </div>

        {/* Save button */}
        <div className="pt-3">
          <button
            onClick={saveSettings}
            disabled={savingSettings}
            className="w-full py-3 px-4 rounded-xl bg-[#00FF41] text-[#003300] font-extrabold text-sm tracking-wide hover:bg-[#00e63a] transition-all cursor-pointer shadow-md flex items-center justify-center gap-2"
          >
            <Save className="w-4 h-4" />
            {savingSettings ? 'Saving Changes...' : 'Save Changes'}
          </button>
        </div>
      </div>

      {/* 2. Branding Card */}
      <div className="bg-[#0D2B15] border border-[#1B5E20] rounded-2xl p-4 sm:p-5 shadow-lg">
        <h2 className="text-base font-extrabold text-white mb-4">
          Store Branding & Media
        </h2>

        <div className="space-y-4">
          {/* Logo Tile */}
          <div className="bg-[#0F3318] border border-[#1B3D22] rounded-xl p-3.5">
            <h3 className="text-xs font-bold text-white mb-0.5">Restaurant Logo</h3>
            <p className="text-[11px] text-[#81C784] mb-3">Square avatar shown in customer search & lists</p>

            <div className="w-20 h-20 rounded-xl bg-[#0A1A0F] border border-[#1B3D22] overflow-hidden mb-3 flex items-center justify-center">
              {logoUrl ? (
                <img src={logoUrl} alt="Logo" className="w-full h-full object-cover" />
              ) : (
                <span className="text-xs text-[#9E9E9E] font-medium">No Logo</span>
              )}
            </div>

            <input
              type="file"
              ref={logoInputRef}
              onChange={handleLogoUpload}
              accept="image/*"
              className="hidden"
            />
            <button
              onClick={() => logoInputRef.current?.click()}
              disabled={uploadingLogo}
              className="w-full py-2 px-3 rounded-lg border border-[#1B3D22] bg-[#0A1A0F] hover:bg-[#1B5E20] text-xs font-bold text-white flex items-center justify-center gap-2 cursor-pointer transition-colors"
            >
              <Upload className="w-3.5 h-3.5 text-[#00FF41]" />
              {uploadingLogo ? 'Uploading...' : 'Upload Logo'}
            </button>
          </div>

          {/* Cover Banner Tile */}
          <div className="bg-[#0F3318] border border-[#1B3D22] rounded-xl p-3.5">
            <h3 className="text-xs font-bold text-white mb-0.5">Cover Image Banner</h3>
            <p className="text-[11px] text-[#81C784] mb-3">Wide hero photo displayed atop your restaurant storefront</p>

            <div className="w-full h-28 rounded-xl bg-[#0A1A0F] border border-[#1B3D22] overflow-hidden mb-3 flex items-center justify-center">
              {coverUrl ? (
                <img src={coverUrl} alt="Cover" className="w-full h-full object-cover" />
              ) : (
                <span className="text-xs text-[#9E9E9E] font-medium">No Cover Banner</span>
              )}
            </div>

            <input
              type="file"
              ref={coverInputRef}
              onChange={handleCoverUpload}
              accept="image/*"
              className="hidden"
            />
            <button
              onClick={() => coverInputRef.current?.click()}
              disabled={uploadingCover}
              className="w-full py-2 px-3 rounded-lg border border-[#1B3D22] bg-[#0A1A0F] hover:bg-[#1B5E20] text-xs font-bold text-white flex items-center justify-center gap-2 cursor-pointer transition-colors"
            >
              <Upload className="w-3.5 h-3.5 text-[#00FF41]" />
              {uploadingCover ? 'Uploading...' : 'Upload Cover Banner'}
            </button>
          </div>
        </div>
      </div>

      {/* 3. Coupons Card */}
      <div className="bg-[#0D2B15] border border-[#1B5E20] rounded-2xl p-4 sm:p-5 shadow-lg">
        <div className="flex items-center justify-between mb-2">
          <div>
            <h2 className="text-base font-extrabold text-white">Coupons & Promo Codes</h2>
            <p className="text-xs text-[#81C784]">Drive sales with discount campaigns</p>
          </div>
          <button
            onClick={() => setShowCouponDialog(true)}
            className="flex items-center gap-1 px-3 py-1.5 rounded-xl bg-[#00FF41] text-[#003300] font-bold text-xs hover:bg-[#00e63a] transition-all cursor-pointer shadow-md"
          >
            <Plus className="w-3.5 h-3.5 stroke-[3]" />
            Add Coupon
          </button>
        </div>

        <p className="text-[11px] text-[#9E9E9E] italic mb-4">
          Public coupons user app me dikhte hain, private coupons sirf code apply karne par lagte hain.
        </p>

        {coupons.length === 0 ? (
          <div className="py-6 text-center text-xs text-[#9E9E9E]">
            Abhi koi coupon add nahi hai. Click &quot;Add Coupon&quot; to create one.
          </div>
        ) : (
          <div className="space-y-3">
            {coupons.map((c) => {
              const isPublic = c.visibility === 'public';
              return (
                <div
                  key={c.id}
                  className="bg-[#0F3318] border border-[#1B3D22] rounded-xl p-3 flex items-center justify-between gap-3"
                >
                  <div className="flex items-center gap-3 flex-1 min-w-0">
                    <div
                      className={`px-2.5 py-1.5 rounded-lg font-mono font-bold text-xs uppercase tracking-wider flex-shrink-0 ${
                        isPublic
                          ? 'bg-[#00FF41]/15 text-[#00FF41] border border-[#00FF41]/30'
                          : 'bg-[#1B3D22] text-[#9E9E9E]'
                      }`}
                    >
                      {c.code}
                    </div>
                    <div className="flex-1 min-w-0">
                      <h4 className="text-xs font-bold text-white truncate">{c.title}</h4>
                      <p className="text-[11px] text-[#81C784] truncate">{c.subtitle}</p>
                      <p className="text-[11px] font-bold text-[#00FF41] font-mono mt-0.5">
                        Discount: ₹{c.discount}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-3 flex-shrink-0">
                    <div className="text-right">
                      <span className="block text-[10px] text-[#9E9E9E]">
                        {isPublic ? 'Public' : 'Private'}
                      </span>
                      <label className="relative inline-flex items-center cursor-pointer mt-0.5">
                        <input
                          type="checkbox"
                          checked={isPublic}
                          onChange={() => toggleCouponVisibility(c)}
                          className="sr-only peer"
                        />
                        <div className="w-8 h-4 bg-[#0A1A0F] peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-3 after:w-3 after:transition-all peer-checked:bg-[#00FF41]"></div>
                      </label>
                    </div>

                    <button
                      onClick={() => deleteCoupon(c)}
                      className="p-1.5 text-red-400 hover:bg-red-500/20 rounded-lg cursor-pointer"
                      title="Delete coupon"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Add Coupon Modal */}
      {showCouponDialog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-xs">
          <div className="bg-[#0D2B15] border border-[#1B5E20] rounded-2xl max-w-sm w-full p-5 shadow-2xl">
            <h3 className="text-base font-extrabold text-white mb-3 flex items-center gap-2">
              <Tag className="w-4 h-4 text-[#00FF41]" />
              Add Promotional Coupon
            </h3>

            <div className="space-y-3">
              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Coupon Code *
                </label>
                <input
                  type="text"
                  placeholder="e.g. FESTIVE20"
                  value={couponCode}
                  onChange={(e) => setCouponCode(e.target.value.toUpperCase())}
                  className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3 py-2 text-xs font-mono text-white placeholder-[#9E9E9E] focus:outline-none focus:border-[#00FF41]"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Title *
                </label>
                <input
                  type="text"
                  placeholder="e.g. 20% Off Weekend Feast"
                  value={couponTitle}
                  onChange={(e) => setCouponTitle(e.target.value)}
                  className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3 py-2 text-xs text-white placeholder-[#9E9E9E] focus:outline-none focus:border-[#00FF41]"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Subtitle
                </label>
                <input
                  type="text"
                  placeholder="e.g. Applicable on orders above ₹299"
                  value={couponSubtitle}
                  onChange={(e) => setCouponSubtitle(e.target.value)}
                  className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3 py-2 text-xs text-white placeholder-[#9E9E9E] focus:outline-none focus:border-[#00FF41]"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Discount Amount (₹) *
                </label>
                <input
                  type="number"
                  placeholder="50"
                  value={couponDiscount}
                  onChange={(e) => setCouponDiscount(e.target.value)}
                  className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3 py-2 text-xs text-white placeholder-[#9E9E9E] focus:outline-none focus:border-[#00FF41]"
                />
              </div>

              <div className="flex items-center justify-between pt-1">
                <span className="text-xs font-bold text-white">Public Coupon</span>
                <input
                  type="checkbox"
                  checked={couponIsPublic}
                  onChange={(e) => setCouponIsPublic(e.target.checked)}
                  className="w-4 h-4 rounded text-[#00FF41] focus:ring-0"
                />
              </div>
            </div>

            <div className="flex items-center gap-3 pt-4 mt-3 border-t border-[#1B3D22]">
              <button
                type="button"
                onClick={() => setShowCouponDialog(false)}
                className="flex-1 py-2 rounded-xl border border-[#1B3D22] text-[#81C784] hover:bg-[#0F3318] text-xs font-bold cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleAddCoupon}
                className="flex-1 py-2 rounded-xl bg-[#00FF41] text-[#003300] text-xs font-extrabold hover:bg-[#00e63a] transition-all cursor-pointer shadow-md"
              >
                Add Coupon
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
