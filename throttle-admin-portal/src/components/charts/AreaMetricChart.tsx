/**
 * AreaMetricChart.tsx
 *
 * A reusable, dark/light-mode-aware area chart backed by Recharts.
 * Designed for continuous time-series data (CPU, Memory, RPS etc.)
 * from Prometheus.
 *
 * Features:
 *   - Responsive container — fills its parent's width automatically
 *   - Gradient fill for depth
 *   - Custom styled tooltip matching the portal design system
 *   - X-axis ticks formatted as HH:MM for readability
 *   - Graceful "No data" state when the array is empty
 *   - `loading` skeleton state
 */

import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
} from 'recharts';
import type { PrometheusDataPoint } from '../../services/prometheusClient';

interface AreaMetricChartProps {
  data: PrometheusDataPoint[];
  loading: boolean;
  /** Unique id used for the SVG gradient definition — must be unique per page */
  gradientId: string;
  /** Recharts stroke colour (CSS colour string) */
  color: string;
  /** Human-readable label shown in the tooltip */
  label: string;
  /** Optional: function applied to raw values before display (e.g. * 100 for %) */
  transform?: (v: number) => number;
  /** Unit suffix shown in tooltip, e.g. "%" or " MB" */
  unit?: string;
  /** Height in px (default 180) */
  height?: number;
}

interface ChartPoint {
  time: string;
  value: number;
  rawTs: number;
}

function formatTs(unixTs: number): string {
  const d = new Date(unixTs * 1000);
  return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false });
}

interface CustomTooltipProps {
  active?: boolean;
  payload?: Array<{ value?: number; color?: string; name?: string }>;
  label?: string;
  unit?: string;
  valueLabel: string;
}
function CustomTooltip({ active, payload, label: time, unit, valueLabel }: CustomTooltipProps) {
  if (!active || !payload?.length) return null;
  const val = payload[0].value ?? 0;
  return (
    <div className="bg-slate-900 border border-slate-700 rounded-lg px-3 py-2 shadow-xl text-xs">
      <p className="text-slate-400 mb-1">{time}</p>
      <p className="text-white font-semibold">
        {valueLabel}:{' '}
        <span className="text-indigo-400">
          {typeof val === 'number' ? val.toFixed(2) : val}
          {unit}
        </span>
      </p>
    </div>
  );
}

export function AreaMetricChart({
  data,
  loading,
  gradientId,
  color,
  label,
  transform,
  unit = '',
  height = 180,
}: AreaMetricChartProps) {
  const chartData: ChartPoint[] = data.map((p) => ({
    rawTs: p.timestamp,
    time: formatTs(p.timestamp),
    value: transform ? parseFloat(transform(p.value).toFixed(4)) : parseFloat(p.value.toFixed(4)),
  }));

  if (loading) {
    return (
      <div
        style={{ height }}
        className="flex items-center justify-center animate-pulse bg-slate-100 dark:bg-slate-800/50 rounded-xl"
      >
        <span className="text-slate-400 dark:text-slate-600 text-xs font-mono">Fetching metrics…</span>
      </div>
    );
  }

  if (chartData.length === 0) {
    return (
      <div
        style={{ height }}
        className="flex items-center justify-center bg-slate-50 dark:bg-slate-800/30 rounded-xl border border-dashed border-slate-200 dark:border-slate-700"
      >
        <span className="text-slate-400 dark:text-slate-600 text-xs font-mono">No data available</span>
      </div>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={height}>
      <AreaChart data={chartData} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
        <defs>
          <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor={color} stopOpacity={0.25} />
            <stop offset="95%" stopColor={color} stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="rgba(100,116,139,0.15)" vertical={false} />
        <XAxis
          dataKey="time"
          tick={{ fontSize: 10, fill: '#94a3b8' }}
          tickLine={false}
          axisLine={false}
          interval="preserveStartEnd"
        />
        <YAxis
          tick={{ fontSize: 10, fill: '#94a3b8' }}
          tickLine={false}
          axisLine={false}
        />
        <Tooltip
          content={(props) => (
            <CustomTooltip
              active={props.active}
              payload={props.payload as Array<{ value?: number; color?: string; name?: string }>}
              label={props.label as string}
              unit={unit}
              valueLabel={label}
            />
          )}
        />
        <Area
          type="monotone"
          dataKey="value"
          stroke={color}
          strokeWidth={2}
          fill={`url(#${gradientId})`}
          dot={false}
          activeDot={{ r: 4, strokeWidth: 0 }}
          isAnimationActive={false} // disable for real-time updates
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
