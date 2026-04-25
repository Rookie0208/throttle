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
          <h1 className="text-3xl font-bold text-gray-900 flex items-center space-x-3">
            <History className="w-8 h-8 text-blue-600" />
            <span>Audit Logs</span>
          </h1>
          <p className="text-gray-500 mt-2">Monitor all administrative actions performed across the platform.</p>
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-max">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-100 text-sm text-gray-500 uppercase tracking-wider">
                <th className="p-4 font-medium">Log ID</th>
                <th className="p-4 font-medium">Action</th>
                <th className="p-4 font-medium">Admin ID</th>
                <th className="p-4 font-medium">Target ID</th>
                <th className="p-4 font-medium">Timestamp</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
            {loading ? (
              <tr><td colSpan={5} className="text-center p-8 text-gray-400">Loading audit events...</td></tr>
            ) : logs.length === 0 ? (
              <tr>
                <td colSpan={5} className="text-center p-12">
                  <ShieldCheck className="mx-auto w-12 h-12 text-gray-300 mb-4" />
                  <p className="text-gray-400">No audit logs found. The system is quiet.</p>
                </td>
              </tr>
            ) : (
              logs.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()).map(log => (
                <tr key={log.esDocId || log.id} className="hover:bg-gray-50 transition-colors">
                  <td className="p-4 font-mono text-xs text-gray-500" title={log.esDocId}>
                    {log.esDocId ? log.esDocId.substring(0, 8) + '…' : `#${log.id}`}
                  </td>
                  <td className="p-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                      log.action.includes('BLOCK') ? 'bg-red-50 text-red-700' : 
                      log.action.includes('RESOLVE') ? 'bg-emerald-50 text-emerald-700' : 
                      'bg-indigo-50 text-indigo-700'
                    }`}>
                      {log.action}
                    </span>
                  </td>
                  <td className="p-4 font-medium text-gray-900">Admin #{log.adminId}</td>
                  <td className="p-4 text-gray-500">Target #{log.targetId}</td>
                  <td className="p-4 text-gray-400 text-sm">
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
