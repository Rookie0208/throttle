import { useEffect, useState } from 'react';
import { Users, Bike, Activity, ShieldAlert, Cpu } from 'lucide-react';
import apiClient from '../services/apiClient';

interface AdminStats {
  totalUsers: number;
  activeUsers: number;
  totalRides: number;
  pendingReports: number;
}

export const Dashboard = () => {
  const [statsData, setStatsData] = useState<AdminStats | null>(null);
  const [healthStatus, setHealthStatus] = useState<string>('LOADING...');

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const resp = await apiClient.get('/admin/stats');
        setStatsData(resp.data.data);
      } catch (err) {
        console.error("Failed to fetch dashboard stats", err);
      }
    };
    
    const fetchHealth = async () => {
      try {
        const res = await fetch('http://localhost:8080/actuator/health');
        const json = await res.json();
        setHealthStatus(json.status);
      } catch (e) {
        setHealthStatus('DOWN (OFFLINE)');
      }
    };

    fetchStats();
    fetchHealth();
    // Poll system health every 10 seconds
    const interval = setInterval(fetchHealth, 10000);
    return () => clearInterval(interval);
  }, []);

  const stats = [
    { name: 'Total Users', value: statsData?.totalUsers ?? '...', icon: Users, color: 'text-blue-600', bg: 'bg-blue-100' },
    { name: 'Active Riders', value: statsData?.activeUsers ?? '...', icon: Activity, color: 'text-emerald-600', bg: 'bg-emerald-100' },
    { name: 'Total Rides', value: statsData?.totalRides ?? '...', icon: Bike, color: 'text-indigo-600', bg: 'bg-indigo-100' },
    { name: 'Pending Reports', value: statsData?.pendingReports ?? '...', icon: ShieldAlert, color: 'text-amber-600', bg: 'bg-amber-100' },
  ];

  return (
    <div className="animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-500 mt-2">Platform observability and key metrics.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <div key={stat.name} className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-500 mb-1">{stat.name}</p>
                  <h3 className="text-3xl font-bold text-gray-900">{stat.value}</h3>
                </div>
                <div className={`p-4 rounded-full ${stat.bg} ${stat.color}`}>
                  <Icon size={24} />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* System Observability Feed */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden relative">
        <div className="p-6 border-b border-gray-100 flex justify-between items-center">
          <div>
            <h2 className="text-xl font-bold text-gray-900">System Observability</h2>
            <p className="text-sm text-gray-500">Live Spring Boot Actuator Feed</p>
          </div>
          <div className="flex items-center space-x-2">
            <span className="font-semibold text-sm mr-2 text-gray-600">Core Engine:</span>
            <span className={`px-3 py-1 rounded-full text-xs font-bold ${
              healthStatus === 'UP' ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700'
            }`}>
              {healthStatus}
            </span>
          </div>
        </div>
        <div className="h-[200px] w-full bg-slate-900 flex flex-col items-center justify-center p-6 shadow-inner text-emerald-400 font-mono text-sm">
           <Cpu size={32} className="mb-4 opacity-70" />
           <p className="mb-2">&gt;&gt; GRAFANA / PROMETHEUS METRICS AGGREGATING</p>
           <p className="opacity-70">&gt;&gt; STREAM CONNECTED TO: http://localhost:8080/actuator</p>
           <p className="opacity-50 mt-4 animate-pulse">Waiting for Prometheus scrape cycle...</p>
        </div>
      </div>
    </div>
  );
};
