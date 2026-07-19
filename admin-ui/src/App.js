import React, { useEffect, useState } from 'react';
import PendingSubmissions from './pages/PendingSubmissions';
import GurbaniList from './pages/GurbaniList';
import PrizeList from './pages/PrizeList';
import UsersList from './pages/UsersList';
import AddressesList from './pages/AddressesList';
import AuditLogs from './pages/AuditLogs';

const ACTIVE_PAGE_KEY = 'ginj-admin-active-page';

const allowedPageIds = new Set(['pending', 'gurbani', 'prizes', 'users', 'addresses', 'auditLogs']);

function App() {
  const [currentPage, setCurrentPage] = useState(() => {
    const storedPage = localStorage.getItem(ACTIVE_PAGE_KEY);
    return allowedPageIds.has(storedPage) ? storedPage : 'pending';
  });
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [selectedAuditContext, setSelectedAuditContext] = useState(null);

  useEffect(() => {
    localStorage.setItem(ACTIVE_PAGE_KEY, currentPage);
  }, [currentPage]);

  const handleViewSubmissionAudits = (context) => {
    setSelectedAuditContext(context);
    setCurrentPage('auditLogs');
  };

  const menuItems = [
    { id: 'pending', label: 'Applications', icon: '📋' },
    { id: 'gurbani', label: 'Gurbani List', icon: '🎵' },
    { id: 'prizes', label: 'Prize List', icon: '🎁' },
    { id: 'users', label: 'Participants', icon: '👥' },
    { id: 'addresses', label: 'Participant Address List', icon: '🏠' },
    { id: 'auditLogs', label: 'Audit Logs', icon: '📊' },
  ];

  const getPageTitle = () => {
    const item = menuItems.find((m) => m.id === currentPage);
    return item ? item.label : 'GINJ Admin';
  };

  const toggleSidebar = () => {
    setIsSidebarOpen((prev) => !prev);
  };

  return (
    <div style={{ display: 'flex', fontFamily: 'Arial, sans-serif', minHeight: '100vh', backgroundColor: '#f9fafb' }}>
      <div
        style={{
          width: isSidebarOpen ? '220px' : '72px',
          backgroundColor: '#1e3a8a',
          color: 'white',
          padding: '24px 0',
          boxShadow: '2px 0 8px rgba(0,0,0,0.1)',
          minHeight: '100vh',
          transition: 'width 0.2s ease',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: isSidebarOpen ? 'space-between' : 'center', padding: '0 16px 24px', gap: 8 }}>
          {isSidebarOpen ? <h2 style={{ margin: 0, fontSize: '18px', fontWeight: '600' }}>GINJ Admin</h2> : <div style={{ width: 24 }} />}
          <button
            onClick={toggleSidebar}
            title={isSidebarOpen ? 'Collapse menu' : 'Expand menu'}
            style={{
              background: 'transparent',
              color: 'white',
              border: '1px solid rgba(255,255,255,0.25)',
              borderRadius: 6,
              width: 34,
              height: 34,
              cursor: 'pointer',
              fontSize: 16,
            }}
          >
            ☰
          </button>
        </div>
        <nav>
          {menuItems.map((item) => (
            <button
              key={item.id}
              onClick={() => setCurrentPage(item.id)}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: isSidebarOpen ? 'flex-start' : 'center',
                width: '100%',
                padding: isSidebarOpen ? '12px 16px' : '12px 0',
                border: 'none',
                backgroundColor: currentPage === item.id ? '#3b82f6' : 'transparent',
                color: 'white',
                textAlign: 'left',
                cursor: 'pointer',
                fontSize: '14px',
                fontWeight: currentPage === item.id ? '600' : '500',
                transition: 'background-color 0.2s',
              }}
              onMouseEnter={(e) => {
                e.target.style.backgroundColor = currentPage === item.id ? '#3b82f6' : '#1e5a96';
              }}
              onMouseLeave={(e) => {
                e.target.style.backgroundColor = currentPage === item.id ? '#3b82f6' : 'transparent';
              }}
            >
              <span style={{ marginRight: isSidebarOpen ? '8px' : 0, display: 'inline-flex', justifyContent: 'center', width: isSidebarOpen ? 'auto' : '100%' }}>{item.icon}</span>
              {isSidebarOpen && item.label}
            </button>
          ))}
        </nav>
      </div>

      <div style={{ flex: 1, padding: '24px', overflowY: 'auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: '24px' }}>
          {!isSidebarOpen && (
            <button
              onClick={toggleSidebar}
              style={{
                background: '#ffffff',
                border: '1px solid #cbd5e1',
                borderRadius: 6,
                width: 36,
                height: 36,
                cursor: 'pointer',
              }}
              title="Open menu"
            >
              ☰
            </button>
          )}
          <h1 style={{ margin: 0, color: '#1f2937' }}>{getPageTitle()}</h1>
        </div>
        {currentPage === 'pending' && <PendingSubmissions onViewSubmissionAudits={handleViewSubmissionAudits} />}
        {currentPage === 'gurbani' && <GurbaniList />}
        {currentPage === 'prizes' && <PrizeList />}
        {currentPage === 'users' && <UsersList />}
        {currentPage === 'addresses' && <AddressesList />}
        {currentPage === 'auditLogs' && <AuditLogs selectedAuditContext={selectedAuditContext} />}
      </div>
    </div>
  );
}

export default App;
