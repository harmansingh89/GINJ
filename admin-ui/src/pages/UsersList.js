import React, { useEffect, useState } from 'react';
import { get, post } from '../api';

export default function UsersList() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [processing, setProcessing] = useState(false);

  async function fetchUsers() {
    setLoading(true);
    try {
      const res = await get('/api/admin-catalog/users');
      setUsers(res.data);
    } catch (err) {
      console.error(err);
      alert('Failed to load participants');
    } finally {
      setLoading(false);
    }
  }

  async function removeDuplicates() {
    if (!window.confirm('This will delete duplicate participants (keep earliest). Continue?')) return;
    setProcessing(true);
    try {
      const res = await post('/api/admin-catalog/users/remove-duplicates', {});
      alert(`Deleted ${res.data.deleted} duplicate participants`);
      await fetchUsers();
    } catch (err) {
      console.error(err);
      alert('Failed to remove duplicates');
    } finally {
      setProcessing(false);
    }
  }

  useEffect(() => {
    fetchUsers();
  }, []);

  const calculateAge = (dob) => {
    if (!dob) return '-';
    const birthDate = new Date(dob);
    const today = new Date();
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    return age >= 0 ? age : '-';
  };

  const tableStyle = {
    width: '100%',
    minWidth: 920,
    borderCollapse: 'collapse',
    fontSize: 14,
    color: '#1f2937',
  };

  const headerStyle = {
    background: '#f8fafc',
    borderBottom: '2px solid #cbd5e1',
    textAlign: 'left',
    padding: '12px 10px',
    fontWeight: 600,
    fontSize: 13,
    color: '#111827',
  };

  const cellStyle = {
    borderBottom: '1px solid #e5e7eb',
    padding: '10px',
    verticalAlign: 'top',
    whiteSpace: 'normal',
  };

  const buttonStyle = {
    padding: '8px 14px',
    borderRadius: 5,
    border: '1px solid #cbd5e1',
    background: '#ffffff',
    cursor: 'pointer',
  };

  return (
    <div>
      <div style={{ marginBottom: 14, display: 'flex', flexWrap: 'wrap', gap: 8 }}>
        <button onClick={fetchUsers} disabled={loading} style={{ ...buttonStyle, marginRight: 8 }}>
          Refresh
        </button>
        <button onClick={removeDuplicates} disabled={processing} style={buttonStyle}>
          Remove Duplicates (by Phone)
        </button>
      </div>
      {loading ? (
        <div>Loading...</div>
      ) : (
        <div style={{ overflowX: 'auto' }}>
          <table style={tableStyle}>
            <thead>
              <tr>
                <th style={headerStyle}>Id</th>
                <th style={headerStyle}>Phone</th>
                <th style={headerStyle}>Consent</th>
                <th style={headerStyle}>Phone Verified</th>
                <th style={headerStyle}>Saved Address</th>
                <th style={headerStyle}>Name</th>
                <th style={headerStyle}>Age</th>
                <th style={headerStyle}>Sex</th>
                <th style={headerStyle}>Created At</th>
              </tr>
            </thead>
            <tbody>
              {users.map((u, index) => {
                const userProfiles = Array.isArray(u.userProfiles) ? u.userProfiles : [];
                return (
                  <tr key={u.id} style={{ backgroundColor: index % 2 === 0 ? '#ffffff' : '#f8fafc' }}>
                    <td style={cellStyle}>{u.id}</td>
                    <td style={cellStyle}>{u.phone}</td>
                    <td style={cellStyle}>{u.consentAccepted ? 'Yes' : 'No'}</td>
                    <td style={cellStyle}>{u.phoneVerified ? 'Yes' : 'No'}</td>
                    <td style={cellStyle}>{u.savedAddress || '-'}</td>
                    <td style={cellStyle}>{userProfiles.length > 0 ? userProfiles.map((c) => c.name || '-').join(', ') : '-'}</td>
                    <td style={cellStyle}>{userProfiles.length > 0 ? userProfiles.map((c) => calculateAge(c.dateOfBirth)).join(', ') : '-'}</td>
                    <td style={cellStyle}>{userProfiles.length > 0 ? userProfiles.map((c) => c.sex || '-').join(', ') : '-'}</td>
                    <td style={cellStyle}>{new Date(u.createdAt).toLocaleString()}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
