import { useEffect, useMemo, useRef, useState } from 'react';
import toast from 'react-hot-toast';
import { FileJson2, Plus, RefreshCcw, Save, Search, Trash2 } from 'lucide-react';
import apiClient from '../services/apiClient';

type ValueKind = 'string' | 'number' | 'boolean' | 'json' | 'null';

interface ResourceEntry {
  id: string;
  key: string;
  valueKind: ValueKind;
  valueText: string;
}

interface FrontendResourceEntryResponse {
  key: string;
  value: unknown;
}

interface FrontendResourceResponse {
  resourceKey: string;
  source: string;
  updatedBy: string | null;
  updatedAt: string | null;
  entries?: FrontendResourceEntryResponse[];
}

const entryId = () => `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

const inferValueKind = (value: unknown): ValueKind => {
  if (value === null) {
    return 'null';
  }
  if (typeof value === 'string') {
    return 'string';
  }
  if (typeof value === 'number') {
    return 'number';
  }
  if (typeof value === 'boolean') {
    return 'boolean';
  }
  return 'json';
};

const toEditorValue = (value: unknown, kind: ValueKind) => {
  switch (kind) {
    case 'string':
      return typeof value === 'string' ? value : String(value ?? '');
    case 'number':
      return typeof value === 'number' ? String(value) : '';
    case 'boolean':
      return value === true ? 'true' : 'false';
    case 'null':
      return 'null';
    case 'json':
    default:
      return JSON.stringify(value, null, 2);
  }
};

const createEntry = (key = '', value: unknown = ''): ResourceEntry => {
  const valueKind = inferValueKind(value);
  return {
    id: entryId(),
    key,
    valueKind,
    valueText: toEditorValue(value, valueKind),
  };
};

const normalizeEntries = (payload: FrontendResourceResponse): ResourceEntry[] => {
  if (!Array.isArray(payload.entries)) {
    return [];
  }
  return payload.entries.map((entry) => createEntry(entry.key, entry.value));
};

const parseEntryValue = (entry: ResourceEntry): unknown => {
  switch (entry.valueKind) {
    case 'string':
      return entry.valueText;
    case 'number': {
      const trimmed = entry.valueText.trim();
      if (!trimmed) {
        throw new Error(`Value for "${entry.key}" must be a number.`);
      }
      const parsed = Number(trimmed);
      if (Number.isNaN(parsed)) {
        throw new Error(`Value for "${entry.key}" must be a valid number.`);
      }
      return parsed;
    }
    case 'boolean':
      return entry.valueText === 'true';
    case 'null':
      return null;
    case 'json':
    default:
      return JSON.parse(entry.valueText);
  }
};

const extractErrorMessage = (error: unknown, fallback: string) => {
  if (
    typeof error === 'object' &&
    error !== null &&
    'response' in error &&
    typeof (error as { response?: { data?: { message?: string } } }).response?.data?.message === 'string'
  ) {
    return (error as { response?: { data?: { message?: string } } }).response?.data?.message ?? fallback;
  }
  return fallback;
};

const kindLabel: Record<ValueKind, string> = {
  string: 'Text',
  number: 'Number',
  boolean: 'Boolean',
  json: 'JSON',
  null: 'Null',
};

export const Resources = () => {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [resource, setResource] = useState<FrontendResourceResponse | null>(null);
  const [entries, setEntries] = useState<ResourceEntry[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [focusEntryId, setFocusEntryId] = useState<string | null>(null);
  const keyInputRefs = useRef<Record<string, HTMLInputElement | null>>({});

  const loadResource = async () => {
    try {
      setLoading(true);
      const response = await apiClient.get('/admin/frontend-resources');
      const data: FrontendResourceResponse = response.data.data;
      const nextEntries = normalizeEntries(data);
      setResource(data);
      setEntries(nextEntries.length > 0 ? nextEntries : [createEntry('urls.websiteBaseUrl', 'https://throttle.app')]);
    } catch (error: unknown) {
      console.error(error);
      toast.error(extractErrorMessage(error, 'Failed to load resources'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadResource();
  }, []);

  useEffect(() => {
    if (!focusEntryId) {
      return;
    }
    const handle = window.requestAnimationFrame(() => {
      keyInputRefs.current[focusEntryId]?.focus();
    });
    return () => window.cancelAnimationFrame(handle);
  }, [entries, focusEntryId]);

  const validation = useMemo(() => {
    for (const entry of entries) {
      const trimmedKey = entry.key.trim();
      if (!trimmedKey) {
        return { valid: false, message: 'Every resource row needs a key.' };
      }

      try {
        parseEntryValue(entry);
      } catch (error) {
        return {
          valid: false,
          message: error instanceof Error ? error.message : `Invalid value for "${trimmedKey}".`,
        };
      }
    }

    return { valid: true, message: 'All resource entries are valid. If a key appears more than once, the last one overrides the earlier ones.' };
  }, [entries]);

  const filteredEntries = useMemo(() => {
    const term = searchTerm.trim().toLowerCase();
    if (!term) {
      return entries;
    }
    return entries.filter((entry) => entry.key.toLowerCase().includes(term));
  }, [entries, searchTerm]);

  const planSummaries = useMemo(() => {
    const planEntry = entries.find((entry) => entry.key.trim() === 'subscriptions.plans');
    if (!planEntry) {
      return [];
    }

    try {
      const parsed = parseEntryValue(planEntry);
      if (!Array.isArray(parsed)) {
        return [];
      }

      return parsed
        .map((plan) => {
          if (!plan || typeof plan !== 'object') {
            return null;
          }
          const typedPlan = plan as { id?: unknown; name?: unknown; priceInr?: unknown };
          return {
            id: String(typedPlan.id ?? ''),
            name: String(typedPlan.name ?? ''),
            priceInr: String(typedPlan.priceInr ?? ''),
          };
        })
        .filter((plan): plan is { id: string; name: string; priceInr: string } => Boolean(plan));
    } catch {
      return [];
    }
  }, [entries]);

  const updateEntry = (id: string, patch: Partial<ResourceEntry>) => {
    setEntries((current) => current.map((entry) => (entry.id === id ? { ...entry, ...patch } : entry)));
  };

  const changeValueKind = (id: string, nextKind: ValueKind) => {
    setEntries((current) =>
      current.map((entry) => {
        if (entry.id !== id) {
          return entry;
        }

        try {
          const parsed = parseEntryValue(entry);
          return {
            ...entry,
            valueKind: nextKind,
            valueText: toEditorValue(parsed, nextKind),
          };
        } catch {
          const fallback =
            nextKind === 'boolean'
              ? 'false'
              : nextKind === 'null'
                ? 'null'
                : nextKind === 'json'
                  ? '{}'
                  : '';
          return { ...entry, valueKind: nextKind, valueText: fallback };
        }
      }),
    );
  };

  const addEntry = () => {
    const created = createEntry('', '');
    setSearchTerm('');
    setEntries((current) => [created, ...current]);
    setFocusEntryId(created.id);
  };

  const removeEntry = (id: string) => {
    setEntries((current) => {
      if (current.length === 1) {
        return current;
      }
      return current.filter((entry) => entry.id !== id);
    });
  };

  const resetEntries = () => {
    if (!resource) {
      return;
    }
    const nextEntries = normalizeEntries(resource);
    setSearchTerm('');
    setEntries(nextEntries.length > 0 ? nextEntries : [createEntry('urls.websiteBaseUrl', 'https://throttle.app')]);
  };

  const saveResource = async () => {
    if (!validation.valid) {
      toast.error(validation.message);
      return;
    }

    const payload = entries.map((entry) => ({
      key: entry.key.trim(),
      value: parseEntryValue(entry),
    }));

    try {
      setSaving(true);
      const response = await apiClient.put('/admin/frontend-resources', {
        entries: payload,
      });
      const data: FrontendResourceResponse = response.data.data;
      setResource(data);
      setEntries(normalizeEntries(data));
      toast.success('Frontend resources updated');
    } catch (error: unknown) {
      console.error(error);
      toast.error(extractErrorMessage(error, 'Failed to save resources'));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="animate-in fade-in duration-500 space-y-6">
      <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <h1 className="text-3xl font-display font-bold text-slate-900 dark:text-white">Frontend Resources</h1>
          <p className="mt-1 font-medium text-slate-600 dark:text-slate-400">
            Edit simple dotted keys like `urls.websiteBaseUrl` or `subscriptions.title` with plain values.
          </p>
        </div>
        <div className="flex flex-wrap gap-3">
          <button
            onClick={() => void loadResource()}
            disabled={loading || saving}
            className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 shadow-sm transition hover:border-slate-300 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-60 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200 dark:hover:border-slate-600 dark:hover:bg-slate-800"
          >
            <RefreshCcw size={16} />
            Reload
          </button>
          <button
            onClick={resetEntries}
            disabled={!resource || loading || saving}
            className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 shadow-sm transition hover:border-slate-300 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-60 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200 dark:hover:border-slate-600 dark:hover:bg-slate-800"
          >
            <FileJson2 size={16} />
            Update Form
          </button>
          <button
            onClick={saveResource}
            disabled={loading || saving}
            className="inline-flex items-center gap-2 rounded-xl bg-indigo-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
          >
            <Save size={16} />
            {saving ? 'Saving...' : 'Save Changes'}
          </button>
        </div>
      </div>

      <div className="grid gap-6 xl:grid-cols-[minmax(0,1.75fr)_minmax(320px,0.75fr)]">
        <section className="glass-panel rounded-2xl border border-slate-200/80 p-0 shadow-sm dark:border-slate-800/70">
          <div className="border-b border-slate-200/80 px-6 py-4 dark:border-slate-800/70">
            <div className="flex flex-col gap-4">
              <div>
                <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Resource Entries</h2>
                <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
                  Search by key, add a new key instantly at the top, and choose the right value type.
                </p>
              </div>
              <div className="flex items-stretch gap-3">
                <div className="relative flex-1">
                  <Search size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                  <input
                    value={searchTerm}
                    onChange={(event) => setSearchTerm(event.target.value)}
                    placeholder="Search key"
                    className="h-full w-full rounded-xl border border-slate-200 bg-white py-2.5 pl-10 pr-4 text-sm text-slate-900 outline-none transition focus:border-indigo-400 dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                  />
                </div>
                <button
                  onClick={addEntry}
                  className="inline-flex min-w-[132px] items-center justify-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 shadow-sm transition hover:border-slate-300 hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200 dark:hover:border-slate-600 dark:hover:bg-slate-800"
                >
                  <Plus size={16} />
                  Add Key
                </button>
              </div>
            </div>
          </div>

          <div className="space-y-4 p-4">
            {filteredEntries.length === 0 ? (
              <div className="rounded-2xl border border-dashed border-slate-300 bg-white/70 px-4 py-10 text-center text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-900/60 dark:text-slate-400">
                No keys matched your search.
              </div>
            ) : (
              filteredEntries.map((entry) => (
                <div
                  key={entry.id}
                  className="rounded-2xl border border-slate-200 bg-white/80 p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900/80"
                >
                  <div className="grid gap-4">
                    <div className="grid gap-4 md:grid-cols-[minmax(260px,1fr)_180px_48px] md:items-end">
                      <div>
                        <label className="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-300">Key</label>
                        <input
                          ref={(node) => {
                            keyInputRefs.current[entry.id] = node;
                          }}
                          value={entry.key}
                          onChange={(event) => updateEntry(entry.id, { key: event.target.value })}
                          placeholder="SUBSCRIPTION_PRO_FEE or urls.websiteBaseUrl"
                          className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-indigo-400 disabled:cursor-not-allowed disabled:bg-slate-100 dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:disabled:bg-slate-900"
                        />
                      </div>

                      <div>
                        <label className="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-300">Type</label>
                        <select
                          value={entry.valueKind}
                          onChange={(event) => changeValueKind(entry.id, event.target.value as ValueKind)}
                          className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-indigo-400 dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                        >
                          {(['string', 'number', 'boolean', 'json', 'null'] as ValueKind[]).map((kind) => (
                            <option key={kind} value={kind}>
                              {kindLabel[kind]}
                            </option>
                          ))}
                        </select>
                      </div>

                      <div className="md:justify-self-end">
                        <label className="mb-2 block text-sm font-semibold text-transparent select-none">Delete</label>
                        <button
                          onClick={() => removeEntry(entry.id)}
                          disabled={entries.length === 1}
                          aria-label={`Delete ${entry.key || 'resource'} key`}
                          title="Delete key"
                          className="inline-flex h-[48px] w-[48px] items-center justify-center rounded-xl border border-rose-200 bg-rose-50 text-rose-700 transition hover:bg-rose-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-rose-500/30 dark:bg-rose-500/10 dark:text-rose-300 dark:hover:bg-rose-500/20"
                        >
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </div>

                    <div>
                      <label className="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-300">Value</label>
                      {entry.valueKind === 'boolean' ? (
                        <select
                          value={entry.valueText}
                          onChange={(event) => updateEntry(entry.id, { valueText: event.target.value })}
                          className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-indigo-400 dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                        >
                          <option value="true">true</option>
                          <option value="false">false</option>
                        </select>
                      ) : entry.valueKind === 'json' ? (
                        <textarea
                          value={entry.valueText}
                          onChange={(event) => updateEntry(entry.id, { valueText: event.target.value })}
                          spellCheck={false}
                          placeholder='{"hello":"world"}'
                          className="min-h-[140px] w-full rounded-xl border border-slate-200 bg-slate-950 px-4 py-3 font-mono text-sm leading-6 text-emerald-100 outline-none transition focus:border-indigo-400 dark:border-slate-700"
                        />
                      ) : (
                        <input
                          value={entry.valueKind === 'null' ? 'null' : entry.valueText}
                          onChange={(event) => updateEntry(entry.id, { valueText: event.target.value })}
                          disabled={entry.valueKind === 'null'}
                          placeholder={entry.valueKind === 'string' ? 'https://throttle.app' : '499'}
                          className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 outline-none transition focus:border-indigo-400 disabled:cursor-not-allowed disabled:bg-slate-100 dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100 dark:disabled:bg-slate-900"
                        />
                      )}
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </section>

        <aside className="space-y-6">
          <section className="glass-panel rounded-2xl border border-slate-200/80 p-6 shadow-sm dark:border-slate-800/70">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">How To Use</h2>
            <div className="mt-4 space-y-3 text-sm text-slate-600 dark:text-slate-400">
              <p>`SUBSCRIPTION_PRO_FEE` with type `Number` updates the Pro Club subscription fee.</p>
              <p>`SUBSCRIPTION_RIDER_PLUS_FEE` with type `Number` updates the Rider Plus fee.</p>
              <p>`WEBSITE_URL` with type `Text` updates the website URL.</p>
              <p>You can still use dotted keys like `subscriptions.title` when you need them.</p>
              <p>A completely new custom key is allowed, but it only affects the app if the frontend is coded to read it.</p>
            </div>
          </section>

          <section className="glass-panel rounded-2xl border border-slate-200/80 p-6 shadow-sm dark:border-slate-800/70">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Status</h2>
            <dl className="mt-4 space-y-3 text-sm">
              <div className="flex items-center justify-between gap-3">
                <dt className="text-slate-500 dark:text-slate-400">Resource key</dt>
                <dd className="font-semibold text-slate-900 dark:text-slate-200">{resource?.resourceKey ?? 'frontend-resource-config'}</dd>
              </div>
              <div className="flex items-center justify-between gap-3">
                <dt className="text-slate-500 dark:text-slate-400">Source</dt>
                <dd className="font-semibold uppercase tracking-wide text-slate-900 dark:text-slate-200">{resource?.source ?? '...'}</dd>
              </div>
              <div className="flex items-center justify-between gap-3">
                <dt className="text-slate-500 dark:text-slate-400">Updated by</dt>
                <dd className="font-semibold text-slate-900 dark:text-slate-200">{resource?.updatedBy ?? 'system'}</dd>
              </div>
              <div className="flex items-center justify-between gap-3">
                <dt className="text-slate-500 dark:text-slate-400">Updated at</dt>
                <dd className="font-semibold text-right text-slate-900 dark:text-slate-200">
                  {resource?.updatedAt ? new Date(resource.updatedAt).toLocaleString() : 'Not persisted yet'}
                </dd>
              </div>
            </dl>
          </section>

          <section className="glass-panel rounded-2xl border border-slate-200/80 p-6 shadow-sm dark:border-slate-800/70">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Validation</h2>
            <div className={`mt-4 rounded-2xl border px-4 py-3 text-sm font-medium ${
              validation.valid
                ? 'border-emerald-200 bg-emerald-50 text-emerald-700 dark:border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-300'
                : 'border-rose-200 bg-rose-50 text-rose-700 dark:border-rose-500/30 dark:bg-rose-500/10 dark:text-rose-300'
            }`}>
              {validation.message}
            </div>
          </section>

          <section className="glass-panel rounded-2xl border border-slate-200/80 p-6 shadow-sm dark:border-slate-800/70">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Actions</h2>
            <div className="mt-4 flex flex-col gap-3">
              <button
                onClick={resetEntries}
                disabled={!resource || loading || saving}
                className="inline-flex items-center justify-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-700 shadow-sm transition hover:border-slate-300 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-60 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200 dark:hover:border-slate-600 dark:hover:bg-slate-800"
              >
                <FileJson2 size={16} />
                Update Form
              </button>
              <button
                onClick={saveResource}
                disabled={loading || saving}
                className="inline-flex items-center justify-center gap-2 rounded-xl bg-indigo-600 px-4 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
              >
                <Save size={16} />
                {saving ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </section>

          <section className="glass-panel rounded-2xl border border-slate-200/80 p-6 shadow-sm dark:border-slate-800/70">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Plan Snapshot</h2>
            <div className="mt-4 space-y-3">
              {planSummaries.length === 0 ? (
                <p className="text-sm text-slate-500 dark:text-slate-400">No subscription plans detected in `subscriptions.plans`.</p>
              ) : (
                planSummaries.map((plan) => (
                  <div
                    key={plan.id}
                    className="rounded-2xl border border-slate-200 bg-white/80 px-4 py-3 dark:border-slate-800 dark:bg-slate-900/80"
                  >
                    <div className="flex items-center justify-between gap-3">
                      <div>
                        <p className="font-semibold text-slate-900 dark:text-slate-100">{plan.name || plan.id}</p>
                        <p className="text-xs uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">{plan.id}</p>
                      </div>
                      <p className="text-base font-bold text-indigo-600 dark:text-indigo-400">Rs {plan.priceInr}</p>
                    </div>
                  </div>
                ))
              )}
            </div>
          </section>
        </aside>
      </div>
    </div>
  );
};
