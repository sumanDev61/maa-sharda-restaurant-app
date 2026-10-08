import React, { useState, useEffect } from 'react';
import {
  User,
  Building,
  Edit,
  LogOut,
  HelpCircle,
  Info,
  ChevronRight,
  Phone,
  Mail,
  MapPin,
  FileText,
  Shield,
  ExternalLink,
  MessageCircle,
  Percent,
  CheckCircle,
  ArrowLeft,
  Lock,
} from 'lucide-react';
import { PartnerProfile } from '../../types';
import { ApiClient } from '../../services/apiClient';
import { PartnerSession } from '../../services/session';

interface ProfileScreenProps {
  onLogout?: () => void;
  onNavigateToReview?: () => void;
}

type SubScreen = 'main' | 'manager' | 'commission' | 'help' | 'about' | 'bank';

export const ProfileScreen: React.FC<ProfileScreenProps> = ({
  onLogout,
  onNavigateToReview,
}) => {
  const [currentSubScreen, setCurrentSubScreen] = useState<SubScreen>('main');
  const [profile, setProfile] = useState<PartnerProfile | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  // Bank details state
  const [bankAccount, setBankAccount] = useState('HDFC Bank •••• 4892');
  const [ifscCode, setIfscCode] = useState('HDFC0001234');
  const [payoutSchedule, setPayoutSchedule] = useState('Daily Automated Settlement');

  const loadProfile = async () => {
    setLoading(true);
    try {
      const res = await ApiClient.get<{ data: PartnerProfile }>('/v1/partner/profile');
      setProfile(res?.data || null);
    } catch {
      // fallback
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadProfile();
  }, []);

  const handleLogout = async () => {
    PartnerSession.clear();
    onLogout?.();
  };

  if (loading && !profile) {
    return (
      <div className="py-24 text-center">
        <div className="w-8 h-8 border-2 border-[#00FF41] border-t-transparent rounded-full animate-spin mx-auto mb-2" />
        <p className="text-xs text-[#81C784]">Loading profile...</p>
      </div>
    );
  }

  // Sub-screen 1: Manager Profile
  if (currentSubScreen === 'manager') {
    return (
      <div className="p-4 sm:p-5">
        <button
          onClick={() => setCurrentSubScreen('main')}
          className="flex items-center gap-2 text-xs font-bold text-[#81C784] hover:text-[#00FF41] mb-4 cursor-pointer"
        >
          <ArrowLeft className="w-4 h-4" /> Back to Profile
        </button>

        <div className="bg-[#0D2B15] border border-[#1B5E20] rounded-2xl p-5 mb-4 text-center">
          <div className="w-20 h-20 rounded-full bg-[#0F3318] border-2 border-[#00FF41] mx-auto mb-3 flex items-center justify-center text-white overflow-hidden">
            {profile?.image_url ? (
              <img src={profile.image_url} alt="Owner" className="w-full h-full object-cover" />
            ) : (
              <User className="w-10 h-10 text-[#00FF41]" />
            )}
          </div>
          <h3 className="text-lg font-extrabold text-white">{profile?.owner_name || 'Manager'}</h3>
          <span className="inline-block mt-1 px-3 py-0.5 rounded-full bg-[#1B5E20] text-[#00FF41] text-[11px] font-bold">
            Owner & Authorized Signatory
          </span>
          <p className="text-xs text-[#81C784] mt-1">{profile?.name || 'Restaurant'}</p>
        </div>

        <div className="bg-[#0D2B15] border border-[#1B3D22] rounded-2xl divide-y divide-[#1B3D22]">
          <div className="p-3.5 flex items-center gap-3">
            <Phone className="w-4 h-4 text-[#00FF41]" />
            <div>
              <p className="text-[11px] text-[#9E9E9E]">Mobile Number</p>
              <p className="text-sm font-bold text-white">{profile?.phone || 'Not added'}</p>
            </div>
          </div>
          <div className="p-3.5 flex items-center gap-3">
            <Mail className="w-4 h-4 text-[#00FF41]" />
            <div>
              <p className="text-[11px] text-[#9E9E9E]">Email Address</p>
              <p className="text-sm font-bold text-white">{profile?.owner_email || 'Not added'}</p>
            </div>
          </div>
          <div className="p-3.5 flex items-center gap-3">
            <MapPin className="w-4 h-4 text-[#00FF41]" />
            <div>
              <p className="text-[11px] text-[#9E9E9E]">Store Address</p>
              <p className="text-xs font-semibold text-white">{profile?.address || 'Not added'}</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Sub-screen 2: Commission & Agreements
  if (currentSubScreen === 'commission') {
    return (
      <div className="p-4 sm:p-5 space-y-4">
        <button
          onClick={() => setCurrentSubScreen('main')}
          className="flex items-center gap-2 text-xs font-bold text-[#81C784] hover:text-[#00FF41] mb-2 cursor-pointer"
        >
          <ArrowLeft className="w-4 h-4" /> Back to Profile
        </button>

        <div className="bg-[#0F3318] border border-[#1B5E20] rounded-2xl p-5">
          <span className="text-[11px] font-bold tracking-wider text-[#00FF41] uppercase">
            CURRENT TIER
          </span>
          <h3 className="text-2xl font-extrabold text-white mt-1 mb-1">
            10% Commission
          </h3>
          <p className="text-xs text-[#81C784]">
            Your commission rate is based on the Premium Restaurant Partner tier. Settlements are automatically cleared every 24 hours.
          </p>
        </div>

        <div className="bg-[#0D2B15] border border-[#1B3D22] rounded-2xl p-4">
          <h4 className="text-xs font-bold text-[#9E9E9E] uppercase tracking-wider mb-3">
            Active Agreements & Contracts
          </h4>
          <div className="space-y-3">
            <div className="flex items-center justify-between p-3 rounded-xl bg-[#0F3318] border border-[#1B3D22]">
              <div className="flex items-center gap-3">
                <FileText className="w-5 h-5 text-[#00FF41]" />
                <div>
                  <h5 className="text-xs font-bold text-white">Standard Partnership Agreement</h5>
                  <p className="text-[11px] text-[#81C784]">Signed & Activated • Live</p>
                </div>
              </div>
              <CheckCircle className="w-4 h-4 text-[#00FF41]" />
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl bg-[#0F3318] border border-[#1B3D22]">
              <div className="flex items-center gap-3">
                <Shield className="w-5 h-5 text-[#00FF41]" />
                <div>
                  <h5 className="text-xs font-bold text-white">Data Processing & Privacy Addendum</h5>
                  <p className="text-[11px] text-[#81C784]">Compliant with Indian IT Rules & GDPR</p>
                </div>
              </div>
              <CheckCircle className="w-4 h-4 text-[#00FF41]" />
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Sub-screen 3: Help & Support
  if (currentSubScreen === 'help') {
    return (
      <div className="p-4 sm:p-5 space-y-4">
        <button
          onClick={() => setCurrentSubScreen('main')}
          className="flex items-center gap-2 text-xs font-bold text-[#81C784] hover:text-[#00FF41] mb-2 cursor-pointer"
        >
          <ArrowLeft className="w-4 h-4" /> Back to Profile
        </button>

        <div className="bg-[#0D2B15] border border-[#1B5E20] rounded-2xl p-4">
          <h3 className="text-base font-extrabold text-white mb-1">Need Assistance?</h3>
          <p className="text-xs text-[#81C784] mb-4">
            Our 24/7 dedicated merchant care team is ready to help resolve order issues or payout queries.
          </p>

          <div className="space-y-2.5">
            <a
              href="tel:+918000123456"
              className="flex items-center justify-between p-3 rounded-xl bg-[#0F3318] border border-[#1B3D22] hover:bg-[#1B5E20]/40 transition-colors"
            >
              <div className="flex items-center gap-3">
                <Phone className="w-5 h-5 text-[#00FF41]" />
                <div>
                  <h5 className="text-xs font-bold text-white">Call Partner Support</h5>
                  <p className="text-[11px] text-[#81C784]">Toll-Free: 1800-123-4567</p>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-[#9E9E9E]" />
            </a>

            <a
              href="https://wa.me/918000123456"
              target="_blank"
              rel="noreferrer"
              className="flex items-center justify-between p-3 rounded-xl bg-[#0F3318] border border-[#1B3D22] hover:bg-[#1B5E20]/40 transition-colors"
            >
              <div className="flex items-center gap-3">
                <MessageCircle className="w-5 h-5 text-[#00FF41]" />
                <div>
                  <h5 className="text-xs font-bold text-white">WhatsApp Merchant Desk</h5>
                  <p className="text-[11px] text-[#81C784]">Instant chat assistance</p>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-[#9E9E9E]" />
            </a>

            <a
              href="mailto:support@maashardago.com"
              className="flex items-center justify-between p-3 rounded-xl bg-[#0F3318] border border-[#1B3D22] hover:bg-[#1B5E20]/40 transition-colors"
            >
              <div className="flex items-center gap-3">
                <Mail className="w-5 h-5 text-[#00FF41]" />
                <div>
                  <h5 className="text-xs font-bold text-white">Email Partner Support</h5>
                  <p className="text-[11px] text-[#81C784]">support@maashardago.com</p>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-[#9E9E9E]" />
            </a>
          </div>
        </div>
      </div>
    );
  }

  // Sub-screen 4: About
  if (currentSubScreen === 'about') {
    return (
      <div className="p-4 sm:p-5 space-y-4">
        <button
          onClick={() => setCurrentSubScreen('main')}
          className="flex items-center gap-2 text-xs font-bold text-[#81C784] hover:text-[#00FF41] mb-2 cursor-pointer"
        >
          <ArrowLeft className="w-4 h-4" /> Back to Profile
        </button>

        <div className="bg-[#0D2B15] border border-[#1B5E20] rounded-2xl p-5 text-center">
          <div className="w-14 h-14 rounded-2xl bg-[#0F3318] border border-[#00FF41] mx-auto mb-3 flex items-center justify-center text-[#00FF41] font-extrabold text-xl">
            MS
          </div>
          <h3 className="text-lg font-extrabold text-white">Maa Sharda Go Partner</h3>
          <p className="text-xs text-[#81C784] mt-1">Version 1.0.0 (Production Release)</p>
          <p className="text-xs text-[#9E9E9E] mt-3 max-w-sm mx-auto leading-relaxed">
            Empowering regional restaurants and cloud kitchens with hyper-local delivery logistics and merchant automation.
          </p>
        </div>

        <div className="bg-[#0D2B15] border border-[#1B3D22] rounded-2xl divide-y divide-[#1B3D22]">
          <div className="p-3.5 flex items-center justify-between text-xs">
            <span className="text-[#9E9E9E]">Headquarters</span>
            <span className="font-bold text-white">Lucknow, Uttar Pradesh, India</span>
          </div>
          <div className="p-3.5 flex items-center justify-between text-xs">
            <span className="text-[#9E9E9E]">Legal Entity</span>
            <span className="font-bold text-white">Maa Sharda Technologies Pvt Ltd</span>
          </div>
          <div className="p-3.5 flex items-center justify-between text-xs">
            <span className="text-[#9E9E9E]">Official Website</span>
            <span className="font-bold text-[#00FF41]">www.maashardago.com</span>
          </div>
        </div>
      </div>
    );
  }

  // Sub-screen 5: Bank Details Modal
  if (currentSubScreen === 'bank') {
    return (
      <div className="p-4 sm:p-5 space-y-4">
        <button
          onClick={() => setCurrentSubScreen('main')}
          className="flex items-center gap-2 text-xs font-bold text-[#81C784] hover:text-[#00FF41] mb-2 cursor-pointer"
        >
          <ArrowLeft className="w-4 h-4" /> Back to Profile
        </button>

        <div className="bg-[#0D2B15] border border-[#1B5E20] rounded-2xl p-5">
          <h3 className="text-base font-extrabold text-white mb-1">
            Registered Payout Bank Account
          </h3>
          <p className="text-xs text-[#81C784] mb-4">
            Daily order revenue settlements are transferred to this account.
          </p>

          <div className="space-y-3">
            <div className="bg-[#0F3318] p-3 rounded-xl border border-[#1B3D22]">
              <span className="text-[10px] text-[#9E9E9E] uppercase font-bold">Bank & Account</span>
              <p className="text-sm font-extrabold text-white">{bankAccount}</p>
            </div>
            <div className="bg-[#0F3318] p-3 rounded-xl border border-[#1B3D22]">
              <span className="text-[10px] text-[#9E9E9E] uppercase font-bold">IFSC Code</span>
              <p className="text-sm font-mono font-bold text-white">{ifscCode}</p>
            </div>
            <div className="bg-[#0F3318] p-3 rounded-xl border border-[#1B3D22]">
              <span className="text-[10px] text-[#9E9E9E] uppercase font-bold">Payout Frequency</span>
              <p className="text-sm font-bold text-[#00FF41]">{payoutSchedule}</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Default: Main Profile Overview
  return (
    <div className="p-4 sm:p-5 space-y-4">
      {/* Official Partner Hero */}
      <div className="bg-[#0D2B15] border border-[#1B5E20] rounded-2xl p-5 text-center shadow-lg relative overflow-hidden">
        <div className="w-20 h-20 rounded-full bg-[#0F3318] border-2 border-[#00FF41] mx-auto mb-3 overflow-hidden flex items-center justify-center">
          {profile?.image_url ? (
            <img src={profile.image_url} alt="Store" className="w-full h-full object-cover" />
          ) : (
            <Building className="w-10 h-10 text-[#00FF41]" />
          )}
        </div>

        <h2 className="text-lg font-extrabold text-white">
          {profile?.name || 'Maa Sharda Grand Kitchen'}
        </h2>

        <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#1B5E20]/60 text-[#00FF41] text-xs font-bold mt-1.5">
          <CheckCircle className="w-3.5 h-3.5" />
          Official Verified Partner
        </div>

        <p className="text-xs text-[#81C784] mt-2">
          Partner ID: <span className="font-mono font-bold text-white">#{profile?.id || 'REST-7890'}</span>
        </p>
      </div>

      {/* Account Settings List */}
      <div>
        <h3 className="text-xs font-bold text-[#9E9E9E] uppercase tracking-wider mb-2 px-1">
          Account & Operations
        </h3>

        <div className="bg-[#0D2B15] border border-[#1B3D22] rounded-2xl divide-y divide-[#1B3D22] overflow-hidden">
          <button
            onClick={() => setCurrentSubScreen('bank')}
            className="w-full p-4 flex items-center justify-between text-left hover:bg-[#0F3318] transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-[#0F3318] flex items-center justify-center text-[#00FF41]">
                <Building className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-sm font-bold text-white">My Bank</h4>
                <p className="text-xs text-[#81C784]">Payout account & direct settlement</p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-[#9E9E9E]" />
          </button>

          <button
            onClick={() => setCurrentSubScreen('manager')}
            className="w-full p-4 flex items-center justify-between text-left hover:bg-[#0F3318] transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-[#0F3318] flex items-center justify-center text-[#00FF41]">
                <Edit className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-sm font-bold text-white">Edit Profile</h4>
                <p className="text-xs text-[#81C784]">
                  {profile?.owner_name ? `Manager: ${profile.owner_name}` : 'Update store & owner information'}
                </p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-[#9E9E9E]" />
          </button>

          <button
            onClick={() => setCurrentSubScreen('commission')}
            className="w-full p-4 flex items-center justify-between text-left hover:bg-[#0F3318] transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-[#0F3318] flex items-center justify-center text-[#00FF41]">
                <Percent className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-sm font-bold text-white">Commission & Agreements</h4>
                <p className="text-xs text-[#81C784]">10% Partner Tier • Signed contracts</p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-[#9E9E9E]" />
          </button>
        </div>
      </div>

      {/* Support & Legal */}
      <div>
        <h3 className="text-xs font-bold text-[#9E9E9E] uppercase tracking-wider mb-2 px-1">
          Support & Legal
        </h3>

        <div className="bg-[#0D2B15] border border-[#1B3D22] rounded-2xl divide-y divide-[#1B3D22] overflow-hidden">
          <button
            onClick={() => setCurrentSubScreen('help')}
            className="w-full p-4 flex items-center justify-between text-left hover:bg-[#0F3318] transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-[#0F3318] flex items-center justify-center text-[#00FF41]">
                <HelpCircle className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-sm font-bold text-white">Help & Support</h4>
                <p className="text-xs text-[#81C784]">Contact partner desk 24/7</p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-[#9E9E9E]" />
          </button>

          <button
            onClick={() => setCurrentSubScreen('about')}
            className="w-full p-4 flex items-center justify-between text-left hover:bg-[#0F3318] transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-[#0F3318] flex items-center justify-center text-[#00FF41]">
                <Info className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-sm font-bold text-white">About Maa Sharda Go</h4>
                <p className="text-xs text-[#81C784]">Version 1.0.0 • Terms & Policies</p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-[#9E9E9E]" />
          </button>
        </div>
      </div>

      {/* Logout button */}
      <div className="pt-2">
        <button
          onClick={handleLogout}
          className="w-full py-3.5 px-4 rounded-xl border border-red-500/40 bg-red-950/20 text-red-400 font-bold text-sm hover:bg-red-900/30 transition-colors flex items-center justify-center gap-2 cursor-pointer"
        >
          <LogOut className="w-4 h-4" />
          Log Out
        </button>
      </div>
    </div>
  );
};
