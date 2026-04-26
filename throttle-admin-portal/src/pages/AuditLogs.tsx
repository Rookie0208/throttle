import { useEffect, useState } from 'react';
import apiClient from '../services/apiClient';
import { ShieldCheck, History } from 'lucide-react';

interface AuditLog {
  id: number | null;
  esDocId: string;
  action: string;
  adminId: number;
  targetId: number;
  timestamp: string;
}

export const AuditLogs = () => {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchLogs = async () => {
    try {
      const resp = await apiClient.get('/admin/audit-logs');
      setLogs(resp.data.data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, []);

  return (
    <div className="animate-in fade-in duration-500">
      <div className="mb-8 flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-display font-bold text-slate-900 dark:text-white flex items-center space-x-3">
            <History className="w-8 h-8 text-indigo-600 dark:text-indigo-400" />
            <span>Audit Logs</span>
          </h1>
          <p className="text-slate-600 dark:text-slate-400 mt-1 font-medium">Monitor all administrative actions performed across the platform.</p>
        </div>
      </div>

      <div className="glass-panel overflow-hidden border-x-0 border-b-0 md:border md:rounded-2xl shadow-sm">
        <div className="overflow-x-auto">
          <table className="glass-table min-w-max">
            <thead>
              <tr>
                <th>Log ID</th>
                <th>Action</th>
                <th>Admin ID</th>
                <th>Target ID</th>
                <th>Timestamp</th>
              </tr>
            </thead>
            <tbody>
            {loading ? (
              <tr><td colSpan={5} className="text-center py-10 font-semibold text-slate-500 dark:text-slate-400">Loading audit events...</td></tr>
            ) : logs.length === 0 ? (
              <tr>
                <td colSpan={5} className="text-center p-12">
                  <ShieldCheck className="mx-auto w-12 h-12 text-slate-400 dark:text-slate-600 mb-4" />
                  <p className="text-slate-500 dark:text-slate-400 font-medium">No audit logs found. The system is quiet.</p>
                </td>
              </tr>
            ) : (
              logs.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()).map(log => (
                <tr key={log.esDocId || log.id}>
                  <td className="font-mono text-xs text-indigo-600 dark:text-indigo-400 font-semibold" title={log.esDocId}>
                    {log.esDocId ? log.esDocId.substring(0, 8) + '…' : `#${log.id}`}
                  </td>
                  <td>
                    <span className={`px-2 py-1 rounded-md text-[10px] uppercase font-bold tracking-widest ${
                      log.action.includes('BLOCK') ? 'bg-rose-100 text-rose-700 dark:bg-rose-500/10 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30' : 
                      log.action.includes('RESOLVE') ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-500/30' : 
                      'bg-indigo-100 text-indigo-700 dark:bg-indigo-500/10 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-500/30'
                    }`}>
                      {log.action}
                    </span>
                  </td>
                  <td className="font-semibold text-slate-900 dark:text-slate-200">Admin #{log.adminId}</td>
                  <td className="text-slate-600 dark:text-slate-400">Target #{log.targetId}</td>
                  <td className="text-slate-500 dark:text-slate-500 text-sm font-mono">
                    {new Date(log.timestamp).toLocaleString()}
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
