/**
 * BarGrowthChart.tsx
 *
 * A reusable bar chart for discrete daily growth metrics (user signups,
 * ride creations) backed by Recharts.
 *
 * Features:
 *   - Rounded bar corners for a modern premium look
 *   - Dual-series support (users + rides on the same chart)
 *   - X-axis formatted as short date strings
 *   - Custom tooltip matching the portal design system
 *   - Responsive container — fills parent width automatically
 *   - Skeleton loading state
 */

import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  Cell,
  type TooltipProps,
} from 'recharts';

export interface GrowthPoint {
  date: string;
  count: number;
}

interface BarGrowthChartProps {
  userGrowth: GrowthPoint[];
  rideGrowth: GrowthPoint[];
  loading: boolean;
  height?: number;
}

/**
 * Merges two growth series (by date), filling missing dates with zero
 * so bars are always aligned on the same axis.
 */
function mergeGrowthSeries(users: GrowthPoint[], rides: GrowthPoint[]) {
  const dateSet = new Set([...users.map((u) => u.date), ...rides.map((r) => r.date)]);
  const userMap = new Map(users.map((u) => [u.date, u.count]));
  const rideMap = new Map(rides.map((r) => [r.date, r.count]));

  return Array.from(dateSet)
    .sort()
    .map((date) => ({
      date: date.substring(5), // "MM-DD" — shorter for x-axis
      users: userMap.get(date) ?? 0,
      rides: rideMap.get(date) ?? 0,
    }));
}

function CustomTooltip({ active, payload, label }: TooltipProps<number, string>) {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-slate-900 border border-slate-700 rounded-lg px-3 py-2 shadow-xl text-xs space-y-1">
      <p className="text-slate-400 font-medium mb-1">{label}</p>
      {payload.map((entry) => (
        <p key={entry.name} className="text-white">
          {entry.name === 'users' ? '👤 New Users' : '🏍️ New Rides'}:{' '}
          <span className="font-bold" style={{ color: entry.color }}>
            {entry.value}
          </span>
        </p>
      ))}
    </div>
  );
}

export function BarGrowthChart({ userGrowth, rideGrowth, loading, height = 220 }: BarGrowthChartProps) {
  const merged = mergeGrowthSeries(userGrowth, rideGrowth);

  if (loading) {
    return (
      <div
        style={{ height }}
        className="flex items-center justify-center animate-pulse bg-slate-100 dark:bg-slate-800/50 rounded-xl"
      >
        <span className="text-slate-400 dark:text-slate-600 text-xs font-mono">Loading growth data…</span>
      </div>
    );
  }

  if (merged.length === 0) {
    return (
      <div
        style={{ height }}
        className="flex items-center justify-center bg-slate-50 dark:bg-slate-800/30 rounded-xl border border-dashed border-slate-200 dark:border-slate-700"
      >
        <span className="text-slate-400 dark:text-slate-600 text-xs font-mono">No growth data yet</span>
      </div>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={height}>
      <BarChart data={merged} margin={{ top: 4, right: 4, left: -20, bottom: 0 }} barGap={4}>
        <CartesianGrid strokeDasharray="3 3" stroke="rgba(100,116,139,0.15)" vertical={false} />
        <XAxis
          dataKey="date"
          tick={{ fontSize: 10, fill: '#94a3b8' }}
          tickLine={false}
          axisLine={false}
        />
        <YAxis
          allowDecimals={false}
          tick={{ fontSize: 10, fill: '#94a3b8' }}
          tickLine={false}
          axisLine={false}
        />
        <Tooltip content={<CustomTooltip />} />
        <Legend
          iconType="circle"
          iconSize={8}
          wrapperStyle={{ fontSize: '11px', paddingTop: '8px' }}
          formatter={(value) => (value === 'users' ? 'New Users' : 'New Rides')}
        />
        <Bar dataKey="users" fill="#6366f1" radius={[4, 4, 0, 0]} maxBarSize={28} isAnimationActive={false}>
          {merged.map((_, i) => (
            <Cell key={i} fill="#6366f1" fillOpacity={0.85} />
          ))}
        </Bar>
        <Bar dataKey="rides" fill="#10b981" radius={[4, 4, 0, 0]} maxBarSize={28} isAnimationActive={false}>
          {merged.map((_, i) => (
            <Cell key={i} fill="#10b981" fillOpacity={0.85} />
          ))}
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  );
}
