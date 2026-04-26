import { useState } from 'react';
import { Outlet, Navigate, Link, useLocation } from 'react-router-dom';
import { Home, Users, Bike, LogOut, Menu, X, Flag, History, Database, Sun, Moon } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../context/ThemeContext';

export const Layout = () => {
  const { isAuthenticated, logout, role } = useAuth();
  const { theme, toggleTheme } = useTheme();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  const handleLogout = async () => {
    await logout();
  };

  const navItems = [
    { name: 'Dashboard', path: '/', icon: Home },
    { name: 'Users', path: '/users', icon: Users },
    { name: 'Rides', path: '/rides', icon: Bike },
    { name: 'Reports', path: '/reports', icon: Flag },
    { name: 'Audit Logs', path: '/audit-logs', icon: History },
  ];

  if (role === 'ADMIN') {
    navItems.push({ name: 'Query Executor', path: '/query-executor', icon: Database });
  }

  return (
    <div className="flex h-screen bg-transparent flex-col md:flex-row overflow-hidden relative font-sans">
      {/* Mobile Topbar */}
      <div className="md:hidden flex items-center justify-between glass-panel text-slate-900 dark:text-white p-4 z-40 relative">
        <h1 className="text-xl font-bold font-display text-indigo-600 dark:text-indigo-400">
          Throttle Admin
        </h1>
        <div className="flex items-center space-x-4">
          <button onClick={toggleTheme} className="text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white focus:outline-none">
            {theme === 'light' ? <Moon size={20} /> : <Sun size={20} />}
          </button>
          <button onClick={() => setSidebarOpen(!sidebarOpen)} className="text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white focus:outline-none">
            {sidebarOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>
      </div>

      {/* Sidebar Overlay for Mobile */}
      {sidebarOpen && (
        <div 
          className="fixed inset-0 bg-black bg-opacity-50 z-40 md:hidden transition-opacity"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside 
        className={`fixed inset-y-0 left-0 z-50 w-64 glass-panel flex flex-col transform transition-transform duration-300 ease-in-out md:relative md:translate-x-0 md:m-4 md:rounded-2xl md:h-[calc(100vh-2rem)] ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="p-6 hidden md:flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-display font-bold text-indigo-600 dark:text-indigo-400 drop-shadow-sm">
              Throttle
            </h1>
            <p className="text-xs text-slate-500 dark:text-indigo-300 font-semibold tracking-widest mt-1 uppercase">Portal AI</p>
          </div>
          <button onClick={toggleTheme} className="p-2 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-500 dark:text-slate-400 transition-colors">
            {theme === 'light' ? <Moon size={18} /> : <Sun size={18} />}
          </button>
        </div>
        
        <div className="p-6 md:hidden flex justify-between items-center border-b border-slate-200 dark:border-slate-800/50">
          <h1 className="text-xl font-bold text-slate-900 dark:text-white">Menu</h1>
          <button onClick={() => setSidebarOpen(false)} className="text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white focus:outline-none">
             <X size={24} />
          </button>
        </div>
        
        <nav className="flex-1 px-4 space-y-2 mt-4 overflow-y-auto">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            
            return (
              <Link
                key={item.name}
                to={item.path}
                onClick={() => setSidebarOpen(false)}
                className={`flex items-center space-x-3 px-4 py-3 rounded-xl transition-all duration-300 ${
                  isActive 
                    ? 'bg-indigo-50 dark:bg-indigo-500/10 text-indigo-700 dark:text-indigo-400 font-semibold border border-indigo-100 dark:border-indigo-500/30' 
                    : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800/40 hover:text-slate-900 dark:hover:text-slate-200'
                }`}
              >
                <Icon size={20} />
                <span>{item.name}</span>
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-slate-200 dark:border-slate-800/50">
          <button 
            onClick={handleLogout}
            className="flex items-center space-x-3 px-4 py-3 text-slate-600 dark:text-slate-400 hover:text-rose-600 dark:hover:text-rose-400 w-full rounded-xl transition-colors hover:bg-rose-50 dark:hover:bg-rose-500/10 focus:outline-none"
          >
            <LogOut size={20} />
            <span className="font-medium">Logout</span>
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-auto bg-transparent p-4 md:p-8 md:pl-4 h-full">
        <div className="max-w-7xl mx-auto h-full">
          <Outlet />
        </div>
      </main>
    </div>
  );
};
