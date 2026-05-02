import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { Layout } from './components/Layout';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { Users } from './pages/Users';
import { Rides } from './pages/Rides';
import { Reports } from './pages/Reports';
import { AuditLogs } from './pages/AuditLogs';
import { DatabaseQuery } from './pages/DatabaseQuery';
import { Resources } from './pages/Resources';
import { AuthProvider } from './context/AuthContext';

import { ThemeProvider } from './context/ThemeContext';

function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <Toaster position="top-right" />
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<Login />} />
            
            {/* Protected Routes using Layout */}
            <Route path="/" element={<Layout />}>
              <Route index element={<Dashboard />} />
              <Route path="users" element={<Users />} />
              <Route path="rides" element={<Rides />} />
              <Route path="reports" element={<Reports />} />
              <Route path="audit-logs" element={<AuditLogs />} />
              <Route path="resources" element={<Resources />} />
              <Route path="query-executor" element={<DatabaseQuery />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;
