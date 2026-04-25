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
          <h1 className="text-3xl font-bold text-gray-900">Content Moderation</h1>
          <p className="text-gray-500 mt-2">Manage flagged content, toxic behavior, and platform reports.</p>
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-max">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-100 text-sm text-gray-500 uppercase tracking-wider">
                <th className="p-4 font-medium">Type</th>
                <th className="p-4 font-medium">Reason</th>
                <th className="p-4 font-medium">Status</th>
                <th className="p-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {loading ? (
                <tr><td colSpan={4} className="text-center p-8 text-gray-400">Loading reports...</td></tr>
              ) : reports.length === 0 ? (
                <tr><td colSpan={4} className="text-center p-8 text-gray-400">No active reports. Good job!</td></tr>
              ) : (
                reports.map(report => (
                  <tr key={report.id} className="hover:bg-gray-50 transition-colors">
                    <td className="p-4">
                      <div className="flex items-center space-x-2">
                        <Flag size={16} className={report.type === 'USER' ? 'text-blue-500' : 'text-purple-500'} />
                        <span className="font-semibold text-gray-900">{report.type}</span>
                        <span className="text-xs text-gray-400">#{report.targetId}</span>
                      </div>
                    </td>
                    <td className="p-4 text-gray-600 max-w-md truncate" title={report.reason}>{report.reason}</td>
                    <td className="p-4">
                       <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                          report.status === 'PENDING' ? 'bg-amber-50 text-amber-700' : 
                          'bg-emerald-50 text-emerald-700'
                        }`}>
                          {report.status}
                       </span>
                       {report.resolutionNote && (
                         <div className="text-xs text-gray-400 mt-1 truncate max-w-[150px]" title={report.resolutionNote}>
                           Note: {report.resolutionNote}
                         </div>
                       )}
                    </td>
                    <td className="p-4 text-right">
                      {report.status === 'PENDING' && (
                        <button
                          onClick={() => handleResolve(report.id)}
                          disabled={resolvingId === report.id}
                          className="inline-flex items-center space-x-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors text-emerald-600 bg-emerald-50 hover:bg-emerald-100 disabled:opacity-50"
                        >
                          <CheckCircle size={16} /> <span>{resolvingId === report.id ? 'Resolving...' : 'Resolve'}</span>
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
