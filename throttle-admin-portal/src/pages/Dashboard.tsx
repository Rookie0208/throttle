/**
 * Dashboard.tsx
 *
 * Primary observability view for the Throttle Admin Portal.
 *
 * Data sources:
 *   1. GET /admin/stats/analytics  → platform metrics + categorical breakdowns
 *   2. GET /admin/stats/growth     → 14-day user & ride time-series
 *   3. Prometheus query_range      → live JVM memory + CPU (via usePrometheusMetric)
 */

import { useEffect, useState, useCallback } from 'react';
import {
  Users, Bike, Activity, ShieldAlert,
  UserX, CheckCircle, Flag,
} from 'lucide-react';
import apiClient from '../services/apiClient';
import { usePrometheusMetric } from '../hooks/usePrometheusMetric';
import { AreaMetricChart } from '../components/charts/AreaMetricChart';
import { BarGrowthChart, type GrowthPoint } from '../components/charts/BarGrowthChart';
import { DonutChart, type DonutSlice } from '../components/charts/DonutChart';

// ─── Types ────────────────────────────────────────────────────────────────────

interface BreakdownPoint {
  label: string;
  count: number;
}

interface Analytics {
  totalUsers: number;
  activeUsers: number;
  blockedUsers: number;
  totalRides: number;
  completedRides: number;
  activeRides: number;
  ridesByStatus: BreakdownPoint[];
  ridesByType: BreakdownPoint[];
  totalReports: number;
  pendingReports: number;
  resolvedReports: number;
  reportsByStatus: BreakdownPoint[];
  reportsByType: BreakdownPoint[];
}

interface GrowthStats {
  userGrowth: GrowthPoint[];
  rideGrowth: GrowthPoint[];
}

// ─── Sub-components ───────────────────────────────────────────────────────────

interface StatCardProps {
  name: string;
  value: number | string;
  icon: React.ElementType;
  color: string;
  bg: string;
  sub?: string;
}

function StatCard({ name, value, icon: Icon, color, bg, sub }: StatCardProps) {
  return (
    <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 p-5 rounded-2xl shadow-sm transition-all duration-200 hover:shadow-md hover:-translate-y-0.5">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-xs font-semibold text-slate-500 dark:text-slate-400 mb-1 uppercase tracking-wide">{name}</p>
          <h3 className="text-3xl font-bold text-slate-900 dark:text-white">{value}</h3>
          {sub && <p className="text-xs text-slate-400 dark:text-slate-500 mt-1">{sub}</p>}
        </div>
        <div className={`p-3.5 rounded-full ${bg} ${color}`}>
          <Icon size={22} />
        </div>
      </div>
    </div>
  );
}

interface ChartCardProps {
  title: string;
  subtitle: string;
  badge?: React.ReactNode;
  children: React.ReactNode;
}

function ChartCard({ title, subtitle, badge, children }: ChartCardProps) {
  return (
    <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-sm overflow-hidden">
      <div className="px-6 pt-5 pb-3 flex items-start justify-between border-b border-slate-100 dark:border-slate-800">
        <div>
          <h2 className="text-sm font-bold text-slate-900 dark:text-white">{title}</h2>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">{subtitle}</p>
        </div>
        {badge}
      </div>
      <div className="px-4 py-4">{children}</div>
    </div>
  );
}

function LiveBadge() {
  return (
    <span className="flex items-center gap-1.5 text-xs font-semibold text-emerald-600 dark:text-emerald-400">
      <span className="relative flex h-2 w-2">
        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
        <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500" />
      </span>
      LIVE
    </span>
  );
}

// ─── Main Component ───────────────────────────────────────────────────────────

export const Dashboard = () => {
  const [analytics, setAnalytics] = useState<Analytics | null>(null);
  const [analyticsLoading, setAnalyticsLoading] = useState(true);
  const [growthData, setGrowthData] = useState<GrowthStats | null>(null);
  const [growthLoading, setGrowthLoading] = useState(true);
  const [healthStatus, setHealthStatus] = useState<string>('CHECKING…');

  // Prometheus live metrics — 30-min window, 60 s resolution, auto-refresh 30 s
  const jvmMemory = usePrometheusMetric({ query: 'jvm_memory_used_bytes{area="heap"}', minutes: 30, step: 60, refreshIntervalMs: 30_000 });
  const cpuUsage  = usePrometheusMetric({ query: 'system_cpu_usage',                  minutes: 30, step: 60, refreshIntervalMs: 30_000 });

  const fetchAnalytics = useCallback(async () => {
    try {
      setAnalyticsLoading(true);
      const resp = await apiClient.get<{ data: Analytics }>('/admin/stats/analytics');
      setAnalytics(resp.data.data);
    } catch (err) {
      console.error('[Dashboard] Failed to fetch analytics', err);
    } finally {
      setAnalyticsLoading(false);
    }
  }, []);

  const fetchGrowth = useCallback(async () => {
    try {
      setGrowthLoading(true);
      const resp = await apiClient.get<{ data: GrowthStats }>('/admin/stats/growth?days=14');
      setGrowthData(resp.data.data);
    } catch (err) {
      console.error('[Dashboard] Failed to fetch growth data', err);
    } finally {
      setGrowthLoading(false);
    }
  }, []);

  const fetchHealth = useCallback(async () => {
    try {
      const res = await fetch('http://localhost:8080/actuator/health', {
        signal: AbortSignal.timeout(4000),
      });
      const json = await res.json();
      setHealthStatus(json.status ?? 'UNKNOWN');
    } catch {
      setHealthStatus('DOWN');
    }
  }, []);

  useEffect(() => {
    fetchAnalytics();
    fetchGrowth();
    fetchHealth();
    const healthInterval = setInterval(fetchHealth, 15_000);
    return () => clearInterval(healthInterval);
  }, [fetchAnalytics, fetchGrowth, fetchHealth]);

  const isUp = healthStatus === 'UP';
  const a = analytics;

  // ── Stat Card Rows ──────────────────────────────────────────────────────────
  const primaryStats: StatCardProps[] = [
    { name: 'Total Users',     value: a?.totalUsers     ?? '…', icon: Users,       color: 'text-cyan-400',    bg: 'bg-cyan-500/20 border border-cyan-500/30' },
    { name: 'Active Riders',   value: a?.activeUsers    ?? '…', icon: Activity,    color: 'text-emerald-400', bg: 'bg-emerald-500/20 border border-emerald-500/30' },
    { name: 'Total Rides',     value: a?.totalRides     ?? '…', icon: Bike,        color: 'text-indigo-400',  bg: 'bg-indigo-500/20 border border-indigo-500/30' },
    { name: 'Pending Reports', value: a?.pendingReports ?? '…', icon: ShieldAlert, color: 'text-rose-400',    bg: 'bg-rose-500/20 border border-rose-500/30' },
  ] satisfies StatCardProps[];

  const secondaryStats: StatCardProps[] = [
    { name: 'Blocked Users',   value: a?.blockedUsers   ?? '…', icon: UserX,       color: 'text-orange-400', bg: 'bg-orange-500/20 border border-orange-500/30', sub: `of ${a?.totalUsers ?? '…'} total` },
    { name: 'Active Rides',    value: a?.activeRides    ?? '…', icon: Activity,    color: 'text-sky-400',    bg: 'bg-sky-500/20 border border-sky-500/30',       sub: 'currently in progress' },
    { name: 'Completed Rides', value: a?.completedRides ?? '…', icon: CheckCircle, color: 'text-teal-400',   bg: 'bg-teal-500/20 border border-teal-500/30',     sub: `of ${a?.totalRides ?? '…'} total` },
    { name: 'Total Reports',   value: a?.totalReports   ?? '…', icon: Flag,        color: 'text-violet-400', bg: 'bg-violet-500/20 border border-violet-500/30', sub: `${a?.resolvedReports ?? '…'} resolved` },
  ] satisfies StatCardProps[];

  // ── Donut Data ──────────────────────────────────────────────────────────────
  const toSlices = (arr: BreakdownPoint[]): DonutSlice[] =>
    arr.map(b => ({ label: b.label, count: b.count }));

  const rideStatusSlices   = toSlices(a?.ridesByStatus   ?? []);
  const rideTypeSlices     = toSlices(a?.ridesByType     ?? []);
  const reportStatusSlices = toSlices(a?.reportsByStatus ?? []);
  const reportTypeSlices   = toSlices(a?.reportsByType   ?? []);

  const rideTypeColors     = ['#6366f1', '#10b981'];
  const reportStatusColors = ['#f59e0b', '#10b981', '#94a3b8'];
  const reportTypeColors   = ['#ef4444', '#6366f1', '#3b82f6'];

  return (
    <div className="animate-in fade-in slide-in-from-bottom-4 duration-500 space-y-8">

      {/* ── Header ── */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-3xl font-display font-bold text-slate-900 dark:text-white">Dashboard</h1>
          <p className="text-slate-500 dark:text-slate-400 mt-1 font-medium text-sm">
            Platform observability, growth trends, and live system telemetry.
          </p>
        </div>
        <div className="flex items-center gap-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 px-4 py-2 rounded-xl shadow-sm text-xs">
          <span className="font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wide">API Status</span>
          <span className={`px-2.5 py-1 rounded-md font-bold ${isUp
            ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-500/30'
            : 'bg-rose-100 text-rose-700 dark:bg-rose-500/10 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30'
          }`}>
            {healthStatus}
          </span>
        </div>
      </div>

      {/* ── Primary Stat Cards ── */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {primaryStats.map((s) => <StatCard key={s.name} {...s} />)}
      </div>

      {/* ── Secondary Stat Cards ── */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {secondaryStats.map((s) => <StatCard key={s.name} {...s} />)}
      </div>

      {/* ── Platform Growth ── */}
      <ChartCard title="Platform Growth" subtitle="Daily new users & rides — last 14 days">
        <BarGrowthChart
          userGrowth={growthData?.userGrowth ?? []}
          rideGrowth={growthData?.rideGrowth ?? []}
          loading={growthLoading}
          height={220}
        />
      </ChartCard>

      {/* ── Ride Analytics ── */}
      <div>
        <h2 className="text-lg font-display font-bold text-slate-900 dark:text-white mb-4">Ride Analytics</h2>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          <ChartCard title="Ride Status Breakdown" subtitle="Distribution of rides by current status">
            <DonutChart data={rideStatusSlices} loading={analyticsLoading} height={220} />
          </ChartCard>
          <ChartCard title="Ride Type Distribution" subtitle="Solo rides vs Group rides">
            <DonutChart data={rideTypeSlices} loading={analyticsLoading} colors={rideTypeColors} height={220} />
          </ChartCard>
        </div>
      </div>

      {/* ── Report Analytics ── */}
      <div>
        <h2 className="text-lg font-display font-bold text-slate-900 dark:text-white mb-4">Report Analytics</h2>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          <ChartCard title="Report Status" subtitle="Pending, Resolved, and Dismissed reports">
            <DonutChart data={reportStatusSlices} loading={analyticsLoading} colors={reportStatusColors} height={220} />
          </ChartCard>
          <ChartCard title="Report Types" subtitle="Reports by category: User, Ride, System">
            <DonutChart data={reportTypeSlices} loading={analyticsLoading} colors={reportTypeColors} height={220} />
          </ChartCard>
        </div>
      </div>

      {/* ── Live System Telemetry ── */}
      <div>
        <div className="flex items-center gap-2 mb-4">
          <h2 className="text-lg font-display font-bold text-slate-900 dark:text-white">System Telemetry</h2>
          <LiveBadge />
          <span className="text-xs text-slate-400 dark:text-slate-500 ml-1">· Prometheus · refreshes every 30 s</span>
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          <ChartCard title="JVM Heap Memory" subtitle="Used heap — last 30 min" badge={<LiveBadge />}>
            <AreaMetricChart
              data={jvmMemory.data}
              loading={jvmMemory.loading}
              gradientId="grad-jvm"
              color="#6366f1"
              label="Heap"
              transform={(v) => v / 1_048_576}
              unit=" MB"
              height={180}
            />
          </ChartCard>
          <ChartCard title="System CPU Usage" subtitle="CPU % — last 30 min" badge={<LiveBadge />}>
            <AreaMetricChart
              data={cpuUsage.data}
              loading={cpuUsage.loading}
              gradientId="grad-cpu"
              color="#10b981"
              label="CPU"
              transform={(v) => v * 100}
              unit="%"
              height={180}
            />
          </ChartCard>
        </div>
      </div>

    </div>
  );
};
