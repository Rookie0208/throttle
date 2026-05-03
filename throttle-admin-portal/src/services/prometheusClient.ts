/**
 * prometheusClient.ts
 *
 * A typed, lightweight client for querying the Prometheus HTTP API.
 * All functions return strongly-typed results and never throw — callers
 * receive empty arrays on network or parse failure so the UI degrades
 * gracefully without crashing.
 *
 * Prometheus base URL is intentionally kept separate from the Spring Boot
 * apiClient so it does not go through the JWT interceptor chain.
 */

const PROMETHEUS_BASE = 'http://localhost:9090/api/v1';

/** A single [unixTimestamp, valueString] tuple from Prometheus range queries */
export interface PrometheusDataPoint {
  timestamp: number; // Unix epoch seconds
  value: number;
}

interface PrometheusRangeResult {
  metric: Record<string, string>;
  values: [number, string][];
}

interface PrometheusRangeResponse {
  status: string;
  data: {
    resultType: string;
    result: PrometheusRangeResult[];
  };
}

/**
 * Fetches a Prometheus range query and returns the first series as data points.
 *
 * @param query   PromQL expression
 * @param minutes How many minutes back to look (default 30)
 * @param step    Step interval in seconds (default 60)
 */
export async function fetchRangeQuery(
  query: string,
  minutes = 30,
  step = 60,
): Promise<PrometheusDataPoint[]> {
  try {
    const end = Math.floor(Date.now() / 1000);
    const start = end - minutes * 60;

    const params = new URLSearchParams({
      query,
      start: String(start),
      end: String(end),
      step: String(step),
    });

    const response = await fetch(`${PROMETHEUS_BASE}/query_range?${params}`, {
      signal: AbortSignal.timeout(5000),
    });

    if (!response.ok) return [];

    const json: PrometheusRangeResponse = await response.json();

    if (json.status !== 'success' || json.data.result.length === 0) return [];

    return json.data.result[0].values.map(([ts, val]) => ({
      timestamp: ts,
      value: parseFloat(val) || 0,
    }));
  } catch {
    // Network error, timeout, or malformed response — fail silently
    return [];
  }
}

/**
 * Fetches a Prometheus instant query and returns a single numeric value.
 *
 * @param query PromQL expression
 * @returns     The parsed value, or 0 on failure
 */
export async function fetchInstantQuery(query: string): Promise<number> {
  try {
    const params = new URLSearchParams({ query });

    const response = await fetch(`${PROMETHEUS_BASE}/query?${params}`, {
      signal: AbortSignal.timeout(5000),
    });

    if (!response.ok) return 0;

    const json = await response.json();
    if (json.status !== 'success' || json.data.result.length === 0) return 0;

    return parseFloat(json.data.result[0].value[1]) || 0;
  } catch {
    return 0;
  }
}
