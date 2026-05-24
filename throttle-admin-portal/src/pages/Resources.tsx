import { useEffect, useState } from 'react';
import apiClient from '../services/apiClient';
import toast from 'react-hot-toast';
import { 
  Sliders, 
  ToggleLeft, 
  ToggleRight, 
  Edit3, 
  Trash2, 
  Plus, 
  Search, 
  ShieldAlert, 
  Database,
  Lock, 
  RotateCw,
  X
} from 'lucide-react';

interface Resource {
  id: number;
  resourceKey: String;
  resourceValue: String;
  resourceType: String; // STRING, BOOLEAN, NUMBER, SECRET, JSON
  category: String;    // FEATURE_FLAGS, API_KEYS, SYSTEM_RATES, OTHER
  description: String;
  isSecret: boolean;
  createdAt: String;
  updatedAt: String;
  updatedBy: String | null;
}

export const Resources = () => {
  const [resources, setResources] = useState<Resource[]>([]);
  const [filteredResources, setFilteredResources] = useState<Resource[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [activeTab, setActiveTab] = useState('ALL');
  const [refreshing, setRefreshing] = useState(false);

  // Modal State
  const [modalOpen, setModalOpen] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [selectedId, setSelectedId] = useState<number | null>(null);

  // Form State
  const [formKey, setFormKey] = useState('');
  const [formValue, setFormValue] = useState('');
  const [formType, setFormType] = useState('STRING');
  const [formCategory, setFormCategory] = useState('OTHER');
  const [formDescription, setFormDescription] = useState('');
  const [formIsSecret, setFormIsSecret] = useState(false);

  const fetchResources = async (quiet = false) => {
    if (!quiet) setLoading(true);
    try {
      const resp = await apiClient.get('/admin/resources');
      const data = resp.data.data || [];
      setResources(data);
    } catch (err) {
      console.error(err);
      toast.error('Failed to load system resources');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchResources();
  }, []);

  // Filter and Search logic
  useEffect(() => {
    let result = resources;

    // Filter by tab
    if (activeTab !== 'ALL') {
      result = result.filter(res => res.category === activeTab);
    }

    // Filter by search query
    if (searchQuery.trim() !== '') {
      const query = searchQuery.toLowerCase();
      result = result.filter(res => 
        res.resourceKey.toLowerCase().includes(query) || 
        (res.description && res.description.toLowerCase().includes(query)) ||
        (res.resourceValue && res.resourceValue.toLowerCase().includes(query))
      );
    }

    setFilteredResources(result);
  }, [resources, activeTab, searchQuery]);

  const handleRefresh = () => {
    setRefreshing(true);
    fetchResources(true);
  };

  const handleToggleFeature = async (resource: Resource) => {
    const originalValue = resource.resourceValue;
    const newValue = originalValue === 'true' ? 'false' : 'true';
    
    // Optimistic UI update
    setResources(prev => prev.map(res => 
      res.id === resource.id ? { ...res, resourceValue: newValue } : res
    ));

    try {
      await apiClient.put(`/admin/resources/${resource.id}`, {
        resourceKey: resource.resourceKey,
        resourceValue: newValue,
        resourceType: resource.resourceType,
        category: resource.category,
        description: resource.description,
        isSecret: resource.isSecret
      });
      toast.success(`${resource.resourceKey} set to ${newValue}`);
    } catch (err) {
      console.error(err);
      toast.error(`Failed to update ${resource.resourceKey}`);
      // Revert UI on failure
      setResources(prev => prev.map(res => 
        res.id === resource.id ? { ...res, resourceValue: originalValue } : res
      ));
    }
  };

  const handleDelete = async (id: number, key: String) => {
    if (!window.confirm(`Are you sure you want to delete the configuration resource "${key}"?`)) {
      return;
    }

    try {
      await apiClient.delete(`/admin/resources/${id}`);
      toast.success(`Resource config "${key}" deleted successfully`);
      setResources(prev => prev.filter(res => res.id !== id));
    } catch (err) {
      console.error(err);
      toast.error(`Failed to delete resource config "${key}"`);
    }
  };

  const handleOpenCreateModal = () => {
    setEditMode(false);
    setSelectedId(null);
    setFormKey('');
    setFormValue('');
    setFormType('STRING');
    setFormCategory('OTHER');
    setFormDescription('');
    setFormIsSecret(false);
    setModalOpen(true);
  };

  const handleOpenEditModal = (resource: Resource) => {
    setEditMode(true);
    setSelectedId(resource.id);
    setFormKey(String(resource.resourceKey));
    setFormValue(String(resource.resourceValue));
    setFormType(String(resource.resourceType));
    setFormCategory(String(resource.category));
    setFormDescription(String(resource.description || ''));
    setFormIsSecret(resource.isSecret);
    setModalOpen(true);
  };

  const handleFormSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!formKey.trim()) {
      toast.error('Resource Key is required');
      return;
    }

    const payload = {
      resourceKey: formKey.toUpperCase().replace(/\s+/g, '_'),
      resourceValue: formValue,
      resourceType: formType,
      category: formCategory,
      description: formDescription,
      isSecret: formIsSecret
    };

    try {
      if (editMode && selectedId !== null) {
        await apiClient.put(`/admin/resources/${selectedId}`, payload);
        toast.success(`Config ${formKey} updated successfully`);
      } else {
        await apiClient.post('/admin/resources', payload);
        toast.success(`New config ${formKey} registered successfully`);
      }
      setModalOpen(false);
      fetchResources(true);
    } catch (err: any) {
      console.error(err);
      toast.error(err.response?.data?.message || 'Failed to save resource configuration');
    }
  };

  // Helper stats computation
  const stats = {
    total: resources.length,
    activeFlags: resources.filter(r => r.resourceType === 'BOOLEAN' && r.resourceValue === 'true').length,
    secrets: resources.filter(r => r.isSecret).length,
    systemRates: resources.filter(r => r.category === 'SYSTEM_RATES').length
  };

  return (
    <div className="animate-in fade-in duration-500">
      {/* Header */}
      <div className="mb-8 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 className="text-3xl font-display font-bold text-slate-900 dark:text-white flex items-center space-x-3">
            <Sliders className="w-8 h-8 text-indigo-600 dark:text-indigo-400" />
            <span>Resources & Configs</span>
          </h1>
          <p className="text-slate-600 dark:text-slate-400 mt-1 font-medium">
            Manage global deployment API keys, runtime feature flags, and billing coefficients.
          </p>
        </div>

        <div className="flex items-center space-x-3 w-full md:w-auto">
          <button 
            onClick={handleRefresh}
            className="p-2.5 rounded-xl border border-slate-200 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800/50 text-slate-500 dark:text-slate-400 transition-all cursor-pointer"
            title="Refresh configurations"
          >
            <RotateCw size={18} className={`${refreshing ? 'animate-spin' : ''}`} />
          </button>
          
          <button 
            onClick={handleOpenCreateModal}
            className="flex-1 md:flex-initial flex items-center justify-center space-x-2 px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-medium rounded-xl shadow-sm transition-all duration-300 cursor-pointer"
          >
            <Plus size={18} />
            <span>Register Resource</span>
          </button>
        </div>
      </div>

      {/* Warning Notification Banner */}
      <div className="glass-panel rounded-2xl p-4 mb-8 border-l-4 border-l-amber-500 bg-amber-50/50 dark:bg-amber-500/5 flex items-start space-x-3.5">
        <ShieldAlert className="w-5 h-5 text-amber-600 dark:text-amber-500 shrink-0 mt-0.5" />
        <div>
          <h4 className="text-sm font-semibold text-slate-900 dark:text-amber-300">Production Impact Awareness</h4>
          <p className="text-xs text-slate-600 dark:text-slate-400 mt-0.5 leading-relaxed">
            API Keys, credentials, and feature flag states are evaluated dynamically by downstream applications. Modifying values updates live caches instantly and publishes an immutable trace to Kafka audit indexes.
          </p>
        </div>
      </div>

      {/* Overview Analytics Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <div className="glass-panel p-5 rounded-2xl">
          <p className="text-xs text-slate-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Total Configurations</p>
          <p className="text-3xl font-display font-bold text-slate-900 dark:text-white mt-2">{stats.total}</p>
        </div>
        <div className="glass-panel p-5 rounded-2xl">
          <p className="text-xs text-slate-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Enabled Flags</p>
          <p className="text-3xl font-display font-bold text-emerald-600 dark:text-emerald-400 mt-2">{stats.activeFlags}</p>
        </div>
        <div className="glass-panel p-5 rounded-2xl">
          <p className="text-xs text-slate-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Encrypted Secrets</p>
          <p className="text-3xl font-display font-bold text-indigo-600 dark:text-indigo-400 mt-2">{stats.secrets}</p>
        </div>
        <div className="glass-panel p-5 rounded-2xl">
          <p className="text-xs text-slate-500 dark:text-slate-400 font-semibold uppercase tracking-wider">Pricing / Limits</p>
          <p className="text-3xl font-display font-bold text-indigo-600 dark:text-indigo-400 mt-2">{stats.systemRates}</p>
        </div>
      </div>

      {/* Search & Tabs bar */}
      <div className="flex flex-col lg:flex-row justify-between items-stretch lg:items-center gap-4 mb-6">
        {/* Navigation Tabs */}
        <div className="flex p-1 bg-slate-100 dark:bg-slate-800/40 rounded-xl overflow-x-auto select-none gap-1">
          {['ALL', 'FEATURE_FLAGS', 'API_KEYS', 'SYSTEM_RATES', 'OTHER'].map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-4 py-2 text-xs font-semibold rounded-lg transition-all cursor-pointer whitespace-nowrap ${
                activeTab === tab 
                  ? 'bg-white dark:bg-slate-800 text-indigo-600 dark:text-indigo-400 shadow-sm' 
                  : 'text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'
              }`}
            >
              {tab.replace('_', ' ')}
            </button>
          ))}
        </div>

        {/* Search */}
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3.5 top-3 w-4 h-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search resources by key or description..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="glass-input pl-10 pr-4 py-2 w-full text-sm"
          />
        </div>
      </div>

      {/* Main Grid List */}
      {loading ? (
        <div className="glass-panel rounded-2xl p-12 text-center">
          <p className="text-slate-500 font-medium">Loading system configurations...</p>
        </div>
      ) : filteredResources.length === 0 ? (
        <div className="glass-panel rounded-2xl p-16 text-center">
          <Sliders className="w-12 h-12 text-slate-400 dark:text-slate-600 mx-auto mb-4" />
          <h3 className="text-lg font-bold text-slate-900 dark:text-white">No configurations found</h3>
          <p className="text-slate-500 dark:text-slate-400 text-sm mt-1 max-w-sm mx-auto">
            Try adjusting your search criteria or register a new resource mapping using the button above.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {filteredResources.map((res) => {
            const isFeatureFlag = res.resourceType === 'BOOLEAN';
            const isSecret = res.isSecret;
            const isTrue = res.resourceValue === 'true';

            return (
              <div 
                key={res.id} 
                className="glass-panel p-6 rounded-2xl border border-slate-200 dark:border-slate-800/80 shadow-sm flex flex-col justify-between"
              >
                <div>
                  {/* Card Header badges */}
                  <div className="flex justify-between items-start mb-3">
                    <span className={`px-2 py-0.5 rounded text-[10px] uppercase font-bold tracking-wider ${
                      res.category === 'FEATURE_FLAGS' ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400' :
                      res.category === 'API_KEYS' ? 'bg-indigo-100 text-indigo-700 dark:bg-indigo-500/10 dark:text-indigo-400' :
                      res.category === 'SYSTEM_RATES' ? 'bg-purple-100 text-purple-700 dark:bg-purple-500/10 dark:text-purple-400' :
                      'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400'
                    }`}>
                      {res.category.replace('_', ' ')}
                    </span>

                    <span className="text-[10px] font-mono text-slate-400 dark:text-slate-500">
                      {res.resourceType}
                    </span>
                  </div>

                  {/* Resource Key Name */}
                  <h3 className="text-md font-bold text-slate-900 dark:text-white flex items-center font-mono">
                    {res.resourceKey}
                  </h3>

                  {/* Description */}
                  <p className="text-xs text-slate-600 dark:text-slate-400 mt-2 leading-relaxed min-h-[2.5rem]">
                    {res.description || 'No description provided.'}
                  </p>
                </div>

                {/* Value Section */}
                <div className="mt-5 pt-4 border-t border-slate-100 dark:border-slate-800/40 flex items-center justify-between">
                  <div className="flex-1 mr-4">
                    {isFeatureFlag ? (
                      <div className="flex items-center space-x-2">
                        <span className={`text-xs font-semibold ${isTrue ? 'text-emerald-600 dark:text-emerald-400' : 'text-slate-500'}`}>
                          {isTrue ? 'Enabled' : 'Disabled'}
                        </span>
                      </div>
                    ) : (
                      <div className="flex items-center space-x-2">
                        {isSecret && <Lock className="w-3.5 h-3.5 text-indigo-500" />}
                        <span className="text-xs font-mono font-bold text-slate-800 dark:text-slate-200 select-all truncate">
                          {res.resourceValue}
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Action buttons */}
                  <div className="flex items-center space-x-2">
                    {isFeatureFlag ? (
                      <button 
                        onClick={() => handleToggleFeature(res)}
                        className="text-slate-400 hover:text-indigo-600 transition-colors cursor-pointer"
                        title="Toggle Feature Flag"
                      >
                        {isTrue ? (
                          <ToggleRight className="w-8 h-8 text-emerald-500" />
                        ) : (
                          <ToggleLeft className="w-8 h-8" />
                        )}
                      </button>
                    ) : null}

                    <button
                      onClick={() => handleOpenEditModal(res)}
                      className="p-1.5 rounded-lg border border-slate-200 dark:border-slate-800/60 text-slate-500 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors cursor-pointer"
                      title="Edit configuration"
                    >
                      <Edit3 size={14} />
                    </button>

                    <button
                      onClick={() => handleDelete(res.id, res.resourceKey)}
                      className="p-1.5 rounded-lg border border-slate-200 dark:border-slate-800/60 text-slate-400 hover:text-rose-600 dark:hover:text-rose-400 hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors cursor-pointer"
                      title="Delete configuration"
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                </div>

                {/* Audit footprint */}
                <div className="mt-2 flex items-center justify-between text-[10px] text-slate-400 font-mono">
                  <span>Last Updated By: {res.updatedBy || 'System'}</span>
                  <span>{new Date(String(res.updatedAt)).toLocaleDateString()}</span>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Modal - Create/Edit Config */}
      {modalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="glass-panel w-full max-w-lg rounded-2xl overflow-hidden shadow-xl border border-slate-200 dark:border-slate-800 flex flex-col">
            
            {/* Modal Header */}
            <div className="p-6 border-b border-slate-200 dark:border-slate-800/50 flex justify-between items-center bg-slate-50/50 dark:bg-slate-800/20">
              <h2 className="text-xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
                <Database className="w-5 h-5 text-indigo-500" />
                <span>{editMode ? 'Edit Configuration' : 'Register Configuration'}</span>
              </h2>
              <button 
                onClick={() => setModalOpen(false)}
                className="p-1.5 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-500 dark:text-slate-400 transition-colors cursor-pointer"
              >
                <X size={18} />
              </button>
            </div>

            {/* Modal Form */}
            <form onSubmit={handleFormSubmit} className="p-6 space-y-4 flex-1">
              {/* Resource Key */}
              <div>
                <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
                  Resource Key
                </label>
                <input
                  type="text"
                  required
                  disabled={editMode}
                  value={formKey}
                  onChange={(e) => setFormKey(e.target.value)}
                  placeholder="e.g. GOOGLE_MAPS_KEY or FEATURE_PROMOTIONS"
                  className="glass-input w-full px-3 py-2 text-sm font-mono uppercase disabled:opacity-50 disabled:bg-slate-50 dark:disabled:bg-slate-900/60"
                />
                <p className="text-[10px] text-slate-400 mt-1">
                  Unique global key identifier. Spaces are converted to underscores.
                </p>
              </div>

              {/* Type and Category dropdowns */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
                    Value Type
                  </label>
                  <select
                    value={formType}
                    onChange={(e) => {
                      setFormType(e.target.value);
                      if (e.target.value === 'SECRET') {
                        setFormIsSecret(true);
                      } else {
                        setFormIsSecret(false);
                      }
                    }}
                    className="glass-input w-full px-3 py-2 text-sm"
                  >
                    <option value="STRING">STRING</option>
                    <option value="BOOLEAN">BOOLEAN</option>
                    <option value="NUMBER">NUMBER</option>
                    <option value="SECRET">SECRET (AES Encrypted)</option>
                    <option value="JSON">JSON</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
                    Category Group
                  </label>
                  <select
                    value={formCategory}
                    onChange={(e) => setFormCategory(e.target.value)}
                    className="glass-input w-full px-3 py-2 text-sm"
                  >
                    <option value="FEATURE_FLAGS">FEATURE FLAGS</option>
                    <option value="API_KEYS">API KEYS & SECRETS</option>
                    <option value="SYSTEM_RATES">SYSTEM RATES & LIMITS</option>
                    <option value="OTHER">OTHER CONFIG</option>
                  </select>
                </div>
              </div>

              {/* Resource Value */}
              <div>
                <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
                  Resource Value
                </label>
                {formType === 'BOOLEAN' ? (
                  <select
                    value={formValue}
                    onChange={(e) => setFormValue(e.target.value)}
                    className="glass-input w-full px-3 py-2 text-sm font-mono"
                  >
                    <option value="">-- Select --</option>
                    <option value="true">true</option>
                    <option value="false">false</option>
                  </select>
                ) : (
                  <textarea
                    rows={2}
                    value={formValue}
                    onChange={(e) => setFormValue(e.target.value)}
                    placeholder={
                      formType === 'SECRET' 
                        ? (editMode ? "•••••••• (Leave unchanged, or enter a new value)" : "Enter secret plain-text value")
                        : "Enter resource config value..."
                    }
                    className="glass-input w-full px-3 py-2 text-sm font-mono resize-none"
                  />
                )}
              </div>

              {/* Secret Attribute Toggle */}
              <div className="flex items-center justify-between p-3 bg-indigo-50/30 dark:bg-indigo-500/5 rounded-xl border border-indigo-100/40 dark:border-indigo-500/10">
                <div className="flex items-center space-x-2.5">
                  <Lock className="w-4 h-4 text-indigo-500" />
                  <div>
                    <h5 className="text-xs font-semibold text-slate-900 dark:text-indigo-400">Encrypt this Secret</h5>
                    <p className="text-[10px] text-slate-500 dark:text-slate-400 mt-0.5">Encrypts the value in the PostgreSQL table at rest.</p>
                  </div>
                </div>
                <input
                  type="checkbox"
                  disabled={formType === 'SECRET'}
                  checked={formIsSecret}
                  onChange={(e) => setFormIsSecret(e.target.checked)}
                  className="w-4 h-4 text-indigo-600 accent-indigo-600 bg-gray-100 rounded border-gray-300 focus:ring-indigo-500 cursor-pointer"
                />
              </div>

              {/* Description */}
              <div>
                <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
                  Description
                </label>
                <textarea
                  rows={2}
                  value={formDescription}
                  onChange={(e) => setFormDescription(e.target.value)}
                  placeholder="Explain what this configuration does and what systems depend on it..."
                  className="glass-input w-full px-3 py-2 text-sm resize-none"
                />
              </div>

              {/* Modal footer / Actions */}
              <div className="pt-4 border-t border-slate-200 dark:border-slate-800/50 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setModalOpen(false)}
                  className="px-4 py-2 border border-slate-300 dark:border-slate-800 text-slate-700 dark:text-slate-300 text-sm font-medium rounded-xl hover:bg-slate-50 dark:hover:bg-slate-850 transition-colors cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-medium rounded-xl shadow-sm transition-colors cursor-pointer"
                >
                  Save Configuration
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
