/**
 * Reports.tsx
 *
 * Content Moderation page — lists all platform reports and allows admins to:
 *   - RESOLVE: Mark as actioned (e.g. user warned/banned)
 *   - DISMISS: Mark as invalid / no action needed
 *
 * Both actions record a resolution note and are persisted in audit logs via Kafka → Elasticsearch.
 */

import { useEffect, useState, useCallback } from 'react';
import apiClient from '../services/apiClient';
import { Flag, CheckCircle, XCircle, RefreshCw } from 'lucide-react';
import toast from 'react-hot-toast';

interface Report {
  id: number;
  reporterId: number;
  targetId: number;
  type: string;
  reason: string;
  status: 'PENDING' | 'RESOLVED' | 'DISMISSED';
  createdAt: string;
  resolvedAt?: string;
  resolutionNote?: string;
}

// ── Status pill colour mapping ──────────────────────────────────────────────
const STATUS_STYLES: Record<Report['status'], string> = {
  PENDING:   'bg-amber-100 text-amber-700 dark:bg-amber-500/10 dark:text-amber-400 border border-amber-200 dark:border-amber-500/30',
  RESOLVED:  'bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-500/30',
  DISMISSED: 'bg-slate-100 text-slate-600 dark:bg-slate-700/40 dark:text-slate-400 border border-slate-200 dark:border-slate-600/40',
};

// ── Type icon colour mapping ────────────────────────────────────────────────
const TYPE_COLORS: Record<string, string> = {
  USER:   'text-indigo-500 dark:text-indigo-400',
  RIDE:   'text-purple-500 dark:text-purple-400',
  SYSTEM: 'text-rose-500 dark:text-rose-400',
};

// ── Inline action dialog (replaces window.prompt for a production feel) ──────
interface ActionDialogProps {
  reportId: number;
  action: 'resolve' | 'dismiss';
  onConfirm: (note: string) => void;
  onCancel: () => void;
}

function ActionDialog({ reportId, action, onConfirm, onCancel }: ActionDialogProps) {
  const [note, setNote] = useState(
    action === 'resolve' ? 'Resolved by admin.' : 'Dismissed — no action required.'
  );
  const isResolve = action === 'resolve';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm animate-in fade-in duration-150">
      <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-2xl shadow-2xl w-full max-w-md mx-4 p-6 space-y-4">
        <div className="flex items-center gap-3">
          {isResolve
            ? <CheckCircle className="text-emerald-500" size={22} />
            : <XCircle className="text-slate-400" size={22} />}
          <h3 className="text-base font-bold text-slate-900 dark:text-white">
            {isResolve ? 'Resolve' : 'Dismiss'} Report #{reportId}
          </h3>
        </div>
        <p className="text-sm text-slate-500 dark:text-slate-400">
          {isResolve
            ? 'Add a resolution note documenting what action was taken.'
            : 'Add a note explaining why this report requires no action.'}
        </p>
        <textarea
          value={note}
          onChange={(e) => setNote(e.target.value)}
          rows={3}
          className="w-full px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-900 dark:text-white resize-none focus:outline-none focus:ring-2 focus:ring-indigo-500/50"
          placeholder="Enter note..."
        />
        <div className="flex gap-3 pt-1">
          <button
            onClick={() => onConfirm(note.trim() || (isResolve ? 'Resolved by admin.' : 'Dismissed — no action required.'))}
            className={`flex-1 py-2 rounded-xl text-sm font-bold transition-all ${
              isResolve
                ? 'bg-emerald-600 hover:bg-emerald-700 text-white'
                : 'bg-slate-200 dark:bg-slate-700 hover:bg-slate-300 dark:hover:bg-slate-600 text-slate-800 dark:text-slate-200'
            }`}
          >
            {isResolve ? 'Confirm Resolve' : 'Confirm Dismiss'}
          </button>
          <button
            onClick={onCancel}
            className="px-4 py-2 rounded-xl text-sm font-semibold text-slate-500 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 transition-all"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Main Component ───────────────────────────────────────────────────────────

export const Reports = () => {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeAction, setActiveAction] = useState<{ reportId: number; type: 'resolve' | 'dismiss' } | null>(null);
  const [processingId, setProcessingId] = useState<number | null>(null);
  const [filter, setFilter] = useState<'ALL' | Report['status']>('ALL');

  const fetchReports = useCallback(async () => {
    try {
      setLoading(true);
      const resp = await apiClient.get<{ data: Report[] }>('/admin/reports');
      setReports(resp.data.data ?? []);
    } catch {
      toast.error('Failed to fetch reports');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchReports(); }, [fetchReports]);

  const handleAction = async (note: string) => {
    if (!activeAction) return;
    const { reportId, type } = activeAction;
    setActiveAction(null);
    setProcessingId(reportId);
    try {
      await apiClient.put(`/admin/reports/${reportId}/${type}?note=${encodeURIComponent(note)}`);
      toast.success(`Report #${reportId} ${type === 'resolve' ? 'resolved' : 'dismissed'}.`);
      // Optimistic update — avoid full refetch for better UX
      setReports(prev =>
        prev.map(r =>
          r.id === reportId
            ? { ...r, status: type === 'resolve' ? 'RESOLVED' : 'DISMISSED', resolutionNote: note }
            : r
        )
      );
    } catch {
      toast.error(`Failed to ${type} report`);
    } finally {
      setProcessingId(null);
    }
  };

  const displayed = filter === 'ALL' ? reports : reports.filter(r => r.status === filter);

  const counts = {
    ALL:       reports.length,
    PENDING:   reports.filter(r => r.status === 'PENDING').length,
    RESOLVED:  reports.filter(r => r.status === 'RESOLVED').length,
    DISMISSED: reports.filter(r => r.status === 'DISMISSED').length,
  };

  const FILTERS: Array<{ key: typeof filter; label: string }> = [
    { key: 'ALL',       label: `All (${counts.ALL})` },
    { key: 'PENDING',   label: `Pending (${counts.PENDING})` },
    { key: 'RESOLVED',  label: `Resolved (${counts.RESOLVED})` },
    { key: 'DISMISSED', label: `Dismissed (${counts.DISMISSED})` },
  ];

  return (
    <>
      {activeAction && (
        <ActionDialog
          reportId={activeAction.reportId}
          action={activeAction.type}
          onConfirm={handleAction}
          onCancel={() => setActiveAction(null)}
        />
      )}

      <div className="animate-in fade-in duration-500 space-y-6">

        {/* Header */}
        <div className="flex items-start justify-between gap-4 flex-wrap">
          <div>
            <h1 className="text-3xl font-display font-bold text-slate-900 dark:text-white">Content Moderation</h1>
            <p className="text-slate-500 dark:text-slate-400 mt-1 text-sm font-medium">
              Manage flagged content, toxic behaviour, and platform reports.
            </p>
          </div>
          <button
            onClick={fetchReports}
            disabled={loading}
            className="flex items-center gap-2 px-4 py-2 text-xs font-bold rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 disabled:opacity-50 transition-all"
          >
            <RefreshCw size={13} className={loading ? 'animate-spin' : ''} />
            Refresh
          </button>
        </div>

        {/* Filter Tabs */}
        <div className="flex gap-2 flex-wrap">
          {FILTERS.map(({ key, label }) => (
            <button
              key={key}
              onClick={() => setFilter(key)}
              className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-all ${
                filter === key
                  ? 'bg-indigo-600 text-white shadow-sm'
                  : 'bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800'
              }`}
            >
              {label}
            </button>
          ))}
        </div>

        {/* Table */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="border-b border-slate-100 dark:border-slate-800">
                <tr className="text-left">
                  <th className="px-5 py-3.5 text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Type</th>
                  <th className="px-5 py-3.5 text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Reason</th>
                  <th className="px-5 py-3.5 text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Status</th>
                  <th className="px-5 py-3.5 text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                {loading ? (
                  <tr>
                    <td colSpan={4} className="text-center py-12 text-slate-400 dark:text-slate-500 text-sm">
                      Loading reports…
                    </td>
                  </tr>
                ) : displayed.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="text-center py-12 text-slate-400 dark:text-slate-500 text-sm">
                      {filter === 'ALL' ? 'No reports yet. All clear! ✅' : `No ${filter.toLowerCase()} reports.`}
                    </td>
                  </tr>
                ) : (
                  displayed.map(report => (
                    <tr
                      key={report.id}
                      className="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors"
                    >
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-2">
                          <Flag size={15} className={TYPE_COLORS[report.type] ?? 'text-slate-400'} />
                          <span className="font-semibold text-slate-900 dark:text-slate-100">{report.type}</span>
                          <span className="text-xs text-slate-400 dark:text-slate-500">#{report.targetId}</span>
                        </div>
                      </td>
                      <td className="px-5 py-4 text-slate-600 dark:text-slate-400 max-w-xs truncate" title={report.reason}>
                        {report.reason}
                      </td>
                      <td className="px-5 py-4">
                        <span className={`inline-flex px-2.5 py-1 rounded-md text-[10px] uppercase font-bold tracking-widest ${STATUS_STYLES[report.status]}`}>
                          {report.status}
                        </span>
                        {report.resolutionNote && (
                          <p className="text-xs text-slate-400 dark:text-slate-500 mt-1 truncate max-w-[180px]" title={report.resolutionNote}>
                            {report.resolutionNote}
                          </p>
                        )}
                      </td>
                      <td className="px-5 py-4 text-right">
                        {report.status === 'PENDING' && (
                          <div className="flex items-center justify-end gap-2">
                            <button
                              onClick={() => setActiveAction({ reportId: report.id, type: 'resolve' })}
                              disabled={processingId === report.id}
                              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold uppercase tracking-wide text-emerald-700 bg-emerald-50 border border-emerald-200 hover:bg-emerald-100 dark:text-emerald-400 dark:bg-emerald-500/10 dark:border-emerald-500/30 dark:hover:bg-emerald-500/20 disabled:opacity-50 transition-all"
                            >
                              <CheckCircle size={13} />
                              {processingId === report.id ? '…' : 'Resolve'}
                            </button>
                            <button
                              onClick={() => setActiveAction({ reportId: report.id, type: 'dismiss' })}
                              disabled={processingId === report.id}
                              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold uppercase tracking-wide text-slate-600 bg-slate-100 border border-slate-200 hover:bg-slate-200 dark:text-slate-400 dark:bg-slate-700/40 dark:border-slate-600 dark:hover:bg-slate-700 disabled:opacity-50 transition-all"
                            >
                              <XCircle size={13} />
                              {processingId === report.id ? '…' : 'Dismiss'}
                            </button>
                          </div>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </>
  );
};
