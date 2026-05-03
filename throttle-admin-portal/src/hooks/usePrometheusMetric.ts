/**
 * usePrometheusMetric.ts
 *
 * A production-grade custom hook for continuously polling a Prometheus
 * range query. It handles:
 *   - Initial load state
 *   - Auto-refresh on configurable interval
 *   - Cleanup on unmount (no stale state updates)
 *   - Graceful error handling (returns empty data, not errors)
 */

import { useEffect, useRef, useState } from 'react';
import { fetchRangeQuery, type PrometheusDataPoint } from '../services/prometheusClient';

interface UsePrometheusMetricOptions {
  /** PromQL query string */
  query: string;
  /** Lookback window in minutes */
  minutes?: number;
  /** Step resolution in seconds */
  step?: number;
  /** How often to refresh in milliseconds (default: 30 000 ms) */
  refreshIntervalMs?: number;
}

interface UsePrometheusMetricResult {
  data: PrometheusDataPoint[];
  loading: boolean;
}

export function usePrometheusMetric({
  query,
  minutes = 30,
  step = 60,
  refreshIntervalMs = 30_000,
}: UsePrometheusMetricOptions): UsePrometheusMetricResult {
  const [data, setData] = useState<PrometheusDataPoint[]>([]);
  const [loading, setLoading] = useState(true);
  // Use a ref for the mounted flag to avoid stale closure issues
  const mountedRef = useRef(true);

  useEffect(() => {
    mountedRef.current = true;

    const load = async () => {
      const result = await fetchRangeQuery(query, minutes, step);
      if (mountedRef.current) {
        setData(result);
        setLoading(false);
      }
    };

    load();
    const interval = setInterval(load, refreshIntervalMs);

    return () => {
      mountedRef.current = false;
      clearInterval(interval);
    };
  }, [query, minutes, step, refreshIntervalMs]);

  return { data, loading };
}
