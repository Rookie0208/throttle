import { useState } from 'react';
import { Play, AlertCircle, CheckCircle2, Clock } from 'lucide-react';
import apiClient from '../services/apiClient';

interface QueryResponse {
  resultSet: boolean;
  columns?: string[];
  data?: Record<string, any>[];
  rowsAffected?: number;
  executionTimeMs: number;
  error?: string;
}

export const DatabaseQuery = () => {
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<QueryResponse | null>(null);

  const handleExecute = async () => {
    if (!query.trim()) return;

    setLoading(true);
    setResult(null);

    try {
      const response = await apiClient.post('/admin/execute-query', { query });
      setResult(response.data.data);
    } catch (err: any) {
      if (err.response?.data?.data) {
        setResult(err.response.data.data);
      } else {
        setResult({
          resultSet: false,
          executionTimeMs: 0,
          error: err.response?.data?.message || 'Network error occurred while executing the query.',
        });
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="animate-in fade-in duration-500 space-y-6">
      <div className="flex justify-between items-center mb-4">
        <div>
          <h1 className="text-3xl font-display font-bold text-slate-900 dark:text-white">Query Executor</h1>
          <p className="text-slate-600 dark:text-slate-400 mt-1 font-medium">Run complex database queries and telemetry fixes seamlessly via raw uplink.</p>
        </div>
      </div>

      {/* Editor Section */}
      <div className="glass-panel overflow-hidden border border-slate-200 dark:border-slate-800 shadow-sm rounded-2xl">
        <div className="bg-slate-100 dark:bg-slate-950 px-6 py-4 flex justify-between items-center border-b border-slate-200 dark:border-slate-800">
          <span className="text-indigo-600 dark:text-indigo-400 text-xs font-semibold uppercase tracking-widest flex items-center gap-3">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse shadow-[0_0_8px_rgba(16,185,129,0.5)] dark:shadow-[0_0_8px_rgba(52,211,153,0.8)]"></span> Secure SQL Tunnel ACTIVE
          </span>
          <button
            onClick={handleExecute}
            disabled={loading || !query.trim()}
            className="flex items-center space-x-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed text-white px-5 py-2 rounded-xl text-xs font-bold uppercase tracking-wider transition-all shadow-sm"
          >
            {loading ? (
              <div className="w-4 h-4 border-2 border-white/20 border-t-white rounded-full animate-spin" />
            ) : (
              <Play size={16} />
            )}
            <span>Execute</span>
          </button>
        </div>
        <textarea
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="SELECT * FROM users LIMIT 10;"
          className="w-full h-48 sm:h-64 bg-slate-50 dark:bg-slate-900/50 text-indigo-700 dark:text-cyan-400 font-mono p-6 resize-y outline-none placeholder-slate-400 dark:placeholder-slate-700 leading-relaxed text-sm shadow-inner"
          spellCheck={false}
        />
      </div>

      {/* Results Section */}
      {result && (
        <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
          <div className="flex items-center justify-between text-sm bg-slate-100 dark:bg-slate-900/40 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
            <h2 className="text-lg font-display font-bold text-slate-900 dark:text-slate-200 uppercase tracking-wide">Execution Result</h2>
            <div className="flex items-center space-x-6">
              <span className="flex items-center space-x-2 text-indigo-600 dark:text-indigo-400 font-mono">
                <Clock size={14} />
                <span>{result.executionTimeMs}ms</span>
              </span>
              {result.error ? (
                <span className="flex items-center space-x-2 text-rose-700 bg-rose-100 border border-rose-200 dark:text-rose-400 dark:bg-rose-500/10 dark:border-rose-500/30 px-3 py-1 rounded-full font-bold uppercase text-[10px] tracking-widest">
                  <AlertCircle size={14} />
                  <span>Failed</span>
                </span>
              ) : (
                <span className="flex items-center space-x-2 text-emerald-700 bg-emerald-100 border border-emerald-200 dark:text-emerald-400 dark:bg-emerald-500/10 dark:border-emerald-500/30 px-3 py-1 rounded-full font-bold uppercase text-[10px] tracking-widest">
                  <CheckCircle2 size={14} />
                  <span>Success</span>
                </span>
              )}
            </div>
          </div>

          {result.error && (
            <div className="bg-rose-50 dark:bg-rose-500/10 border border-rose-200 dark:border-rose-500/30 text-rose-700 dark:text-rose-400 p-6 rounded-2xl font-mono text-sm whitespace-pre-wrap">
              <div className="font-bold mb-3 flex items-center gap-2 uppercase tracking-widest text-xs">
                <AlertCircle size={16} /> SQL Exception Detected
              </div>
              {result.error}
            </div>
          )}

          {!result.error && !result.resultSet && (
            <div className="glass-panel p-10 flex flex-col items-center justify-center text-slate-500 dark:text-slate-400">
              <CheckCircle2 size={48} className="text-emerald-500 dark:text-emerald-400 mb-4" />
              <p className="text-2xl font-display font-bold text-slate-900 dark:text-slate-200">Query Executed Successfully</p>
              <p className="mt-2 text-indigo-600 dark:text-indigo-300 font-mono">{result.rowsAffected} row(s) updated in database.</p>
            </div>
          )}

          {!result.error && result.resultSet && result.columns && result.data && (
            <div className="glass-panel overflow-hidden overflow-x-auto shadow-sm rounded-2xl">
              <table className="glass-table min-w-full">
                <thead>
                  <tr>
                    {result.columns.map((col, idx) => (
                      <th
                        key={idx}
                      >
                        {col}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {result.data.length === 0 ? (
                    <tr>
                      <td colSpan={result.columns.length} className="px-6 py-8 text-center text-slate-500 font-medium">
                        No rows returned.
                      </td>
                    </tr>
                  ) : (
                    result.data.map((row, rowIdx) => (
                      <tr key={rowIdx}>
                        {result.columns!.map((col, colIdx) => (
                          <td key={colIdx}>
                            {row[col] === null ? (
                              <span className="text-slate-400 dark:text-slate-500 italic font-mono text-xs">null</span>
                            ) : typeof row[col] === 'boolean' ? (
                              <span className={`px-2 py-0.5 rounded text-[10px] uppercase font-bold tracking-widest ${row[col] ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400' : 'bg-rose-100 text-rose-700 dark:bg-rose-500/10 dark:text-rose-400'}`}>{row[col] ? 'true' : 'false'}</span>
                            ) : typeof row[col] === 'object' ? (
                              <span className="font-mono text-xs text-indigo-600 dark:text-indigo-300">{JSON.stringify(row[col])}</span>
                            ) : (
                              String(row[col])
                            )}
                          </td>
                        ))}
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
