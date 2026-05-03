/**
 * DonutChart.tsx
 *
 * A reusable donut (pie with centre hole) chart for categorical breakdowns
 * like ride statuses, report types, and user activity state.
 *
 * Features:
 *   - Animated percentage fill on mount
 *   - Custom centre label with total count
 *   - Interactive tooltip matching the portal design system
 *   - Auto-generates accessible colours from a curated palette if not supplied
 *   - Responsive container — fills its parent's width automatically
 *   - Skeleton loading state
 */

import {
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Tooltip,
  Legend,
} from 'recharts';

export interface DonutSlice {
  label: string;
  count: number;
}

interface DonutChartProps {
  data: DonutSlice[];
  loading: boolean;
  /** Override colours — must match data.length if provided */
  colors?: string[];
  height?: number;
  /** Show a count label in the centre of the donut */
  showCenterLabel?: boolean;
}

// Curated, accessible palette for up to 10 slices
const DEFAULT_COLORS = [
  '#6366f1', // indigo
  '#10b981', // emerald
  '#f59e0b', // amber
  '#ef4444', // red
  '#3b82f6', // blue
  '#8b5cf6', // violet
  '#14b8a6', // teal
  '#f97316', // orange
  '#ec4899', // pink
  '#64748b', // slate
];

/** Prettify enum names: "IN_PROGRESS" → "In Progress" */
function formatLabel(raw: string): string {
  return raw
    .split('_')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
    .join(' ');
}

function CustomTooltip({
  active,
  payload,
}: {
  active?: boolean;
  payload?: Array<{ name: string; value: number; payload: { label: string } }>;
}) {
  if (!active || !payload?.length) return null;
  const entry = payload[0];
  return (
    <div className="bg-slate-900 border border-slate-700 rounded-lg px-3 py-2 shadow-xl text-xs">
      <p className="text-white font-semibold">
        {formatLabel(entry.payload.label)}:{' '}
        <span className="text-indigo-400">{entry.value}</span>
      </p>
    </div>
  );
}

export function DonutChart({
  data,
  loading,
  colors = DEFAULT_COLORS,
  height = 220,
  showCenterLabel = true,
}: DonutChartProps) {
  if (loading) {
    return (
      <div
        style={{ height }}
        className="flex items-center justify-center animate-pulse bg-slate-100 dark:bg-slate-800/50 rounded-xl"
      >
        <span className="text-slate-400 dark:text-slate-600 text-xs font-mono">Loading…</span>
      </div>
    );
  }

  const total = data.reduce((s, d) => s + d.count, 0);

  if (total === 0) {
    return (
      <div
        style={{ height }}
        className="flex items-center justify-center bg-slate-50 dark:bg-slate-800/30 rounded-xl border border-dashed border-slate-200 dark:border-slate-700"
      >
        <span className="text-slate-400 dark:text-slate-600 text-xs font-mono">No data yet</span>
      </div>
    );
  }

  // recharts needs a `name` key for Legend
  const chartData = data.map((d) => ({ ...d, name: formatLabel(d.label) }));

  return (
    <ResponsiveContainer width="100%" height={height}>
      <PieChart>
        <Pie
          data={chartData}
          cx="50%"
          cy="50%"
          innerRadius="55%"
          outerRadius="80%"
          dataKey="count"
          nameKey="name"
          paddingAngle={3}
          isAnimationActive={true}
          animationBegin={0}
          animationDuration={800}
        >
          {chartData.map((_, index) => (
            <Cell key={index} fill={colors[index % colors.length]} stroke="transparent" />
          ))}
        </Pie>
        <Tooltip content={<CustomTooltip />} />
        <Legend
          iconType="circle"
          iconSize={8}
          wrapperStyle={{ fontSize: '11px', paddingTop: '4px' }}
        />
        {showCenterLabel && (
          <text
            x="50%"
            y="42%"
            textAnchor="middle"
            dominantBaseline="middle"
            className="fill-slate-900 dark:fill-white"
            style={{ fontSize: '22px', fontWeight: 700, fill: 'currentColor' }}
          >
            {total}
          </text>
        )}
      </PieChart>
    </ResponsiveContainer>
  );
}
