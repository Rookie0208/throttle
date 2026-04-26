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
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Query Executor</h1>
          <p className="text-gray-500 mt-1">Run complex queries and data fixes manually (Max 500 rows)</p>
        </div>
      </div>

      {/* Editor Section */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div className="bg-slate-900 px-4 py-3 flex justify-between items-center">
          <span className="text-gray-300 text-sm font-mono flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-green-500"></span> SQL Window
          </span>
          <button
            onClick={handleExecute}
            disabled={loading || !query.trim()}
            className="flex items-center space-x-2 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-white px-4 py-1.5 rounded-lg text-sm font-medium transition-colors"
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
          className="w-full h-48 sm:h-64 bg-slate-950 text-emerald-400 font-mono p-4 resize-y focus:outline-none placeholder-gray-700 leading-relaxed"
          spellCheck={false}
        />
      </div>

      {/* Results Section */}
      {result && (
        <div className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-300">
          <div className="flex items-center justify-between text-sm">
            <h2 className="text-lg font-semibold text-gray-900">Execution Result</h2>
            <div className="flex items-center space-x-4">
              <span className="flex items-center space-x-1.5 text-gray-500">
                <Clock size={14} />
                <span>{result.executionTimeMs} ms</span>
              </span>
              {result.error ? (
                <span className="flex items-center space-x-1.5 text-red-600 bg-red-50 px-2.5 py-1 rounded-full">
                  <AlertCircle size={14} />
                  <span>Failed</span>
                </span>
              ) : (
                <span className="flex items-center space-x-1.5 text-emerald-600 bg-emerald-50 px-2.5 py-1 rounded-full">
                  <CheckCircle2 size={14} />
                  <span>Success</span>
                </span>
              )}
            </div>
          </div>

          {result.error && (
            <div className="bg-red-50 border border-red-200 text-red-700 p-4 rounded-lg font-mono text-sm whitespace-pre-wrap">
              <div className="font-semibold mb-1 flex items-center gap-2">
                <AlertCircle size={16} /> SQL Exception
              </div>
              {result.error}
            </div>
          )}

          {!result.error && !result.resultSet && (
            <div className="bg-white border border-gray-200 p-6 rounded-xl flex flex-col items-center justify-center text-gray-500">
              <CheckCircle2 size={32} className="text-emerald-500 mb-3" />
              <p className="text-lg font-medium text-gray-900">Query Executed Successfully</p>
              <p className="mt-1">{result.rowsAffected} row(s) affected.</p>
            </div>
          )}

          {!result.error && result.resultSet && result.columns && result.data && (
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    {result.columns.map((col, idx) => (
                      <th
                        key={idx}
                        className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider whitespace-nowrap"
                      >
                        {col}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {result.data.length === 0 ? (
                    <tr>
                      <td colSpan={result.columns.length} className="px-6 py-8 text-center text-gray-500">
                        No rows returned.
                      </td>
                    </tr>
                  ) : (
                    result.data.map((row, rowIdx) => (
                      <tr key={rowIdx} className="hover:bg-slate-50 transition-colors">
                        {result.columns!.map((col, colIdx) => (
                          <td key={colIdx} className="px-6 py-4 whitespace-nowrap text-sm text-gray-700">
                            {row[col] === null ? (
                              <span className="text-gray-400 italic">null</span>
                            ) : typeof row[col] === 'boolean' ? (
                              row[col] ? 'true' : 'false'
                            ) : typeof row[col] === 'object' ? (
                              JSON.stringify(row[col])
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
