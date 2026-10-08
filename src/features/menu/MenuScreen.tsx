import React, { useState, useEffect, useRef } from 'react';
import {
  Plus,
  Flame,
  Edit2,
  Trash2,
  Image as ImageIcon,
  Upload,
  RefreshCw,
  Search,
} from 'lucide-react';
import { PartnerMenuItem } from '../../types';
import { ApiClient } from '../../services/apiClient';

const MENU_CATEGORIES = [
  'Main Course',
  'Biryani',
  'Pizza',
  'Burger',
  'South Indian',
  'Chinese',
  'Snacks',
  'Dessert',
  'Starters',
  'Beverages',
  'Thali',
  'Bread',
  'Rice',
  'Salad',
  'Combo',
];

export const MenuScreen: React.FC = () => {
  const [items, setItems] = useState<PartnerMenuItem[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [editingItem, setEditingItem] = useState<PartnerMenuItem | null | 'new'>(null);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedCategoryFilter, setSelectedCategoryFilter] = useState<string>('all');

  // Form states for modal
  const [formName, setFormName] = useState('');
  const [formCategory, setFormCategory] = useState(MENU_CATEGORIES[0]);
  const [formPrice, setFormPrice] = useState('');
  const [formPrepTime, setFormPrepTime] = useState(15);
  const [formDescription, setFormDescription] = useState('');
  const [formImageUrl, setFormImageUrl] = useState('');
  const [formIsVeg, setFormIsVeg] = useState(true);
  const [formIsBestseller, setFormIsBestseller] = useState(false);
  const [uploading, setUploading] = useState(false);

  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const loadMenu = async () => {
    setLoading(true);
    try {
      const res = await ApiClient.get<{ data: { items: PartnerMenuItem[] } }>('/v1/partner/menu');
      setItems(res?.data?.items || []);
    } catch {
      // fallback
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadMenu();
  }, []);

  const openAddModal = () => {
    setFormName('');
    setFormCategory(MENU_CATEGORIES[0]);
    setFormPrice('');
    setFormPrepTime(15);
    setFormDescription('');
    setFormImageUrl('');
    setFormIsVeg(true);
    setFormIsBestseller(false);
    setEditingItem('new');
  };

  const openEditModal = (item: PartnerMenuItem) => {
    setFormName(item.name);
    setFormCategory(item.category || MENU_CATEGORIES[0]);
    setFormPrice(String(item.price));
    setFormPrepTime(item.prepTimeMinutes || 15);
    setFormDescription(item.description || '');
    setFormImageUrl(item.imageUrl || '');
    setFormIsVeg(item.isVeg);
    setFormIsBestseller(item.isBestseller);
    setEditingItem(item);
  };

  const handleSaveItem = async () => {
    if (!formName.trim()) {
      alert('Please enter item name');
      return;
    }
    const priceNum = parseFloat(formPrice) || 0;
    if (priceNum <= 0) {
      alert('Please enter a valid price');
      return;
    }

    const payloadItem: PartnerMenuItem = {
      id: editingItem === 'new' ? '' : (editingItem as PartnerMenuItem).id,
      name: formName.trim(),
      category: formCategory,
      price: priceNum,
      prepTimeMinutes: formPrepTime,
      isVeg: formIsVeg,
      isBestseller: formIsBestseller,
      status: editingItem === 'new' ? 'Available' : (editingItem as PartnerMenuItem).status,
      description: formDescription.trim(),
      imageUrl: formImageUrl.trim(),
    };

    try {
      await ApiClient.put('/v1/partner/menu', {
        upserts: [
          {
            ...(payloadItem.id ? { id: payloadItem.id } : {}),
            name: payloadItem.name,
            category: payloadItem.category,
            price: payloadItem.price,
            prep_time_minutes: payloadItem.prepTimeMinutes,
            is_veg: payloadItem.isVeg,
            is_bestseller: payloadItem.isBestseller,
            status: payloadItem.status,
            description: payloadItem.description,
            image_url: payloadItem.imageUrl,
          },
        ],
        deletes: [],
      });
      setEditingItem(null);
      await loadMenu();
    } catch (err: any) {
      alert(err?.message || 'Failed to save menu item on server.');
    }
  };

  const toggleAvailability = async (item: PartnerMenuItem) => {
    const nextStatus = item.status === 'Available' ? 'Unavailable' : 'Available';
    try {
      await ApiClient.put('/v1/partner/menu', {
        upserts: [
          {
            id: item.id,
            name: item.name,
            category: item.category,
            price: item.price,
            prep_time_minutes: item.prepTimeMinutes,
            is_veg: item.isVeg,
            is_bestseller: item.isBestseller,
            status: nextStatus,
            description: item.description,
            image_url: item.imageUrl,
          },
        ],
        deletes: [],
      });
      setItems((prev) =>
        prev.map((it) => (it.id === item.id ? { ...it, status: nextStatus } : it))
      );
    } catch (err: any) {
      alert(err?.message || 'Failed to update item availability on server.');
    }
  };

  const handleDelete = async (item: PartnerMenuItem) => {
    if (!window.confirm(`Delete "${item.name}" from menu?`)) return;
    try {
      await ApiClient.put('/v1/partner/menu', {
        upserts: [],
        deletes: [item.id],
      });
      setItems((prev) => prev.filter((it) => it.id !== item.id));
    } catch (err: any) {
      alert(err?.message || 'Failed to delete menu item on server.');
    }
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    try {
      const res = await ApiClient.uploadImage(file, 'partner-menu');
      if (res?.data?.url) {
        setFormImageUrl(res.data.url);
      }
    } catch (err: any) {
      alert(err?.message || 'Image upload failed on server.');
    } finally {
      setUploading(false);
    }
  };

  const filteredItems = items.filter((it) => {
    const matchesSearch = it.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (it.category || '').toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCat = selectedCategoryFilter === 'all' || it.category === selectedCategoryFilter;
    return matchesSearch && matchesCat;
  });

  return (
    <div>
      {/* Top Header */}
      <div className="sticky top-[53px] z-30 bg-[#0A1A0F] border-b border-[#1B3D22] px-4 py-3">
        <div className="flex items-center justify-between mb-3">
          <div>
            <h2 className="text-lg font-extrabold text-white">Menu Catalog</h2>
            <p className="text-xs text-[#81C784]">
              {items.length} items configured • {items.filter((i) => i.status === 'Available').length} active
            </p>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={loadMenu}
              disabled={loading}
              className="p-2 text-[#81C784] hover:text-[#00FF41] rounded-lg transition-colors cursor-pointer"
              title="Refresh Menu"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            </button>
            <button
              onClick={openAddModal}
              className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-[#00FF41] text-[#003300] font-bold text-xs tracking-wide hover:bg-[#00e63a] transition-all cursor-pointer shadow-md"
            >
              <Plus className="w-4 h-4 stroke-[3]" />
              Add Item
            </button>
          </div>
        </div>

        {/* Search & Category Filter */}
        <div className="space-y-2">
          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-2.5 text-[#9E9E9E]" />
            <input
              type="text"
              placeholder="Search dishes or categories..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-[#0D2B15] border border-[#1B3D22] rounded-xl pl-9 pr-3 py-1.5 text-xs text-white placeholder-[#9E9E9E] focus:outline-none focus:border-[#00FF41]"
            />
          </div>

          <div className="flex gap-1.5 overflow-x-auto no-scrollbar py-0.5">
            <button
              onClick={() => setSelectedCategoryFilter('all')}
              className={`px-2.5 py-1 rounded-lg text-[11px] font-bold whitespace-nowrap transition-colors cursor-pointer ${
                selectedCategoryFilter === 'all'
                  ? 'bg-[#00FF41] text-[#003300]'
                  : 'bg-[#0F3318] text-[#81C784] hover:bg-[#1B5E20]'
              }`}
            >
              All
            </button>
            {MENU_CATEGORIES.map((cat) => (
              <button
                key={cat}
                onClick={() => setSelectedCategoryFilter(cat)}
                className={`px-2.5 py-1 rounded-lg text-[11px] font-bold whitespace-nowrap transition-colors cursor-pointer ${
                  selectedCategoryFilter === cat
                    ? 'bg-[#00FF41] text-[#003300]'
                    : 'bg-[#0F3318] text-[#81C784] hover:bg-[#1B5E20]'
                }`}
              >
                {cat}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Menu List */}
      <div className="p-4 sm:p-5 divide-y divide-[#1B3D22]">
        {filteredItems.length === 0 ? (
          <div className="py-20 text-center">
            <p className="text-sm text-[#9E9E9E]">No menu items found</p>
          </div>
        ) : (
          filteredItems.map((item) => (
            <div key={item.id} className="py-3.5 first:pt-0 last:pb-0 flex items-center justify-between gap-3">
              <div className="flex items-center gap-3 flex-1 min-w-0">
                {/* Image / Icon */}
                <div className="w-14 h-14 rounded-xl bg-[#0F3318] border border-[#1B3D22] overflow-hidden flex-shrink-0 flex items-center justify-center">
                  {item.imageUrl ? (
                    <img
                      src={item.imageUrl}
                      alt={item.name}
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <ImageIcon className="w-6 h-6 text-[#9E9E9E]" />
                  )}
                </div>

                {/* Details */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-1.5">
                    {/* Veg indicator badge */}
                    <span
                      className={`w-3.5 h-3.5 rounded-sm border flex items-center justify-center ${
                        item.isVeg
                          ? 'border-green-500'
                          : 'border-red-500'
                      }`}
                      title={item.isVeg ? 'Vegetarian' : 'Non-Vegetarian'}
                    >
                      <span
                        className={`w-1.5 h-1.5 rounded-full ${
                          item.isVeg ? 'bg-green-500' : 'bg-red-500'
                        }`}
                      />
                    </span>

                    <h3 className="text-sm font-bold text-white truncate">
                      {item.name}
                    </h3>

                    {item.isBestseller && (
                      <span title="Bestseller" className="inline-flex">
                        <Flame className="w-3.5 h-3.5 text-orange-400 flex-shrink-0" />
                      </span>
                    )}
                  </div>

                  <p className="text-xs text-[#81C784] mt-0.5 font-medium">
                    {item.category || 'General'} • ₹{item.price.toFixed(0)} • {item.prepTimeMinutes} min
                  </p>

                  {item.description && (
                    <p className="text-[11px] text-[#9E9E9E] truncate mt-0.5 max-w-sm">
                      {item.description}
                    </p>
                  )}
                </div>
              </div>

              {/* Action Controls */}
              <div className="flex items-center gap-2 flex-shrink-0">
                {/* Available toggle switch */}
                <label className="relative inline-flex items-center cursor-pointer" title="Toggle item availability">
                  <input
                    type="checkbox"
                    checked={item.status === 'Available'}
                    onChange={() => toggleAvailability(item)}
                    className="sr-only peer"
                  />
                  <div className="w-9 h-5 bg-[#0F3318] peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-[#00FF41]"></div>
                </label>

                {/* Edit Button */}
                <button
                  onClick={() => openEditModal(item)}
                  className="p-1.5 text-[#00FF41] hover:bg-[#1B5E20]/40 rounded-lg cursor-pointer"
                  title="Edit item"
                >
                  <Edit2 className="w-4 h-4" />
                </button>

                {/* Delete Button */}
                <button
                  onClick={() => handleDelete(item)}
                  className="p-1.5 text-red-400 hover:bg-red-500/20 rounded-lg cursor-pointer"
                  title="Delete item"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Add / Edit Item Modal */}
      {editingItem !== null && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-xs overflow-y-auto">
          <div className="bg-[#0D2B15] border border-[#1B5E20] rounded-2xl max-w-md w-full p-5 sm:p-6 shadow-2xl my-8">
            <h3 className="text-lg font-extrabold text-white mb-4">
              {editingItem === 'new' ? 'Add Menu Item' : 'Edit Menu Item'}
            </h3>

            <div className="space-y-3.5 max-h-[70vh] overflow-y-auto pr-1">
              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Item Name *
                </label>
                <input
                  type="text"
                  placeholder="e.g. Shahi Paneer Butter Masala"
                  value={formName}
                  onChange={(e) => setFormName(e.target.value)}
                  className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3 py-2 text-sm text-white placeholder-[#9E9E9E] focus:outline-none focus:border-[#00FF41]"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Category
                </label>
                <select
                  value={formCategory}
                  onChange={(e) => setFormCategory(e.target.value)}
                  className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3 py-2 text-sm text-white focus:outline-none focus:border-[#00FF41]"
                >
                  {MENU_CATEGORIES.map((c) => (
                    <option key={c} value={c} className="bg-[#0D2B15] text-white">
                      {c}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Price (₹) *
                </label>
                <input
                  type="number"
                  placeholder="240"
                  value={formPrice}
                  onChange={(e) => setFormPrice(e.target.value)}
                  className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3 py-2 text-sm text-white placeholder-[#9E9E9E] focus:outline-none focus:border-[#00FF41]"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1.5">
                  Preparation Time
                </label>
                <div className="flex flex-wrap gap-1.5">
                  {[10, 15, 20, 25, 30, 45, 60].map((m) => (
                    <button
                      key={m}
                      type="button"
                      onClick={() => setFormPrepTime(m)}
                      className={`px-3 py-1.5 rounded-xl text-xs font-bold cursor-pointer transition-colors ${
                        formPrepTime === m
                          ? 'bg-[#00FF41] text-[#003300]'
                          : 'bg-[#0F3318] text-white hover:bg-[#1B5E20]'
                      }`}
                    >
                      {m} min
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Description
                </label>
                <textarea
                  rows={2}
                  placeholder="Ingredients, taste, and portion size details..."
                  value={formDescription}
                  onChange={(e) => setFormDescription(e.target.value)}
                  className="w-full bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3 py-2 text-sm text-white placeholder-[#9E9E9E] focus:outline-none focus:border-[#00FF41]"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#81C784] mb-1">
                  Image URL or Upload
                </label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    placeholder="https://... or upload photo"
                    value={formImageUrl}
                    onChange={(e) => setFormImageUrl(e.target.value)}
                    className="flex-1 bg-[#0F3318] border border-[#1B3D22] rounded-xl px-3 py-2 text-xs text-white placeholder-[#9E9E9E] focus:outline-none focus:border-[#00FF41]"
                  />
                  <input
                    type="file"
                    ref={fileInputRef}
                    onChange={handleFileUpload}
                    accept="image/*"
                    className="hidden"
                  />
                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    disabled={uploading}
                    className="px-3 py-2 rounded-xl border border-[#1B3D22] bg-[#0F3318] hover:bg-[#1B5E20] text-white text-xs font-semibold flex items-center gap-1.5 cursor-pointer"
                  >
                    <Upload className="w-4 h-4 text-[#00FF41]" />
                    {uploading ? '...' : 'Upload'}
                  </button>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3 pt-1">
                <label className="flex items-center gap-2 p-2.5 rounded-xl bg-[#0F3318] border border-[#1B3D22] cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formIsVeg}
                    onChange={(e) => setFormIsVeg(e.target.checked)}
                    className="rounded text-[#00FF41] focus:ring-0"
                  />
                  <span className="text-xs font-bold text-white">Pure Veg</span>
                </label>

                <label className="flex items-center gap-2 p-2.5 rounded-xl bg-[#0F3318] border border-[#1B3D22] cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formIsBestseller}
                    onChange={(e) => setFormIsBestseller(e.target.checked)}
                    className="rounded text-orange-400 focus:ring-0"
                  />
                  <span className="text-xs font-bold text-white flex items-center gap-1">
                    Bestseller <Flame className="w-3.5 h-3.5 text-orange-400" />
                  </span>
                </label>
              </div>
            </div>

            <div className="flex items-center gap-3 pt-5 mt-4 border-t border-[#1B3D22]">
              <button
                type="button"
                onClick={() => setEditingItem(null)}
                className="flex-1 py-2.5 rounded-xl border border-[#1B3D22] text-[#81C784] hover:bg-[#0F3318] text-xs font-bold cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleSaveItem}
                className="flex-1 py-2.5 rounded-xl bg-[#00FF41] text-[#003300] text-xs font-extrabold hover:bg-[#00e63a] transition-all cursor-pointer shadow-md"
              >
                Save Item
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
