import React, { useEffect, useState, useRef } from 'react';
import { get, post, put, remove, API_BASE_URL } from '../api';

const emptyPrize = {
  name: '',
  imageUrl: '',
  minimumScore: 0,
  isActive: true,
};

const PrizeList = () => {
  const [prizes, setPrizes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [workingPrize, setWorkingPrize] = useState(emptyPrize);
  const [editingId, setEditingId] = useState(null);
  const [showForm, setShowForm] = useState(false);
  const [actionError, setActionError] = useState(null);
  const [successMessage, setSuccessMessage] = useState(null);
  const [uploadingImage, setUploadingImage] = useState(false);
  const fileInputRef = useRef(null);
  const formRef = useRef(null);

  const loadPrizes = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await get('/api/admin-catalog/prizes');
      setPrizes(response.data);
    } catch (err) {
      console.error(err);
      setError('Unable to load prizes.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadPrizes();
  }, []);

  const handleRefresh = () => {
    loadPrizes();
  };

  const handleEdit = (prize) => {
    setEditingId(prize.id);
    setShowForm(true);
    setWorkingPrize({
      name: prize.name || '',
      imageUrl: prize.imageUrl || '',
      minimumScore: prize.minimumScore ?? prize.price ?? 0,
      isActive: prize.isActive,
    });
    setActionError(null);
    setSuccessMessage(null);
    setTimeout(() => {
      formRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }, 50);
  };

  const handleCreate = () => {
    setEditingId(null);
    setWorkingPrize(emptyPrize);
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
    setWorkingPrize(emptyPrize);
    setActionError(null);
    setSuccessMessage(null);
  };

  const handleSubmit = async () => {
    setActionError(null);
    setSuccessMessage(null);

    const trimmedName = workingPrize.name.trim();
    const trimmedImageUrl = workingPrize.imageUrl.trim();

    if (!trimmedName) {
      setActionError('Prize name is required.');
      return;
    }

    if (!trimmedImageUrl) {
      setActionError('Prize image is required. Please upload an image.');
      return;
    }

    try {
      const payload = {
        ...workingPrize,
        name: trimmedName,
        imageUrl: trimmedImageUrl,
        minimumScore: Number(workingPrize.minimumScore ?? 0),
      };

      if (editingId) {
        await put(`/api/admin-catalog/prizes/${editingId}`, payload);
        setSuccessMessage('Prize updated successfully.');
      } else {
        await post('/api/admin-catalog/prizes', payload);
        setSuccessMessage('Prize created successfully.');
      }
      await loadPrizes();
      setEditingId(null);
      setWorkingPrize(emptyPrize);
      setShowForm(false);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    } catch (err) {
      console.error(err);
      setActionError('Unable to save prize.');
    }
  };

  const handleFileUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file) {
      return;
    }

    const allowedMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (!allowedMimes.includes(file.type)) {
      setActionError('Only JPEG, PNG, GIF, and WebP images are allowed.');
      return;
    }

    const maxFileSize = 5 * 1024 * 1024;
    if (file.size > maxFileSize) {
      setActionError('File size must not exceed 5MB.');
      return;
    }

    setUploadingImage(true);
    setActionError(null);
    setSuccessMessage(null);

    try {
      const formData = new FormData();
      formData.append('file', file);

      const response = await post('/api/prizelist/upload-image', formData);
      if (response?.data?.imageUrl) {
        setWorkingPrize({ ...workingPrize, imageUrl: response.data.imageUrl });
        setSuccessMessage('Image uploaded successfully.');
      } else {
        setActionError('Upload failed: No image URL returned.');
      }
    } catch (err) {
      console.error('Upload error:', err);
      setActionError('Unable to upload image.');
    } finally {
      setUploadingImage(false);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    }
  };

  const normalizeImageUrl = (value) => {
    if (!value) {
      return '';
    }

    try {
      const parsedUrl = new URL(value, API_BASE_URL);
      if (parsedUrl.protocol === 'http:' || parsedUrl.protocol === 'https:') {
        return parsedUrl.toString();
      }
    } catch {
      // Fallback for relative URLs
    }

    if (value.startsWith('/')) {
      return `${API_BASE_URL}${value}`;
    }

    return value;
  };

  const handleDelete = async (id) => {
    setActionError(null);
    setSuccessMessage(null);
    try {
      await remove(`/api/admin-catalog/prizes/${id}`);
      setSuccessMessage('Prize deleted successfully.');
      await loadPrizes();
    } catch (err) {
      console.error(err);
      setActionError('Unable to delete prize.');
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
      {loading && <p>Loading prizes...</p>}
      {error && <p style={{ color: 'red' }}>{error}</p>}
      {!loading && !error && (
        <div style={{ overflowX: 'auto' }}>
          <table style={tableStyle}>
            <thead>
              <tr>
                <th style={headerStyle}>Prize</th>
                <th style={headerStyle}>Price</th>
                <th style={headerStyle}>Image</th>
                <th style={headerStyle}>Active</th>
                <th style={headerStyle}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {prizes.map((prize, index) => (
                <tr key={prize.id} style={{ backgroundColor: index % 2 === 0 ? '#ffffff' : '#f8fafc' }}>
                  <td style={cellStyle}>{prize.name}</td>
                  <td style={cellStyle}>{prize.minimumScore ?? prize.price ?? 0}</td>
                  <td style={cellStyle}>
                    {prize.imageUrl ? (
                      <div>
                        <div style={{ marginBottom: 6 }}>
                          <img
                            src={normalizeImageUrl(prize.imageUrl)}
                            alt={prize.name}
                            style={{ width: 48, height: 48, objectFit: 'cover', borderRadius: 6, border: '1px solid #ddd' }}
                          />
                        </div>
                        <a href={normalizeImageUrl(prize.imageUrl)} target="_blank" rel="noopener noreferrer">
                          Open
                        </a>
                      </div>
                    ) : (
                      'None'
                    )}
                  </td>
                  <td style={cellStyle}>{prize.isActive ? 'Yes' : 'No'}</td>
                  <td style={cellStyle}>
                    <button onClick={() => handleEdit(prize)} style={{ ...buttonStyle, marginRight: 8 }}>
                      Edit
                    </button>
                    <button onClick={() => handleDelete(prize.id)} style={buttonStyle}>
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
          <h3 style={{ marginTop: 0 }}>{editingId ? 'Edit Prize' : 'Add Prize'}</h3>
          <div style={{ marginBottom: 8 }}>
            <label style={{ display: 'block', marginBottom: 4 }}>Prize Name</label>
            <input
              type="text"
              value={workingPrize.name}
              onChange={(e) => setWorkingPrize({ ...workingPrize, name: e.target.value })}
              style={inputStyle}
            />
          </div>
          <div style={{ marginBottom: 8 }}>
            <label style={{ display: 'block', marginBottom: 4 }}>Price</label>
            <input
              type="number"
              min="0"
              value={workingPrize.minimumScore ?? 0}
              onChange={(e) => setWorkingPrize({ ...workingPrize, minimumScore: Number(e.target.value) })}
              style={inputStyle}
            />
          </div>
          <div style={{ marginBottom: 8 }}>
            <label style={{ display: 'block', marginBottom: 4 }}>Prize Image</label>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/jpeg,image/png,image/gif,image/webp"
              onChange={handleFileUpload}
              disabled={uploadingImage}
              style={{ width: '100%', padding: 8 }}
            />
            <div style={{ marginTop: 4, fontSize: 12, color: '#555' }}>
              Upload a JPEG, PNG, GIF, or WebP image (max 5MB). Recommended dimensions: at least 320×320 px, square or near-square.
              This displays best in the Flutter prize grid and helps keep six prizes visible comfortably.
            </div>
          </div>
          {workingPrize.imageUrl.trim() && (
            <div style={{ marginBottom: 12 }}>
              <div style={{ marginBottom: 4, fontSize: 12, color: '#555' }}>Preview</div>
              <img
                src={normalizeImageUrl(workingPrize.imageUrl.trim())}
                alt="Prize preview"
                style={{ width: 150, height: 150, objectFit: 'cover', borderRadius: 8, border: '1px solid #ddd' }}
                onError={(e) => {
                  e.currentTarget.style.display = 'none';
                }}
              />
              {editingId && (
                <div style={{ marginTop: 8 }}>
                  <button
                    type="button"
                    onClick={async () => {
                      const confirmDelete = window.confirm('Remove the uploaded image for this prize?');
                      if (!confirmDelete) {
                        return;
                      }
                      setActionError(null);
                      setSuccessMessage(null);
                      try {
                        await post(`/api/admin-catalog/prizes/${editingId}/remove-image`, {});
                        setWorkingPrize({ ...workingPrize, imageUrl: '' });
                        setSuccessMessage('Image removed successfully.');
                      } catch (err) {
                        console.error(err);
                        setActionError('Unable to remove image.');
                      }
                    }}
                    style={{ background: '#f87171', color: '#fff', border: 'none', padding: '8px 12px', borderRadius: 4, cursor: 'pointer' }}
                  >
                    Clear image
                  </button>
                </div>
              )}
            </div>
          )}
          <div style={{ marginBottom: 12 }}>
            <label style={{ display: 'inline-flex', alignItems: 'center' }}>
              <input
                type="checkbox"
                checked={workingPrize.isActive}
                onChange={(e) => setWorkingPrize({ ...workingPrize, isActive: e.target.checked })}
                style={{ marginRight: 8 }}
              />
              Active
            </label>
          </div>
          <button onClick={handleSubmit} disabled={uploadingImage} style={{ ...buttonStyle, marginRight: 8 }}>
            {uploadingImage ? 'Uploading...' : 'Save'}
          </button>
          <button onClick={handleCancel} style={buttonStyle}>
            Cancel
          </button>
        </div>
      )}
    </div>
  );
};

export default PrizeList;
