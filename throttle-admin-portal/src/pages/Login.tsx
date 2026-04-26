import { useState } from 'react';
import { useNavigate, Navigate } from 'react-router-dom';
import apiClient from '../services/apiClient';
import { Bike } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import toast from 'react-hot-toast';

export const Login = () => {
  const { login, isAuthenticated } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState('ADMIN');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const resp = await apiClient.post('/auth/login', { email, password, role });
      
      if (resp.data.data && resp.data.data.token && resp.data.data.refreshToken) {
        // Authenticate via robust context utilizing both tokens
        login(resp.data.data.token, resp.data.data.refreshToken, role);
        toast.success("Welcome back, Admin!");
        navigate('/');
      } else {
        toast.error('Invalid credentials or missing tokens.');
      }
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Failed to login');
    } finally {
      setLoading(false);
    }
  };

  if (isAuthenticated) {
    return <Navigate to="/" replace />;
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50 dark:bg-slate-950 p-4 relative overflow-hidden transition-colors duration-200">
      
      <div className="max-w-md w-full glass-panel rounded-3xl p-10 relative z-10 shadow-lg dark:shadow-none">
        <div className="flex flex-col items-center mb-10">
          <div className="w-20 h-20 bg-indigo-50 dark:bg-indigo-500/10 rounded-2xl flex items-center justify-center mb-6 text-indigo-600 dark:text-indigo-400 border border-indigo-100 dark:border-indigo-500/30">
            <Bike size={36} />
          </div>
          <h2 className="text-3xl font-display font-bold text-slate-900 dark:text-white tracking-tight">Throttle Admin</h2>
          <p className="text-slate-500 dark:text-slate-400 mt-2 font-medium tracking-wide uppercase text-xs">Secure Access</p>
        </div>

        {error && (
          <div className="bg-rose-50 dark:bg-rose-500/10 border border-rose-200 dark:border-rose-500/50 text-rose-600 dark:text-rose-400 p-4 rounded-xl mb-8 text-sm flex items-center font-medium">
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-6">
          <div>
            <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-2 uppercase tracking-wide">Role Assignment</label>
            <select
              value={role}
              onChange={(e) => setRole(e.target.value)}
              className="glass-input w-full px-4 py-3 appearance-none"
            >
              <option value="ADMIN">ADMIN</option>
              <option value="SUPPORT">SUPPORT</option>
              <option value="MODERATOR">MODERATOR</option>
              <option value="DEVELOPER">DEVELOPER</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-2 uppercase tracking-wide">Email Address</label>
            <input
              type="email"
              required
              className="glass-input w-full px-4 py-3"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@throttle.com"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-2 uppercase tracking-wide">Password</label>
            <input
              type="password"
              required
              className="glass-input w-full px-4 py-3"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full mt-8 bg-indigo-600 dark:bg-indigo-600 text-white font-bold tracking-wide py-4 rounded-xl hover:bg-indigo-700 dark:hover:bg-indigo-500 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? 'Authenticating...' : 'Sign In'}
          </button>
        </form>
      </div>
    </div>
  );
};
