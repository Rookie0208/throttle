import { useState } from 'react';
import { Outlet, Navigate, Link, useLocation } from 'react-router-dom';
import { Home, Users, Bike, LogOut, Menu, X, Flag, History, Database } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export const Layout = () => {
  const { isAuthenticated, logout, role } = useAuth();
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
    <div className="flex h-screen bg-gray-50 flex-col md:flex-row overflow-hidden">
      {/* Mobile Topbar */}
      <div className="md:hidden flex items-center justify-between bg-slate-900 text-white p-4 z-40 relative">
        <h1 className="text-xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-indigo-500">
          Throttle Admin
        </h1>
        <button onClick={() => setSidebarOpen(!sidebarOpen)} className="text-gray-400 hover:text-white focus:outline-none">
          {sidebarOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
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
        className={`fixed inset-y-0 left-0 z-50 w-64 bg-slate-900 text-white flex flex-col transform transition-transform duration-300 ease-in-out md:relative md:translate-x-0 ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="p-6 hidden md:block">
          <h1 className="text-2xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-indigo-500">
            Throttle Admin
          </h1>
        </div>
        
        <div className="p-6 md:hidden flex justify-between items-center border-b border-gray-800">
          <h1 className="text-xl font-bold text-white">Menu</h1>
          <button onClick={() => setSidebarOpen(false)} className="text-gray-400 hover:text-white focus:outline-none">
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
                className={`flex items-center space-x-3 px-4 py-3 rounded-lg transition-all duration-200 ${
                  isActive 
                    ? 'bg-blue-600/20 text-blue-400 font-medium' 
                    : 'text-gray-400 hover:bg-slate-800 hover:text-white'
                }`}
              >
                <Icon size={20} />
                <span>{item.name}</span>
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-slate-800">
          <button 
            onClick={handleLogout}
            className="flex items-center space-x-3 px-4 py-3 text-gray-400 hover:text-white w-full rounded-lg transition-colors hover:bg-slate-800 focus:outline-none"
          >
            <LogOut size={20} />
            <span>Logout</span>
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-auto bg-gray-50 p-4 md:p-8 h-full">
        <Outlet />
      </main>
    </div>
  );
};
