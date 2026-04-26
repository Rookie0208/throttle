import { useEffect, useState } from 'react';
import apiClient from '../services/apiClient';
import { Flag, CheckCircle } from 'lucide-react';
import toast from 'react-hot-toast';

interface Report {
  id: number;
  reporterId: number;
  targetId: number;
  type: string;
  reason: string;
  status: string;
  createdAt: string;
  resolutionNote?: string;
}

export const Reports = () => {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [resolvingId, setResolvingId] = useState<number | null>(null);

  const fetchReports = async () => {
    try {
      const resp = await apiClient.get('/admin/reports');
      setReports(resp.data.data || []);
    } catch (err) {
      toast.error("Failed to fetch reports");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReports();
  }, []);

  const handleResolve = async (id: number) => {
    const note = prompt("Enter resolution notes for this report:");
    if (note === null) return;

    setResolvingId(id);
    try {
      await apiClient.put(`/admin/reports/${id}/resolve?note=${encodeURIComponent(note)}`);
      toast.success("Report successfully resolved.");
      fetchReports();
    } catch (err) {
      toast.error("Failed to resolve report");
    } finally {
      setResolvingId(null);
    }
  };

  return (
    <div className="animate-in fade-in duration-500">
      <div className="mb-8 flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-display font-bold text-slate-900 dark:text-white">Content Moderation</h1>
          <p className="text-slate-600 dark:text-slate-400 mt-1 font-medium">Manage flagged content, toxic behavior, and platform reports.</p>
        </div>
      </div>

      <div className="glass-panel overflow-hidden border-x-0 border-b-0 md:border md:rounded-2xl shadow-sm">
        <div className="overflow-x-auto">
          <table className="glass-table min-w-max">
            <thead>
              <tr>
                <th>Type</th>
                <th>Reason</th>
                <th>Status</th>
                <th className="text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={4} className="text-center py-10 font-semibold text-slate-500 dark:text-slate-400">Loading reports...</td></tr>
              ) : reports.length === 0 ? (
                <tr><td colSpan={4} className="text-center py-10 font-semibold text-slate-500 dark:text-slate-400">No active reports. All clear!</td></tr>
              ) : (
                reports.map(report => (
                  <tr key={report.id}>
                    <td>
                      <div className="flex items-center space-x-2">
                        <Flag size={16} className={report.type === 'USER' ? 'text-indigo-600 dark:text-indigo-400' : 'text-purple-600 dark:text-purple-400'} />
                        <span className="font-semibold text-slate-900 dark:text-slate-200">{report.type}</span>
                        <span className="text-xs text-slate-500 dark:text-slate-500">#{report.targetId}</span>
                      </div>
                    </td>
                    <td className="text-slate-600 dark:text-slate-400 max-w-md truncate" title={report.reason}>{report.reason}</td>
                    <td>
                       <span className={`px-2.5 py-1 rounded-md text-[10px] uppercase font-bold tracking-widest ${
                          report.status === 'PENDING' ? 'bg-amber-100 text-amber-700 dark:bg-amber-500/10 dark:text-amber-400 border border-amber-200 dark:border-amber-500/30' : 
                          'bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-500/30'
                        }`}>
                          {report.status}
                       </span>
                       {report.resolutionNote && (
                         <div className="text-xs text-slate-500 dark:text-slate-500 mt-1 truncate max-w-[150px]" title={report.resolutionNote}>
                           Note: {report.resolutionNote}
                         </div>
                       )}
                    </td>
                    <td className="text-right">
                      {report.status === 'PENDING' && (
                        <button
                          onClick={() => handleResolve(report.id)}
                          disabled={resolvingId === report.id}
                          className="inline-flex items-center space-x-2 px-3 py-1.5 rounded-md text-xs font-bold uppercase tracking-wide transition-all text-emerald-700 hover:bg-emerald-100 bg-emerald-50 border border-emerald-200 dark:text-emerald-400 dark:hover:bg-emerald-500/20 dark:bg-emerald-500/10 dark:border-emerald-500/30 disabled:opacity-50"
                        >
                          <CheckCircle size={14} /> <span>{resolvingId === report.id ? 'PROCESSING...' : 'RESOLVE'}</span>
                        </button>
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
  );
};
