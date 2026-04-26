import { useEffect, useState } from 'react';
import apiClient from '../services/apiClient';
import { XCircle } from 'lucide-react';

interface Ride {
  id: number;
  title: string;
  status: string;
  rideType: string;
  createdBy: number;
  startTime: string;
}

export const Rides = () => {
  const [rides, setRides] = useState<Ride[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchRides = async () => {
    try {
      const resp = await apiClient.get('/admin/rides');
      setRides(resp.data.data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRides();
  }, []);

  const handleCancel = async (id: number) => {
    if (confirm("Are you sure you want to cancel this ride?")) {
      try {
        await apiClient.put(`/admin/rides/${id}/cancel`);
        fetchRides(); // refresh
      } catch (err) {
        console.error("Failed to cancel ride", err);
      }
    }
  };

  return (
    <div className="animate-in fade-in duration-500">
      <div className="mb-8 flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-display font-bold text-slate-900 dark:text-white">Ride Management</h1>
          <p className="text-slate-600 dark:text-slate-400 mt-1 font-medium">Monitor active and scheduled rides.</p>
        </div>
      </div>

      <div className="glass-panel overflow-hidden border-x-0 border-b-0 md:border md:rounded-2xl shadow-sm">
        <div className="overflow-x-auto">
          <table className="glass-table min-w-max">
            <thead>
              <tr>
                <th>Title</th>
                <th>Type</th>
                <th>Status</th>
                <th className="text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
            {loading ? (
              <tr><td colSpan={4} className="text-center py-10 font-semibold text-slate-500 dark:text-slate-400">Loading rides...</td></tr>
            ) : rides.length === 0 ? (
              <tr><td colSpan={4} className="text-center py-10 font-semibold text-slate-500 dark:text-slate-400">No rides found.</td></tr>
            ) : (
              rides.map(ride => (
                <tr key={ride.id}>
                  <td className="font-semibold text-slate-900 dark:text-slate-200">{ride.title}</td>
                  <td className="text-slate-600 dark:text-slate-400">{ride.rideType}</td>
                  <td>
                     <span className={`px-2.5 py-1 rounded-md text-[10px] uppercase font-bold tracking-widest ${
                        ride.status === 'UPCOMING' ? 'bg-amber-100 text-amber-700 dark:bg-amber-500/10 dark:text-amber-400 border border-amber-200 dark:border-amber-500/30' : 
                        ride.status === 'COMPLETED' ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-500/30' :
                        'bg-rose-100 text-rose-700 dark:bg-rose-500/10 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30'
                      }`}>
                        {ride.status}
                     </span>
                  </td>
                  <td className="text-right">
                    {ride.status !== 'CANCELLED' && (
                      <button
                        onClick={() => handleCancel(ride.id)}
                        className="inline-flex items-center space-x-2 px-3 py-1.5 rounded-md text-xs font-bold uppercase tracking-wide transition-all text-rose-700 hover:bg-rose-100 bg-rose-50 border border-rose-200 dark:text-rose-400 dark:hover:bg-rose-500/20 dark:bg-rose-500/10 dark:border-rose-500/30"
                      >
                        <XCircle size={14} /> <span>Cancel</span>
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
