import React, { useEffect, useState } from 'react';
import { get } from '../api';

const tableCellStyle = {
  border: '1px solid #ccc',
  padding: '8px',
  verticalAlign: 'top',
};

const preStyle = {
  margin: 0,
  whiteSpace: 'pre-wrap',
  wordBreak: 'break-word',
  fontSize: 12,
  maxWidth: 260,
};

const changeListStyle = {
  display: 'flex',
  flexDirection: 'column',
  gap: 4,
  minWidth: 0,
};

const changeCardStyle = {
  border: '1px solid #e2e8f0',
  borderRadius: 6,
  padding: 6,
  backgroundColor: '#f8fafc',
};

const changeValueStyle = {
  marginTop: 2,
  padding: '4px 6px',
  borderRadius: 4,
  backgroundColor: '#ffffff',
  border: '1px solid #dbe4ee',
  fontSize: 11,
};

const highlightedValueStyle = {
  ...changeValueStyle,
  backgroundColor: '#fef3c7',
  border: '1px solid #fcd34d',
  fontWeight: 500,
  fontSize: 11,
};

const filterLabelStyle = {
  display: 'block',
  marginBottom: 4,
  fontSize: 12,
  fontWeight: 600,
  color: '#374151',
};

const filterInputStyle = {
  width: '100%',
  minHeight: 42,
  padding: '8px 12px',
  border: '1px solid #d1d5db',
  borderRadius: 6,
  fontSize: 13,
  fontFamily: 'inherit',
  boxSizing: 'border-box',
};

const filterSelectStyle = {
  ...filterInputStyle,
};

const filterDateStyle = {
  ...filterInputStyle,
};

const filterFieldContainerStyle = {
  display: 'flex',
  flexDirection: 'column',
  gap: 4,
};

const entityNameLabelMap = {
  All: 'All',
  Submission: 'Submission',
  User: 'Address',
  UserProfile: 'Participants',
  Prize: 'Prize',
  Gurbani: 'Gurbani List',
  Parent: 'Address',
  ChildProfile: 'Participants',
};

const preferredEntityOrder = ['Submission', 'User', 'UserProfile', 'Prize', 'Gurbani', 'Parent', 'ChildProfile'];

const parseJsonObject = (value) => {
  if (!value) {
    return {};
  }

  try {
    const parsed = JSON.parse(value);
    return parsed && typeof parsed === 'object' ? parsed : {};
  } catch {
    return {};
  }
};

const formatLabel = (value) => {
  if (!value) {
    return 'Details';
  }

  return String(value)
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/[_.-]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .replace(/^./, (letter) => letter.toUpperCase());
};

  const formatEntityName = (value) => entityNameLabelMap[value] || formatLabel(value);

const formatValue = (value, fieldName, mappings) => {
  if (value == null || value === '') {
    return 'Empty';
  }

  if (typeof value === 'boolean') {
    return value ? 'Yes' : 'No';
  }

  // Map IDs to names
  if (fieldName === 'prizeId' || fieldName === 'PrizeId') {
    const prize = mappings.prizes.find((g) => g.id === Number(value));
    if (prize) return prize.name;
  }
  if (fieldName === 'gurbaniId' || fieldName === 'GurbaniId') {
    const gurbani = mappings.gurbaniItems.find((r) => r.id === Number(value));
    if (gurbani) return gurbani.title;
  }

  // Map status codes to names
  if (fieldName === 'deliveryStatus' || fieldName === 'DeliveryStatus') {
    const statuses = { 0: 'Pending', 1: 'Dispatched', 2: 'Delivered', 3: 'Returned' };
    return statuses[value] || value;
  }
  if (fieldName === 'whatsAppTestStatus' || fieldName === 'WhatsAppTestStatus' || 
      fieldName === 'whatsAppStatus' || fieldName === 'WhatsAppStatus') {
    const statuses = { 0: 'Pending', 1: 'Passed', 2: 'Postponed' };
    return statuses[value] || value;
  }
  if (fieldName === 'status' || fieldName === 'Status') {
    const statuses = { 0: 'Pending', 1: 'Approved', 2: 'Rejected' };
    return statuses[value] || value;
  }

  if (typeof value === 'object') {
    return JSON.stringify(value);
  }

  return String(value);
};

// Fields to hide from audit logs display (technical/system fields)
const HIDDEN_FIELDS = new Set([
  'updatedAt',
  'UpdatedAt',
  'updated_at',
  'createdAt',
  'CreatedAt',
  'created_at',
  'id',
  'Id',
  'ID',
  'passwordHash',
  'PasswordHash',
  'password_hash',
  'requestPath',
  'RequestPath',
  'request_path',
  'version',
  'Version',
  'concurrencyStamp',
  'ConcurrencyStamp',
  'concurrency_stamp',
]);

const getChangedFields = (log, mappings) => {
  const oldValues = parseJsonObject(log.oldValues);
  const newValues = parseJsonObject(log.newValues);
  const changedColumns = (log.changedColumns || '')
    .split(',')
    .map((column) => column.trim())
    .filter(Boolean);

  const fieldNames = Array.from(new Set([
    ...changedColumns,
    ...Object.keys(oldValues),
    ...Object.keys(newValues),
  ])).filter((fieldName) => !HIDDEN_FIELDS.has(fieldName));

  if (fieldNames.length === 0) {
    return [];
  }

  return fieldNames.map((fieldName) => ({
    fieldName,
    label: formatLabel(fieldName),
    oldValue: formatValue(oldValues[fieldName], fieldName, mappings),
    newValue: formatValue(newValues[fieldName], fieldName, mappings),
    isChanged: JSON.stringify(oldValues[fieldName] ?? null) !== JSON.stringify(newValues[fieldName] ?? null),
  }));
};

const renderChanges = (log, mappings) => {
  const changes = getChangedFields(log, mappings);

  if (changes.length === 0) {
    return <span style={{ color: '#6b7280' }}>No changes to display</span>;
  }

  return (
    <div style={changeListStyle}>
      {changes.map((change) => (
        <div
          key={`${log.id}-${change.fieldName}`}
          style={{
            ...changeCardStyle,
            backgroundColor: change.isChanged ? '#fffef0' : '#fafafa',
            borderLeft: change.isChanged ? '3px solid #f59e0b' : '3px solid #e5e7eb',
          }}
        >
          <div
            style={{
              fontWeight: 600,
              color: change.isChanged ? '#92400e' : '#374151',
              fontSize: 11,
            }}
          >
            {change.label}
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 4, marginTop: 4 }}>
            <div>
              <div style={{ fontSize: 10, color: '#6b7280', fontWeight: 500 }}>Before</div>
              <div style={change.isChanged ? highlightedValueStyle : changeValueStyle}>
                {change.oldValue}
              </div>
            </div>
            <div>
              <div style={{ fontSize: 10, color: '#6b7280', fontWeight: 500 }}>After</div>
              <div style={change.isChanged ? highlightedValueStyle : changeValueStyle}>
                {change.newValue}
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

const AuditLogs = ({ selectedAuditContext }) => {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchText, setSearchText] = useState('');
  const [actorTypeFilter, setActorTypeFilter] = useState('All');
  const [actorNameFilter, setActorNameFilter] = useState('All');
  const [actorNameSearchText, setActorNameSearchText] = useState('');
  const [showUserDropdown, setShowUserDropdown] = useState(false);
  const [entityNameFilter, setEntityNameFilter] = useState('All');
  const [selectedEntityId, setSelectedEntityId] = useState('');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');
  const [prizes, setPrizes] = useState([]);
  const [gurbaniItems, setGurbaniItems] = useState([]);

  const loadLogs = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await get('/api/admin-catalog/audit-logs');
      setLogs(response.data);
    } catch (err) {
      console.error(err);
      setError('Unable to load audit logs.');
    } finally {
      setLoading(false);
    }
  };

  const loadReferenceData = async () => {
    try {
      const prizesRes = await get('/api/admin-catalog/prizes');
      const gurbaniItemsRes = await get('/api/admin-catalog/gurbani-items');
      setPrizes(prizesRes.data || []);
      setGurbaniItems(gurbaniItemsRes.data || []);
    } catch (err) {
      console.error('Failed to load reference data:', err);
    }
  };

  useEffect(() => {
    loadLogs();
    loadReferenceData();
  }, []);

  const actorTypes = ['All', ...new Set(logs.map((log) => log.actorType).filter(Boolean))];
  const actorNames = ['All', ...new Set(logs.map((log) => log.actorName).filter(Boolean))];
  const availableEntityNames = [...new Set(logs.map((log) => log.entityName).filter(Boolean))];
  const orderedEntityNames = [
    ...preferredEntityOrder.filter((entityName) => availableEntityNames.includes(entityName)),
    ...availableEntityNames.filter((entityName) => !preferredEntityOrder.includes(entityName)),
  ];
  const entityNames = ['All', ...orderedEntityNames];

  const mappings = { prizes, gurbaniItems };
  const selectedActorNameLabel = actorNameFilter === 'All' ? '' : actorNameFilter || 'System';

  useEffect(() => {
    if (!selectedAuditContext) {
      return;
    }

    const { entityName, entityId } = selectedAuditContext;
    setEntityNameFilter(entityName || 'All');
    setSelectedEntityId(entityId ? String(entityId) : '');
    setSearchText('');
  }, [selectedAuditContext]);

  const filteredLogs = logs.filter((log) => {
    const query = searchText.trim().toLowerCase();
    const haystack = [
      log.entityName,
      log.entityId,
      log.action,
      log.actorType,
      log.actorId,
      log.actorName,
      log.changedColumns,
      log.oldValues,
      log.newValues,
    ]
      .filter(Boolean)
      .join(' ')
      .toLowerCase();

    const matchesSearch = !query || haystack.includes(query);
    const matchesActorType = actorTypeFilter === 'All' || log.actorType === actorTypeFilter;
    const matchesActorName = actorNameFilter === 'All' || log.actorName === actorNameFilter;
    const matchesEntityName = entityNameFilter === 'All' || log.entityName === entityNameFilter;
    const matchesEntityId = !selectedEntityId || String(log.entityId) === selectedEntityId;

    const createdAt = new Date(log.createdAt);
    const matchesFromDate = !fromDate || createdAt >= new Date(`${fromDate}T00:00:00`);
    const matchesToDate = !toDate || createdAt <= new Date(`${toDate}T23:59:59.999`);

    return matchesSearch && matchesActorType && matchesActorName && matchesEntityName && matchesEntityId && matchesFromDate && matchesToDate;
  });

  return (
    <div>
      <div style={{ marginBottom: 12 }}>
        <button onClick={loadLogs} disabled={loading}>
          Refresh
        </button>
      </div>
      <div style={{ marginBottom: 16 }}>
        {selectedAuditContext && (
          <div
            style={{
              marginBottom: 16,
              padding: '14px 18px',
              borderRadius: 10,
              backgroundColor: '#eff6ff',
              border: '1px solid #93c5fd',
              color: '#0c4a6e',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
            }}
          >
            <div>
              Viewing audit logs for: <strong>{selectedAuditContext.entityName} #{selectedAuditContext.entityId}</strong>
              {selectedAuditContext.participantName && (
                <div style={{ marginTop: 4, fontSize: 13 }}>
                  {selectedAuditContext.participantName} • {selectedAuditContext.phoneNumber || 'N/A'}
                </div>
              )}
            </div>
            <button
              type="button"
              onClick={() => {
                setEntityNameFilter('All');
                setSelectedEntityId('');
                setSearchText('');
              }}
              style={{
                background: '#ffffff',
                border: '1px solid #93c5fd',
                borderRadius: 6,
                color: '#1d4ed8',
                padding: '8px 12px',
                cursor: 'pointer',
              }}
            >
              Clear selection
            </button>
          </div>
        )}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(6, 1fr)', gap: 20, alignItems: 'end' }}>
          <div style={filterFieldContainerStyle}>
            <label style={filterLabelStyle}>Search</label>
            <input
              type="text"
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              placeholder="Search audit logs"
              style={filterInputStyle}
            />
          </div>
          <div style={filterFieldContainerStyle}>
            <label style={filterLabelStyle}>Actor Type</label>
            <select value={actorTypeFilter} onChange={(e) => setActorTypeFilter(e.target.value)} style={filterSelectStyle}>
              {actorTypes.map((actorType) => (
                <option key={actorType} value={actorType}>
                  {actorType}
                </option>
              ))}
            </select>
          </div>
          <div style={filterFieldContainerStyle}>
            <label style={filterLabelStyle}>User</label>
            <div style={{ position: 'relative' }}>
              <input
                type="text"
                value={actorNameSearchText || selectedActorNameLabel}
                onChange={(e) => {
                  setActorNameSearchText(e.target.value);
                  setShowUserDropdown(true);
                }}
                onFocus={() => setShowUserDropdown(true)}
                onBlur={() => {
                  setTimeout(() => {
                    setActorNameSearchText('');
                    setShowUserDropdown(false);
                  }, 200);
                }}
                placeholder="Search users..."
                style={filterInputStyle}
              />
              {showUserDropdown && (
                <div
                  style={{
                    position: 'absolute',
                    top: '100%',
                    left: 0,
                    right: 0,
                    backgroundColor: '#fff',
                    border: '1px solid #d1d5db',
                    borderTop: 'none',
                    borderRadius: '0 0 6px 6px',
                    maxHeight: '200px',
                    overflowY: 'auto',
                    zIndex: 1000,
                    boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
                  }}
                >
                  {actorNames
                    .filter(
                      (name) =>
                        name === 'All' ||
                        (name || 'System')
                          .toLowerCase()
                          .includes(actorNameSearchText.toLowerCase()),
                    )
                    .map((actorName) => (
                      <div
                        key={actorName}
                        onMouseDown={(e) => {
                          e.preventDefault();
                          setActorNameFilter(actorName);
                          setActorNameSearchText(actorName === 'All' ? '' : actorName || 'System');
                          setShowUserDropdown(false);
                        }}
                        style={{
                          padding: '10px 12px',
                          cursor: 'pointer',
                          backgroundColor:
                            actorNameFilter === actorName ? '#e3f2fd' : '#fff',
                          color: actorNameFilter === actorName ? '#1976d2' : '#000',
                          fontWeight:
                            actorNameFilter === actorName ? '600' : 'normal',
                          fontSize: '13px',
                          borderBottom: '1px solid #f0f0f0',
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.backgroundColor = '#f5f5f5';
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.backgroundColor =
                            actorNameFilter === actorName ? '#e3f2fd' : '#fff';
                        }}
                      >
                        {actorName || 'System'}
                      </div>
                    ))}
                </div>
              )}
            </div>
          </div>
          <div style={filterFieldContainerStyle}>
            <label style={filterLabelStyle}>Entity Name</label>
            <select value={entityNameFilter} onChange={(e) => setEntityNameFilter(e.target.value)} style={filterSelectStyle}>
              {entityNames.map((entityName) => (
                <option key={entityName} value={entityName}>
                  {formatEntityName(entityName)}
                </option>
              ))}
            </select>
          </div>
          <div style={filterFieldContainerStyle}>
            <label style={filterLabelStyle}>From Date</label>
            <input type="date" value={fromDate} onChange={(e) => setFromDate(e.target.value)} style={filterDateStyle} />
          </div>
          <div style={filterFieldContainerStyle}>
            <label style={filterLabelStyle}>To Date</label>
            <input type="date" value={toDate} onChange={(e) => setToDate(e.target.value)} style={filterDateStyle} />
          </div>
        </div>
      </div>
      {loading && <p>Loading audit logs...</p>}
      {error && <p style={{ color: 'red' }}>{error}</p>}
      {!loading && !error && filteredLogs.length === 0 && <p>No audit logs found.</p>}
      {!loading && !error && filteredLogs.length > 0 && (
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr>
                <th style={tableCellStyle}>When</th>
                <th style={tableCellStyle}>What Changed</th>
                <th style={tableCellStyle}>Action</th>
                <th style={tableCellStyle}>Done By</th>
                <th style={tableCellStyle}>Changed Details</th>
              </tr>
            </thead>
            <tbody>
              {filteredLogs.map((log) => (
                <tr key={log.id}>
                  <td style={tableCellStyle}>{new Date(log.createdAt).toLocaleString()}</td>
                  <td style={tableCellStyle}>
                    <div style={{ fontWeight: 600 }}>{formatLabel(log.entityName)}</div>
                    <div style={{ marginTop: 4, color: '#475569', fontSize: 13 }}>
                      {log.entityId ? `Record #${log.entityId}` : 'Record updated'}
                    </div>
                  </td>
                  <td style={tableCellStyle}>{log.action}</td>
                  <td style={tableCellStyle}>
                    <div style={{ fontWeight: 600 }}>{log.actorName || log.actorId || 'System'}</div>
                    <div style={{ marginTop: 4, color: '#475569', fontSize: 13 }}>{formatLabel(log.actorType)}</div>
                  </td>
                  <td style={tableCellStyle}>{renderChanges(log, mappings)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default AuditLogs;
