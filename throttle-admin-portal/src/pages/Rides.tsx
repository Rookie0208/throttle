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
          <h1 className="text-3xl font-bold text-gray-900">Ride Management</h1>
          <p className="text-gray-500 mt-2">Monitor active and scheduled rides.</p>
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-max">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-100 text-sm text-gray-500 uppercase tracking-wider">
                <th className="p-4 font-medium">Title</th>
                <th className="p-4 font-medium">Type</th>
                <th className="p-4 font-medium">Status</th>
                <th className="p-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
            {loading ? (
              <tr><td colSpan={4} className="text-center p-8 text-gray-400">Loading rides...</td></tr>
            ) : rides.length === 0 ? (
              <tr><td colSpan={4} className="text-center p-8 text-gray-400">No rides found.</td></tr>
            ) : (
              rides.map(ride => (
                <tr key={ride.id} className="hover:bg-gray-50 transition-colors">
                  <td className="p-4 font-medium text-gray-900">{ride.title}</td>
                  <td className="p-4 text-gray-500">{ride.rideType}</td>
                  <td className="p-4">
                     <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                        ride.status === 'UPCOMING' ? 'bg-amber-50 text-amber-700' : 
                        ride.status === 'COMPLETED' ? 'bg-emerald-50 text-emerald-700' :
                        'bg-red-50 text-red-700'
                      }`}>
                        {ride.status}
                     </span>
                  </td>
                  <td className="p-4 text-right">
                    {ride.status !== 'CANCELLED' && (
                      <button
                        onClick={() => handleCancel(ride.id)}
                        className="inline-flex items-center space-x-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors text-red-600 bg-red-50 hover:bg-red-100"
                      >
                        <XCircle size={16} /> <span>Force Cancel</span>
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
