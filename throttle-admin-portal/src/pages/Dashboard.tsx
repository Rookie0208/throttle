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
    { name: 'Total Users', value: statsData?.totalUsers ?? '...', icon: Users, color: 'text-cyan-400', bg: 'bg-cyan-500/20 block border border-cyan-500/30 shadow-[0_0_15px_rgba(34,211,238,0.3)]' },
    { name: 'Active Riders', value: statsData?.activeUsers ?? '...', icon: Activity, color: 'text-emerald-400', bg: 'bg-emerald-500/20 block border border-emerald-500/30 shadow-[0_0_15px_rgba(52,211,153,0.3)]' },
    { name: 'Total Rides', value: statsData?.totalRides ?? '...', icon: Bike, color: 'text-indigo-400', bg: 'bg-indigo-500/20 block border border-indigo-500/30 shadow-[0_0_15px_rgba(99,102,241,0.3)]' },
    { name: 'Pending Reports', value: statsData?.pendingReports ?? '...', icon: ShieldAlert, color: 'text-rose-400', bg: 'bg-rose-500/20 block border border-rose-500/30 shadow-[0_0_15px_rgba(244,63,94,0.3)]' },
  ];

  return (
    <div className="animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="mb-8">
        <h1 className="text-3xl font-display font-bold text-slate-900 dark:text-white">Dashboard</h1>
        <p className="text-slate-600 dark:text-slate-400 mt-1 font-medium">Platform observability and key metrics.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <div key={stat.name} className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 p-6 rounded-2xl shadow-sm transition-all duration-200 group">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-semibold text-slate-500 dark:text-slate-400 mb-1">{stat.name}</p>
                  <h3 className="text-3xl font-bold text-slate-900 dark:text-white">{stat.value}</h3>
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
      <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl overflow-hidden shadow-sm">
        <div className="p-6 border-b border-slate-200 dark:border-slate-800 flex justify-between items-center bg-slate-50 dark:bg-slate-900/50">
          <div>
            <h2 className="text-lg font-bold text-slate-900 dark:text-white">System Telemetry Feed</h2>
            <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">Live Spring Boot Actuator Stream</p>
          </div>
          <div className="flex items-center space-x-2 bg-white dark:bg-slate-950 px-4 py-2 rounded-lg border border-slate-200 dark:border-slate-800 shadow-sm">
            <span className="font-semibold text-xs tracking-wide text-slate-600 dark:text-slate-400 uppercase">Status:</span>
            <span className={`px-3 py-1 rounded-md text-xs font-bold ${
              healthStatus === 'UP' ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-500/30' : 'bg-rose-100 text-rose-700 dark:bg-rose-500/10 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30'
            }`}>
              {healthStatus}
            </span>
          </div>
        </div>
        <div className="h-[240px] w-full bg-slate-900 dark:bg-slate-950 flex flex-col items-center justify-center p-6 text-emerald-500 dark:text-emerald-400 font-mono text-sm relative">
           <Cpu size={32} className="mb-4 opacity-70" />
           <p className="mb-2">&gt;&gt; GRAFANA / PROMETHEUS METRICS AGGREGATING</p>
           <p className="opacity-70">&gt;&gt; UPLINK CONNECTED: http://localhost:8080/actuator</p>
           <p className="opacity-50 mt-6 animate-pulse text-xs uppercase">Awaiting Sub-Routine Scrape Sequence...</p>
        </div>
      </div>
    </div>
  );
};
