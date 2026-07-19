import React, { useEffect, useState } from 'react';
import { get, put } from '../api';

const PendingSubmissions = ({ onViewSubmissionAudits }) => {
  const [submissions, setSubmissions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [actionLoading, setActionLoading] = useState(false);
  const [actionError, setActionError] = useState(null);
  const [successMessage, setSuccessMessage] = useState(null);
  const [historyByUserProfile, setHistoryByUserProfile] = useState({});
  const [openHistoryFor, setOpenHistoryFor] = useState([]); // array of userProfileId currently expanded
  const [editValues, setEditValues] = useState({});
  const [whatsAppFilter, setWhatsAppFilter] = useState('All');
  const [dispatchFilter, setDispatchFilter] = useState('All');
  const [searchText, setSearchText] = useState('');

  const getUser = (submission) => submission.user || submission.parent;
  const getUserProfile = (submission) => submission.userProfile || submission.childProfile;
  const getGurbani = (submission) => submission.gurbani;
  const getPrize = (submission) => submission.prize;

  const loadSubmissions = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await get('/api/admin/pending-submissions');
      setSubmissions(response.data);
      const values = {};
      response.data.forEach((submission) => {
        const userProfile = getUserProfile(submission);
        values[submission.id] = {
          whatsAppTestStatus: submission.whatsAppTestStatus || 'Pending',
          reviewNotes: submission.reviewNotes || '',
          dispatchStatus: submission.dispatch?.deliveryStatus || 'Pending',
          docketNumber: submission.dispatch?.docketNumber || '',
          userProfileId: userProfile?.id,
        };
      });
      setEditValues(values);
    } catch (err) {
      console.error(err);
      setError('Unable to fetch pending submissions.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSubmissions();
  }, []);

  const handleDispatchUpdate = async (submissionId, dispatchStatus, docketNumber) => {
    setActionLoading(true);
    setActionError(null);
    setSuccessMessage(null);

    try {
      await put(`/api/admin/dispatch/${submissionId}`, {
        docketNumber,
        deliveryStatus: dispatchStatus,
      });
      setSuccessMessage(`Submission ${submissionId} updated successfully.`);
      await loadSubmissions();
    } catch (err) {
      console.error(err);
      setActionError('Unable to update dispatch information.');
    } finally {
      setActionLoading(false);
    }
  };

  const handleReviewNotesUpdate = async (submissionId, whatsAppStatus, reviewNotes) => {
    setActionLoading(true);
    setActionError(null);
    setSuccessMessage(null);

    try {
      await put('/api/admin/review', {
        submissionId,
        submissionStatus: 'Pending',
        whatsAppTestStatus: whatsAppStatus,
        reviewNotes,
      });
      setSuccessMessage(`Submission ${submissionId} review updated successfully.`);
      await loadSubmissions();
    } catch (err) {
      console.error(err);
      setActionError('Unable to update review notes.');
    } finally {
      setActionLoading(false);
    }
  };

  const updateEditValue = (submissionId, field, value) => {
    setEditValues((prev) => ({
      ...prev,
      [submissionId]: {
        ...prev[submissionId],
        [field]: value,
      },
    }));
  };

  const handleWhatsAppChange = async (submissionId, value) => {
    updateEditValue(submissionId, 'whatsAppTestStatus', value);
    const current = editValues[submissionId] || {};
    await handleReviewNotesUpdate(submissionId, value, current.reviewNotes || '');
  };

  const handleReviewNotesBlur = async (submissionId, value) => {
    updateEditValue(submissionId, 'reviewNotes', value);
    const current = editValues[submissionId] || {};
    await handleReviewNotesUpdate(submissionId, current.whatsAppTestStatus || 'Pending', value);
  };

  const handleDispatchStatusChange = async (submissionId, value) => {
    updateEditValue(submissionId, 'dispatchStatus', value);
    const current = editValues[submissionId] || {};
    await handleDispatchUpdate(submissionId, value, current.docketNumber || '');
  };

  const handleDocketBlur = async (submissionId, value) => {
    updateEditValue(submissionId, 'docketNumber', value);
    const current = editValues[submissionId] || {};
    await handleDispatchUpdate(submissionId, current.dispatchStatus || 'Pending', value);
  };

  const renderUserInfo = (submission) => {
    const user = getUser(submission);
    if (!user) {
      return 'Unknown';
    }
    return user.phone
      ? `${user.phone} #${user.id}`
      : `#${user.id}`;
  };

  const handleToggleHistory = async (userProfileId) => {
    if (!userProfileId) return;
    setActionError(null);
    setSuccessMessage(null);

    const isOpen = openHistoryFor.includes(userProfileId);
    if (isOpen) {
      setOpenHistoryFor((prev) => prev.filter((id) => id !== userProfileId));
      return;
    }

    // open - fetch if not cached
    if (!historyByUserProfile[userProfileId]) {
      setActionLoading(true);
      try {
        const response = await get(`/api/admin/submission-history/${userProfileId}`);
        setHistoryByUserProfile((prev) => ({ ...prev, [userProfileId]: response.data }));
      } catch (err) {
        console.error(err);
        setActionError('Unable to load submission history.');
        setActionLoading(false);
        return;
      } finally {
        setActionLoading(false);
      }
    }

    setOpenHistoryFor((prev) => [...prev, userProfileId]);
  };

  const handleRefresh = () => {
    loadSubmissions();
  };

  const handleResetFilters = () => {
    setWhatsAppFilter('All');
    setDispatchFilter('All');
    setSearchText('');
  };

  const handleViewSubmissionAudits = (submission) => {
    const entityName = 'Submission';
    const entityId = submission.id;
    const userProfile = getUserProfile(submission);
    const user = getUser(submission);
    const participantName = userProfile?.name || user?.name || 'Unknown';
    const phoneNumber = user?.phone || 'N/A';

    if (typeof window !== 'undefined' && window.location) {
      window.location.hash = `#audit-${entityName}-${entityId}`;
    }
    if (onViewSubmissionAudits) {
      onViewSubmissionAudits({ entityName, entityId, participantName, phoneNumber });
    }
  };

  const getWhatsAppStatus = (submission) => editValues[submission.id]?.whatsAppTestStatus || submission.whatsAppTestStatus || 'Pending';

  const getDispatchStatus = (submission) => editValues[submission.id]?.dispatchStatus || submission.dispatch?.deliveryStatus || 'Pending';

  const getDocketNumber = (submission) => editValues[submission.id]?.docketNumber ?? submission.dispatch?.docketNumber ?? '';

  const renderHighlightedText = (value) => {
    const text = value == null ? '' : String(value);
    const query = searchText.trim();

    if (!query) {
      return text;
    }

    const lowerText = text.toLowerCase();
    const lowerQuery = query.toLowerCase();
    const parts = [];
    let startIndex = 0;
    let matchIndex = lowerText.indexOf(lowerQuery, startIndex);

    while (matchIndex !== -1) {
      if (matchIndex > startIndex) {
        parts.push(text.slice(startIndex, matchIndex));
      }

      parts.push(
        <mark key={`${matchIndex}-${parts.length}`} style={{ backgroundColor: '#ffe08a', padding: '0 2px' }}>
          {text.slice(matchIndex, matchIndex + query.length)}
        </mark>,
      );

      startIndex = matchIndex + query.length;
      matchIndex = lowerText.indexOf(lowerQuery, startIndex);
    }

    if (startIndex < text.length) {
      parts.push(text.slice(startIndex));
    }

    return parts.length > 0 ? parts : text;
  };

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
    minWidth: 1040,
    borderCollapse: 'collapse',
    fontSize: 14,
    color: '#111827',
  };

  const headerStyle = {
    background: '#f8fafc',
    borderBottom: '2px solid #cbd5e1',
    padding: '12px 10px',
    textAlign: 'left',
    fontWeight: 600,
    fontSize: 13,
    color: '#0f172a',
  };

  const historyHeaderStyle = {
    ...headerStyle,
    background: '#86efac',
    color: '#064e3b',
    borderBottom: '1px solid #34d399',
  };

  const historyTextStyle = {
    color: '#065f46',
    margin: 0,
    fontWeight: 600,
  };

  const cellStyle = {
    borderBottom: '1px solid #e2e8f0',
    padding: '10px',
    verticalAlign: 'top',
    whiteSpace: 'normal',
  };

  const idCellStyle = {
    width: 52,
    minWidth: 52,
    whiteSpace: 'nowrap',
    textAlign: 'center',
  };

  const buttonStyle = {
    padding: '8px 14px',
    borderRadius: 5,
    border: '1px solid #cbd5e1',
    background: '#ffffff',
    cursor: 'pointer',
  };

  const statusLegendItems = [
    { label: 'Pending', color: '#fde68a' },
    { label: 'Returned', color: '#ff2c2c' },
    { label: 'Passed / Dispatched', color: '#FFC0CB' },
    { label: 'Delivered', color: '#4ade80' },
  ];

  const getHistoryButtonStyle = (whatsAppStatus, dispatchStatus) => {
    const baseStyle = {
      ...buttonStyle,
      color: '#0f172a',
      fontWeight: 600,
    };

    if (dispatchStatus === 'Delivered') {
      return {
        ...baseStyle,
        background: '#4ade80',
        borderColor: '#16a34a',
      };
    }

    if (dispatchStatus === 'Returned') {
      return {
        ...baseStyle,
        background: '#ff2c2c',
        borderColor: '#cc1f1f',
        color: '#ffffff',
      };
    }

    if (whatsAppStatus === 'Passed' || dispatchStatus === 'Dispatched') {
      return {
        ...baseStyle,
        background: '#FFC0CB',
        borderColor: '#ff8fa3',
      };
    }

    return {
      ...baseStyle,
      background: '#fde68a',
      borderColor: '#fbbf24',
    };
  };

  const inputStyle = {
    width: '100%',
    minHeight: 42,
    padding: '8px 12px',
    border: '1px solid #d1d5db',
    borderRadius: 6,
    fontSize: 13,
    boxSizing: 'border-box',
  };

  const filterLabelStyle = {
    display: 'block',
    marginBottom: 4,
    fontSize: 12,
    fontWeight: 600,
    color: '#374151',
  };

  const filterFieldContainerStyle = {
    display: 'flex',
    flexDirection: 'column',
    gap: 4,
    minWidth: 180,
  };

  const filteredSubmissions = submissions.filter((submission) => {
    const whatsAppStatus = getWhatsAppStatus(submission);
    const dispatchStatus = getDispatchStatus(submission);

    const matchesWhatsApp = whatsAppFilter === 'All' || whatsAppStatus === whatsAppFilter;
    const matchesDispatch = dispatchFilter === 'All' || dispatchStatus === dispatchFilter;

    const searchableText = [
      submission.id,
      renderUserInfo(submission),
      getUserProfile(submission)?.name,
      submission.address,
      getGurbani(submission)?.title,
      getPrize(submission)?.name,
      whatsAppStatus,
      submission.reviewNotes,
      dispatchStatus,
      getDocketNumber(submission),
    ]
      .filter(Boolean)
      .join(' ')
      .toLowerCase();

    const matchesSearch = searchableText.includes(searchText.trim().toLowerCase());

    return matchesWhatsApp && matchesDispatch && matchesSearch;
  });

  return (
    <div>
      <div
        style={{
          marginBottom: 12,
          display: 'flex',
          flexWrap: 'wrap',
          gap: 8,
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          <button onClick={handleRefresh} disabled={loading} style={buttonStyle}>
            Refresh
          </button>
          <button onClick={handleResetFilters} style={buttonStyle}>
            Reset Filters
          </button>
        </div>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>
          {statusLegendItems.map((item) => (
            <div
              key={item.label}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 6,
                padding: '6px 10px',
                borderRadius: 999,
                background: '#f8fafc',
                border: '1px solid #e2e8f0',
                fontSize: 12,
                color: '#0f172a',
              }}
            >
              <span
                style={{
                  width: 12,
                  height: 12,
                  borderRadius: '50%',
                  backgroundColor: item.color,
                  display: 'inline-block',
                  boxShadow: '0 0 0 1px rgba(0,0,0,0.08)',
                }}
              />
              <span>{item.label}</span>
            </div>
          ))}
        </div>
      </div>

      <div style={{ display: 'flex', gap: 20, flexWrap: 'wrap', marginBottom: 16, alignItems: 'end' }}>
        <div style={filterFieldContainerStyle}>
          <label style={filterLabelStyle}>WhatsApp Status</label>
          <select value={whatsAppFilter} onChange={(e) => setWhatsAppFilter(e.target.value)} style={inputStyle}>
            <option value="All">All</option>
            <option value="Pending">Pending</option>
            <option value="Passed">Passed</option>
            <option value="Postponed">Postponed</option>
          </select>
        </div>
        <div style={filterFieldContainerStyle}>
          <label style={filterLabelStyle}>Dispatch Status</label>
          <select value={dispatchFilter} onChange={(e) => setDispatchFilter(e.target.value)} style={inputStyle}>
            <option value="All">All</option>
            <option value="Pending">Pending</option>
            <option value="Dispatched">Dispatched</option>
            <option value="Delivered">Delivered</option>
            <option value="Returned">Returned</option>
          </select>
        </div>
        <div style={{ ...filterFieldContainerStyle, minWidth: 260, flex: '1 1 260px' }}>
          <label style={filterLabelStyle}>Search</label>
          <input
            type="text"
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            placeholder="Search whole grid"
            style={inputStyle}
          />
        </div>
      </div>

      {loading && <p>Loading submissions...</p>}
      {error && <p style={{ color: 'red' }}>{error}</p>}
      {!loading && !error && submissions.length === 0 && <p>No pending submissions.</p>}
      {!loading && !error && submissions.length > 0 && filteredSubmissions.length === 0 && (
        <p>No matching submissions.</p>
      )}
      {successMessage && <p style={{ color: 'green' }}>{successMessage}</p>}
      {actionError && <p style={{ color: 'red' }}>{actionError}</p>}

      {!loading && !error && filteredSubmissions.length > 0 && (
        <div style={{ overflowX: 'auto' }}>
          <table style={tableStyle}>
            <thead>
              <tr>
                <th style={{ ...headerStyle, ...idCellStyle }}>Id</th>
                <th style={headerStyle}>User</th>
                <th style={headerStyle}>Participant</th>
                <th style={headerStyle}>Age</th>
                <th style={headerStyle}>Sex</th>
                <th style={headerStyle}>Address</th>
                <th style={headerStyle}>Gurbani/Jiwani/History</th>
                <th style={headerStyle}>Prize</th>
                <th style={headerStyle}>Review Notes</th>
                <th style={headerStyle}>Docket</th>
                <th style={headerStyle}>WhatsApp Status</th>
                <th style={headerStyle}>Dispatch Status</th>
                <th style={headerStyle}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredSubmissions.map((submission, index) => {
                const userProfileId = getUserProfile(submission)?.id;
                const isOpen = userProfileId ? openHistoryFor.includes(userProfileId) : false;
                const historyList = userProfileId ? historyByUserProfile[userProfileId] || [] : [];
                const visibleHistoryList = historyList.filter((item) => String(item.id) !== String(submission.id));

                return (
                  <React.Fragment key={submission.id}>
                    <tr
                      style={{
                        backgroundColor: index % 2 === 0 ? '#ffffff' : '#f8fafc',
                      }}
                    >
                      <td style={{ ...cellStyle, ...idCellStyle }}>{renderHighlightedText(submission.id)}</td>
                      <td style={cellStyle}>{renderHighlightedText(renderUserInfo(submission))}</td>
                      <td style={cellStyle}>{renderHighlightedText(getUserProfile(submission)?.name || 'Unknown')}</td>
                      <td style={cellStyle}>{calculateAge(getUserProfile(submission)?.dateOfBirth)}</td>
                      <td style={cellStyle}>{getUserProfile(submission)?.sex || '-'}</td>
                      <td style={cellStyle}>{renderHighlightedText(submission.address || 'Unknown')}</td>
                      <td style={cellStyle}>{renderHighlightedText(getGurbani(submission)?.title || 'Unknown')}</td>
                      <td style={cellStyle}>{renderHighlightedText(getPrize(submission)?.name || 'Unknown')}</td>
                      <td style={cellStyle}>
                        <textarea
                          value={editValues[submission.id]?.reviewNotes ?? submission.reviewNotes ?? ''}
                          onChange={(e) => updateEditValue(submission.id, 'reviewNotes', e.target.value)}
                          onBlur={(e) => handleReviewNotesBlur(submission.id, e.target.value)}
                          disabled={actionLoading}
                          rows={2}
                          style={{ width: '100%', minHeight: 58, borderRadius: 4, border: '1px solid #d1d5db', padding: 8 }}
                        />
                      </td>
                      <td style={cellStyle}>
                        <input
                          value={getDocketNumber(submission)}
                          onChange={(e) => updateEditValue(submission.id, 'docketNumber', e.target.value)}
                          onBlur={(e) => handleDocketBlur(submission.id, e.target.value)}
                          disabled={actionLoading}
                          style={inputStyle}
                        />
                      </td>
                      <td style={cellStyle}>
                        <select
                          value={getWhatsAppStatus(submission)}
                          onChange={(e) => handleWhatsAppChange(submission.id, e.target.value)}
                          disabled={actionLoading}
                          style={inputStyle}
                        >
                          <option value="Pending">Pending</option>
                          <option value="Passed">Passed</option>
                          <option value="Postponed">Postponed</option>
                        </select>
                      </td>
                      <td style={cellStyle}>
                        <select
                          value={getDispatchStatus(submission)}
                          onChange={(e) => handleDispatchStatusChange(submission.id, e.target.value)}
                          disabled={actionLoading}
                          style={inputStyle}
                        >
                          <option value="Pending">Pending</option>
                          <option value="Dispatched">Dispatched</option>
                          <option value="Delivered">Delivered</option>
                          <option value="Returned">Returned</option>
                        </select>
                      </td>
                      <td style={cellStyle}>
                        <button
                          disabled={actionLoading || !getUserProfile(submission)?.id}
                          onClick={() => handleToggleHistory(getUserProfile(submission)?.id)}
                          style={getHistoryButtonStyle(
                          getWhatsAppStatus(submission),
                          getDispatchStatus(submission),
                        )}
                        >
                          {isOpen ? 'Hide' : 'History'}
                        </button>
                        <button
                          disabled={actionLoading}
                          onClick={() => handleViewSubmissionAudits(submission)}
                          style={{
                            ...buttonStyle,
                            marginLeft: 8,
                            background: '#eff6ff',
                            borderColor: '#93c5fd',
                            color: '#1d4ed8',
                          }}
                        >
                          Audit
                        </button>
                      </td>
                    </tr>

                    {userProfileId && isOpen && (
                      <tr style={{ backgroundColor: '#bbf7d0' }}>
                        <td colSpan={13} style={{ padding: 12 }}>
                          {actionLoading && !historyByUserProfile[userProfileId] ? (
                            <p style={historyTextStyle}>Loading history...</p>
                          ) : visibleHistoryList.length === 0 ? (
                            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 72 }}>
                              <p style={historyTextStyle}>No history available.</p>
                            </div>
                          ) : (
                            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                              <thead>
                                <tr>
                                  <th style={{ ...historyHeaderStyle, ...idCellStyle }}>Id</th>
                                  <th style={historyHeaderStyle}>Gurbani</th>
                                  <th style={historyHeaderStyle}>Prize</th>
                                  <th style={historyHeaderStyle}>Address</th>
                                  <th style={historyHeaderStyle}>Status</th>
                                  <th style={historyHeaderStyle}>Dispatch</th>
                                  <th style={historyHeaderStyle}>Docket</th>
                                  <th style={historyHeaderStyle}>Created At</th>
                                </tr>
                              </thead>
                              <tbody>
                                {visibleHistoryList.map((item, hindex) => (
                                  <tr key={`${userProfileId}-hist-${item.id}`} style={{ backgroundColor: hindex % 2 === 0 ? '#dcfce7' : '#86efac' }}>
                                    <td style={{ ...cellStyle, ...idCellStyle }}>{renderHighlightedText(item.id)}</td>
                                    <td style={cellStyle}>{renderHighlightedText(item.gurbani || 'Unknown')}</td>
                                    <td style={cellStyle}>{renderHighlightedText(item.prize || 'Unknown')}</td>
                                    <td style={cellStyle}>{renderHighlightedText(item.address || 'Unknown')}</td>
                                    <td style={cellStyle}>{renderHighlightedText(item.status)}</td>
                                    <td style={cellStyle}>{renderHighlightedText(item.dispatchStatus)}</td>
                                    <td style={cellStyle}>{renderHighlightedText(item.docket || 'None')}</td>
                                    <td style={cellStyle}>{renderHighlightedText(new Date(item.createdAt).toLocaleString())}</td>
                                  </tr>
                                ))}
                              </tbody>
                            </table>
                          )}
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      
    </div>
  );
};

export default PendingSubmissions;
