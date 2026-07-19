import React, { useEffect, useState } from 'react';
import { get, put } from '../api';

const AddressesList = () => {
  const [addresses, setAddresses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [editingId, setEditingId] = useState(null);
  const [editingValues, setEditingValues] = useState({
    recipientName: '',
    houseOrFlatNo: '',
    streetOrLocality: '',
    city: '',
    pinCode: '',
  });
  const [actionError, setActionError] = useState(null);
  const [successMessage, setSuccessMessage] = useState(null);

  const loadAddresses = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await get('/api/admin-catalog/addresses');
      setAddresses(response.data);
    } catch (err) {
      console.error(err);
      setError('Unable to load addresses.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadAddresses();
  }, []);

  const handleRefresh = () => {
    loadAddresses();
  };

  const handleEdit = (address) => {
    setEditingId(address.id);
    setEditingValues({
      recipientName: address.recipientName || '',
      houseOrFlatNo: address.houseOrFlatNo || '',
      streetOrLocality: address.streetOrLocality || '',
      city: address.city || '',
      pinCode: address.pinCode || '',
    });
    setActionError(null);
    setSuccessMessage(null);
  };

  const handleSave = async () => {
    if (!editingId) return;
    setActionError(null);
    setSuccessMessage(null);

    try {
      await put(`/api/admin-catalog/addresses/${editingId}`, {
        ...editingValues,
      });
      setSuccessMessage('Saved successfully.');
      setEditingId(null);
      setEditingValues({
        recipientName: '',
        houseOrFlatNo: '',
        streetOrLocality: '',
        city: '',
        pinCode: '',
      });
      await loadAddresses();
    } catch (err) {
      console.error(err);
      setActionError('Unable to update details.');
    }
  };

  const tableStyle = {
    width: '100%',
    minWidth: 1120,
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
      <div style={{ marginBottom: 14 }}>
        <button onClick={handleRefresh} disabled={loading} style={buttonStyle}>
          Refresh
        </button>
      </div>
      {loading && <p>Loading addresses...</p>}
      {error && <p style={{ color: 'red' }}>{error}</p>}
      {successMessage && <p style={{ color: 'green' }}>{successMessage}</p>}
      {actionError && <p style={{ color: 'red' }}>{actionError}</p>}

      {!loading && !error && (
        <div style={{ overflowX: 'auto' }}>
          <table style={tableStyle}>
            <thead>
              <tr>
                <th style={headerStyle}>User ID</th>
                <th style={headerStyle}>Participant</th>
                <th style={headerStyle}>Phone No</th>
                <th style={headerStyle}>Recipient Name</th>
                <th style={headerStyle}>House / Flat No</th>
                <th style={headerStyle}>Street / Locality</th>
                <th style={headerStyle}>City</th>
                <th style={headerStyle}>PIN Code</th>
                <th style={headerStyle}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {addresses.map((address, index) => {
                const userProfiles = address.userProfiles || [];
                return (
                  <tr key={address.id} style={{ backgroundColor: index % 2 === 0 ? '#ffffff' : '#f8fafc' }}>
                    <td style={cellStyle}>{address.id}</td>
                    <td style={cellStyle}>{userProfiles.length > 0 ? userProfiles.map((c) => c.name || '-').join(', ') : 'None'}</td>
                    <td style={cellStyle}>{address.phone || 'None'}</td>
                    <td style={cellStyle}>{address.recipientName || 'None'}</td>
                    <td style={cellStyle}>{address.houseOrFlatNo || 'None'}</td>
                    <td style={cellStyle}>{address.streetOrLocality || 'None'}</td>
                    <td style={cellStyle}>{address.city || 'None'}</td>
                    <td style={cellStyle}>{address.pinCode || 'None'}</td>
                    <td style={cellStyle}>
                      <button onClick={() => handleEdit(address)} style={buttonStyle}>Edit</button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {editingId && (
        <div style={{ marginTop: 24, maxWidth: 640, background: '#ffffff', border: '1px solid #e5e7eb', borderRadius: 8, padding: 16 }}>
          <h3 style={{ marginTop: 0 }}>Edit User #{editingId}</h3>
          <div style={{ marginBottom: 8 }}>
            <label style={{ display: 'block', marginBottom: 4 }}>Recipient Name</label>
            <input
              type="text"
              value={editingValues.recipientName}
              onChange={(e) => setEditingValues((prev) => ({ ...prev, recipientName: e.target.value }))}
              style={{ width: '100%', padding: 8, marginBottom: 12 }}
            />
            <label style={{ display: 'block', marginBottom: 4 }}>House / Flat No</label>
            <input
              type="text"
              value={editingValues.houseOrFlatNo}
              onChange={(e) => setEditingValues((prev) => ({ ...prev, houseOrFlatNo: e.target.value }))}
              style={{ width: '100%', padding: 8, marginBottom: 12 }}
            />
            <label style={{ display: 'block', marginBottom: 4 }}>Street / Locality</label>
            <input
              type="text"
              value={editingValues.streetOrLocality}
              onChange={(e) => setEditingValues((prev) => ({ ...prev, streetOrLocality: e.target.value }))}
              style={{ width: '100%', padding: 8, marginBottom: 12 }}
            />
            <label style={{ display: 'block', marginBottom: 4 }}>City</label>
            <input
              type="text"
              value={editingValues.city}
              onChange={(e) => setEditingValues((prev) => ({ ...prev, city: e.target.value }))}
              style={{ width: '100%', padding: 8, marginBottom: 12 }}
            />
            <label style={{ display: 'block', marginBottom: 4 }}>PIN Code</label>
            <input
              type="text"
              value={editingValues.pinCode}
              onChange={(e) => setEditingValues((prev) => ({ ...prev, pinCode: e.target.value }))}
              style={{ width: '100%', padding: 8, marginBottom: 12 }}
            />
          </div>
          <button onClick={handleSave} style={{ ...buttonStyle, marginRight: 8 }}>
            Save
          </button>
          <button
            onClick={() => {
              setEditingId(null);
              setEditingValues({
                recipientName: '',
                houseOrFlatNo: '',
                streetOrLocality: '',
                city: '',
                pinCode: '',
              });
            }}
            style={buttonStyle}
          >
            Cancel
          </button>
        </div>
      )}
    </div>
  );
};

export default AddressesList;
