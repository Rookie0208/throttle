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
          <h1 className="text-3xl font-bold text-gray-900">User Management</h1>
          <p className="text-gray-500 mt-2">View and manage platform riders.</p>
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-max">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-100 text-sm text-gray-500 uppercase tracking-wider">
                <th className="p-4 font-medium">Username</th>
                <th className="p-4 font-medium">Email</th>
                <th className="p-4 font-medium">Role</th>
                <th className="p-4 font-medium">Status</th>
                <th className="p-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
            {loading ? (
              <tr><td colSpan={5} className="text-center p-8 text-gray-400">Loading users...</td></tr>
            ) : users.length === 0 ? (
              <tr><td colSpan={5} className="text-center p-8 text-gray-400">No users found.</td></tr>
            ) : (
              users.map(user => {
                const currentSelectedRole = pendingRoles[user.id] || user.role;
                const hasRoleChanged = currentSelectedRole !== user.role;

                return (
                  <tr key={user.id} className="hover:bg-gray-50 transition-colors">
                    <td className="p-4 font-medium text-gray-900">{user.username}</td>
                    <td className="p-4 text-gray-500">{user.email}</td>
                    <td className="p-4">
                      <select
                        value={currentSelectedRole}
                        onChange={(e) => setPendingRoles({ ...pendingRoles, [user.id]: e.target.value })}
                        className="bg-indigo-50 text-indigo-700 px-3 py-1.5 rounded-full text-xs font-semibold uppercase hover:bg-indigo-100 cursor-pointer focus:outline-none border-0"
                      >

                        <option value="RIDER">RIDER</option>
                        <option value="SUPPORT">SUPPORT</option>
                        <option value="MODERATOR">MODERATOR</option>
                        <option value="ADMIN">ADMIN</option>
                      </select>
                    </td>
                    <td className="p-4">
                      <span className={`px-3 py-1 rounded-full text-xs font-semibold ${user.active ? 'bg-emerald-50 text-emerald-700' : 'bg-red-50 text-red-700'}`}>
                        {user.active ? 'Active' : 'Blocked'}
                      </span>
                    </td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end space-x-2">
                        <button
                          onClick={() => handleRoleChange(user.id, currentSelectedRole)}
                          disabled={!hasRoleChanged}
                          className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                            hasRoleChanged 
                              ? 'bg-blue-600 text-white hover:bg-blue-700 shadow-sm' 
                              : 'bg-gray-100 text-gray-400 cursor-not-allowed'
                          }`}
                        >
                          Update
                        </button>
                        <button
                          onClick={() => handleToggleBlock(user.id, user.active)}
                          className={`inline-flex items-center space-x-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                            user.active 
                              ? 'text-red-600 bg-red-50 hover:bg-red-100' 
                              : 'text-emerald-600 bg-emerald-50 hover:bg-emerald-100'
                          }`}
                        >
                          {user.active ? <ShieldAlert size={16} /> : <ShieldCheck size={16} />}
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
