import { createContext, useContext, useState } from 'react';
import type { ReactNode } from 'react';
import apiClient from '../services/apiClient';
import toast from 'react-hot-toast';

interface AuthContextType {
  token: string | null;
  refreshToken: string | null;
  login: (token: string, refreshToken: string) => void;
  logout: () => Promise<void>;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [token, setToken] = useState<string | null>(localStorage.getItem('token'));
  const [refreshToken, setRefreshToken] = useState<string | null>(localStorage.getItem('refreshToken'));

  const login = (newToken: string, newRefreshToken: string) => {
    setToken(newToken);
    setRefreshToken(newRefreshToken);
    localStorage.setItem('token', newToken);
    localStorage.setItem('refreshToken', newRefreshToken);
  };

  const logout = async () => {
    try {
      const currentRefreshToken = localStorage.getItem('refreshToken');
      if (currentRefreshToken) {
        // Ping backend to invalidate session in redis and db
        await apiClient.post('/auth/logout', { refreshToken: currentRefreshToken });
      }
      toast.success("Logged out successfully");
    } catch (err) {
      console.error("Logout request failed, cleaning local state anyway", err);
      toast.error("Logout issue: check network");
    } finally {
      setToken(null);
      setRefreshToken(null);
      localStorage.removeItem('token');
      localStorage.removeItem('refreshToken');
    }
  };

  return (
    <AuthContext.Provider value={{ token, refreshToken, login, logout, isAuthenticated: !!token }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
