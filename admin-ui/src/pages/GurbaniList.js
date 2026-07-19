import React, { useEffect, useState, useRef } from 'react';
import { get, post, put, remove } from '../api';

const emptyGurbaniItem = {
  title: '',
  youtubeUrl: '',
  isThisGurbani: false,
  ageGroup: '',
  isActive: true,
};

const GurbaniList = () => {
  const [gurbaniItems, setGurbaniItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [workingGurbaniItem, setWorkingGurbaniItem] = useState(emptyGurbaniItem);
  const [editingId, setEditingId] = useState(null);
  const [showForm, setShowForm] = useState(false);
  const [actionError, setActionError] = useState(null);
  const [successMessage, setSuccessMessage] = useState(null);
  const formRef = useRef(null);

  const loadGurbaniItems = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await get('/api/admin-catalog/gurbani-items');
      setGurbaniItems(response.data);
    } catch (err) {
      console.error(err);
      setError('Unable to load gurbani items.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadGurbaniItems();
  }, []);

  const handleRefresh = () => {
    loadGurbaniItems();
  };

  const handleEdit = (gurbaniItem) => {
    setEditingId(gurbaniItem.id);
    setShowForm(true);
    setWorkingGurbaniItem({
      title: gurbaniItem.title || '',
      youtubeUrl: gurbaniItem.youtubeUrl || '',
      isThisGurbani: gurbaniItem.isThisGurbani || false,
      ageGroup: gurbaniItem.ageGroup || '',
      isActive: gurbaniItem.isActive,
    });
    setActionError(null);
    setSuccessMessage(null);
    setTimeout(() => {
      formRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }, 50);
  };

  const handleCreate = () => {
    setEditingId(null);
    setWorkingGurbaniItem(emptyGurbaniItem);
    setShowForm(true);
    setActionError(null);
    setSuccessMessage(null);
    setTimeout(() => {
      formRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }, 50);
  };

  const handleCancel = () => {
    setShowForm(false);
    setEditingId(null);
    setWorkingGurbaniItem(emptyGurbaniItem);
    setActionError(null);
    setSuccessMessage(null);
  };

  const handleSubmit = async () => {
    setActionError(null);
    setSuccessMessage(null);

    try {
      if (editingId) {
        await put(`/api/admin-catalog/gurbani-items/${editingId}`, workingGurbaniItem);
        setSuccessMessage('Gurbani item updated successfully.');
      } else {
        await post('/api/admin-catalog/gurbani-items', workingGurbaniItem);
        setSuccessMessage('Gurbani item created successfully.');
      }
      await loadGurbaniItems();
      setEditingId(null);
      setWorkingGurbaniItem(emptyGurbaniItem);
      setShowForm(false);
    } catch (err) {
      console.error(err);
      setActionError('Unable to save gurbani item.');
    }
  };

  const handleDelete = async (id) => {
    setActionError(null);
    setSuccessMessage(null);
    try {
      await remove(`/api/admin-catalog/gurbani-items/${id}`);
      setSuccessMessage('Gurbani item deleted successfully.');
      await loadGurbaniItems();
    } catch (err) {
      console.error(err);
      setActionError('Unable to delete gurbani item.');
    }
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

  const inputStyle = {
    width: '100%',
    padding: '8px 10px',
    border: '1px solid #d1d5db',
    borderRadius: 4,
    fontSize: 13,
  };

  return (
    <div>
      <div style={{ marginBottom: 14, display: 'flex', flexWrap: 'wrap', gap: 8 }}>
        <button onClick={handleRefresh} disabled={loading} style={buttonStyle}>
          Refresh
        </button>
        <button onClick={handleCreate} style={buttonStyle}>
          Add New
        </button>
      </div>
      {successMessage && <p style={{ color: 'green' }}>{successMessage}</p>}
      {actionError && <p style={{ color: 'red' }}>{actionError}</p>}
      {loading && <p>Loading gurbani...</p>}
      {error && <p style={{ color: 'red' }}>{error}</p>}
      {!loading && !error && (
        <div style={{ overflowX: 'auto' }}>
          <table style={tableStyle}>
            <thead>
              <tr>
                <th style={headerStyle}>Gurbani/Jiwani/History</th>
                <th style={headerStyle}>Youtube Link</th>
                <th style={headerStyle}>Is This Gurbani</th>
                <th style={headerStyle}>Weightage</th>
                <th style={headerStyle}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {gurbaniItems.map((gurbaniItem, index) => (
                <tr key={gurbaniItem.id} style={{ backgroundColor: index % 2 === 0 ? '#ffffff' : '#f8fafc' }}>
                  <td style={cellStyle}>{gurbaniItem.title}</td>
                  <td style={cellStyle}>
                    {gurbaniItem.youtubeUrl ? (
                      <a href={gurbaniItem.youtubeUrl} target="_blank" rel="noopener noreferrer">
                        Link
                      </a>
                    ) : (
                      'None'
                    )}
                  </td>
                  <td style={cellStyle}>{gurbaniItem.isThisGurbani ? 'Yes' : 'No'}</td>
                  <td style={cellStyle}>{gurbaniItem.scoreRequirement ?? gurbaniItem.weightage ?? 'None'}</td>
                  <td style={cellStyle}>
                    <button onClick={() => handleEdit(gurbaniItem)} style={{ ...buttonStyle, marginRight: 8 }}>
                      Edit
                    </button>
                    <button onClick={() => handleDelete(gurbaniItem.id)} style={buttonStyle}>
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {showForm && (
        <div ref={formRef} style={{ marginTop: 24, maxWidth: 640, background: '#ffffff', border: '1px solid #e5e7eb', borderRadius: 8, padding: 16 }}>
          <h3 style={{ marginTop: 0 }}>{editingId ? 'Edit Gurbani/Jiwani/History' : 'Add Gurbani/Jiwani/History'}</h3>
          <div style={{ marginBottom: 8 }}>
            <label style={{ display: 'block', marginBottom: 4 }}>Gurbani/Jiwani/History</label>
            <input
              type="text"
                value={workingGurbaniItem.title}
                onChange={(e) => setWorkingGurbaniItem({ ...workingGurbaniItem, title: e.target.value })}
              style={inputStyle}
            />
          </div>
          <div style={{ marginBottom: 8 }}>
            <label style={{ display: 'block', marginBottom: 4 }}>Youtube Link</label>
            <input
              type="text"
                value={workingGurbaniItem.youtubeUrl}
                onChange={(e) => setWorkingGurbaniItem({ ...workingGurbaniItem, youtubeUrl: e.target.value })}
              style={inputStyle}
            />
          </div>
          <div style={{ marginBottom: 8 }}>
            <label style={{ display: 'inline-flex', alignItems: 'center' }}>
              <input
                type="checkbox"
                checked={workingGurbaniItem.isThisGurbani}
                onChange={(e) => setWorkingGurbaniItem({ ...workingGurbaniItem, isThisGurbani: e.target.checked })}
                style={{ marginRight: 8 }}
              />
              Is This Gurbani
            </label>
          </div>
          <div style={{ marginBottom: 8 }}>
            <label style={{ display: 'block', marginBottom: 4 }}>Weightage</label>
            <input
              type="number"
              value={workingGurbaniItem.scoreRequirement ?? workingGurbaniItem.weightage ?? ''}
              onChange={(e) => setWorkingGurbaniItem({ ...workingGurbaniItem, scoreRequirement: Number(e.target.value) })}
              style={inputStyle}
            />
          </div>
          <div style={{ marginBottom: 12 }}>
            <label style={{ display: 'inline-flex', alignItems: 'center' }}>
              <input
                type="checkbox"
                checked={workingGurbaniItem.isActive}
                onChange={(e) => setWorkingGurbaniItem({ ...workingGurbaniItem, isActive: e.target.checked })}
                style={{ marginRight: 8 }}
              />
              Active
            </label>
          </div>
          <button onClick={handleSubmit} style={{ ...buttonStyle, marginRight: 8 }}>
            Save
          </button>
          <button onClick={handleCancel} style={buttonStyle}>
            Cancel
          </button>
        </div>
      )}
    </div>
  );
};

export default GurbaniList;
