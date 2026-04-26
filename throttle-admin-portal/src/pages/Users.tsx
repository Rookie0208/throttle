import { useEffect, useState } from 'react';
import apiClient from '../services/apiClient';
import { ShieldAlert, ShieldCheck } from 'lucide-react';
import toast from 'react-hot-toast';

interface User {
  id: number;
  username: string;
  email: string;
  role: string;
  active: boolean;
  createdAt: string;
}

export const Users = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [pendingRoles, setPendingRoles] = useState<Record<number, string>>({});

  const fetchUsers = async () => {
    try {
      const resp = await apiClient.get('/admin/users');
      setUsers(resp.data.data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleToggleBlock = async (id: number, currentlyActive: boolean) => {
    try {
      if (currentlyActive) {
        await apiClient.put(`/admin/users/${id}/block`);
      } else {
      await apiClient.put(`/admin/users/${id}/unblock`);
      toast.success("User unblocked");
    }
    fetchUsers(); // refresh data
  } catch (err) {
    toast.error("Failed to toggle block state");
  }
};

const handleRoleChange = async (id: number, newRole: string) => {
  try {
    await apiClient.put(`/admin/users/${id}/role?role=${newRole}`);
    toast.success(`Role updated to ${newRole}`);
    // Clear the pending state for this specific user to lock the button again
    setPendingRoles(prev => {
      const updated = { ...prev };
      delete updated[id];
      return updated;
    });
    fetchUsers();
  } catch (err) {
    toast.error("Failed to update user role");
  }
};

  return (
    <div className="animate-in fade-in duration-500">
      <div className="mb-8 flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-display font-bold text-slate-900 dark:text-white">User Management</h1>
          <p className="text-slate-600 dark:text-slate-400 mt-1 font-medium">View and manage platform riders.</p>
        </div>
      </div>

      <div className="glass-panel overflow-hidden border-x-0 border-b-0 md:border md:rounded-2xl shadow-sm">
        <div className="overflow-x-auto">
          <table className="glass-table min-w-max">
            <thead>
              <tr>
                <th>Username</th>
                <th>Email</th>
                <th>Role</th>
                <th>Status</th>
                <th className="text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
            {loading ? (
              <tr><td colSpan={5} className="text-center py-10 font-semibold text-slate-500 dark:text-slate-400">Loading users...</td></tr>
            ) : users.length === 0 ? (
              <tr><td colSpan={5} className="text-center py-10 font-semibold text-slate-500 dark:text-slate-400">No users found.</td></tr>
            ) : (
              users.map(user => {
                const currentSelectedRole = pendingRoles[user.id] || user.role;
                const hasRoleChanged = currentSelectedRole !== user.role;

                return (
                  <tr key={user.id}>
                    <td className="font-semibold text-slate-900 dark:text-slate-200">{user.username}</td>
                    <td className="text-slate-600 dark:text-slate-400">{user.email}</td>
                    <td>
                      <select
                        value={currentSelectedRole}
                        onChange={(e) => setPendingRoles({ ...pendingRoles, [user.id]: e.target.value })}
                        className="bg-slate-100 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 text-slate-800 dark:text-slate-300 px-3 py-1.5 rounded-md text-xs font-semibold uppercase hover:bg-slate-200 dark:hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500/50 appearance-none"
                      >
                        <option value="RIDER">RIDER</option>
                        <option value="SUPPORT">SUPPORT</option>
                        <option value="MODERATOR">MODERATOR</option>
                        <option value="ADMIN">ADMIN</option>
                      </select>
                    </td>
                    <td>
                      <span className={`px-2.5 py-1 rounded-md text-[10px] uppercase font-bold tracking-widest ${user.active ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-500/30' : 'bg-rose-100 text-rose-700 dark:bg-rose-500/10 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30'}`}>
                        {user.active ? 'Active' : 'Blocked'}
                      </span>
                    </td>
                    <td className="text-right">
                      <div className="flex items-center justify-end space-x-2">
                        <button
                          onClick={() => handleRoleChange(user.id, currentSelectedRole)}
                          disabled={!hasRoleChanged}
                          className={`px-4 py-1.5 rounded-md text-xs font-bold uppercase tracking-wide transition-all ${
                            hasRoleChanged 
                              ? 'bg-indigo-600 text-white hover:bg-indigo-700 shadow-sm' 
                              : 'bg-slate-100 text-slate-400 dark:bg-slate-800 dark:text-slate-600 cursor-not-allowed'
                          }`}
                        >
                          Update
                        </button>
                        <button
                          onClick={() => handleToggleBlock(user.id, user.active)}
                          className={`inline-flex items-center space-x-2 px-3 py-1.5 rounded-md text-xs font-bold uppercase tracking-wide transition-all ${
                            user.active 
                              ? 'text-rose-700 hover:bg-rose-100 bg-rose-50 border border-rose-200 dark:text-rose-400 dark:hover:bg-rose-500/20 dark:bg-rose-500/10 dark:border-rose-500/30' 
                              : 'text-emerald-700 hover:bg-emerald-100 bg-emerald-50 border border-emerald-200 dark:text-emerald-400 dark:hover:bg-emerald-500/20 dark:bg-emerald-500/10 dark:border-emerald-500/30'
                          }`}
                        >
                          {user.active ? <ShieldAlert size={14} /> : <ShieldCheck size={14} />}
                          <span>{user.active ? 'Block' : 'Unblock'}</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
        </div>
      </div>
    </div>
  );
};
