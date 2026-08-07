import React, { useState, useEffect } from 'react';
import Header from './components/Header';
import SystemHealth from './components/SystemHealth';
import HierarchyTree from './components/HierarchyTree';
import BranchStatus from './components/BranchStatus';

export default function App() {
  const [healthData, setHealthData] = useState(null);
  const [hierarchyData, setHierarchyData] = useState(null);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [notification, setNotification] = useState(null);

  const fetchData = async () => {
    setIsRefreshing(true);
    try {
      // 1. Fetch Health Data
      const healthRes = await fetch('/api/health-full');
      if (healthRes.ok) {
        const hJson = await healthRes.json();
        setHealthData(hJson);
      }

      // 2. Fetch Hierarchy Data
      const hierRes = await fetch('/api/hierarchy');
      if (hierRes.ok) {
        const treeJson = await hierRes.json();
        if (treeJson.success) {
          setHierarchyData(treeJson.data);
        }
      }
    } catch (err) {
      console.warn('Backend API erişim simülasyonu çalışıyor:', err.message);
    } finally {
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleSendSms = async (student, parent) => {
    try {
      const res = await fetch('/api/sms/send-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          phone: parent.phone || '+905320000000',
          role: 'PARENT',
        }),
      });

      const data = await res.json();
      showToast(`📱 SMS Gönderildi: ${student.name} için ${parent.name} velisine bildirim iletildi!`);
      
      // Update SMS status in hierarchy UI
      if (hierarchyData) {
        const updatedNodes = hierarchyData.nodes.map((node) => ({
          ...node,
          students: node.students.map((s) =>
            s.id === student.id
              ? {
                  ...s,
                  parent: {
                    ...s.parent,
                    smsStatus: 'sent',
                    smsStatusText: '✅ SMS Başarıyla İletildi',
                  },
                }
              : s
          ),
        }));
        setHierarchyData({ ...hierarchyData, nodes: updatedNodes });
      }
    } catch (err) {
      showToast(`❌ SMS Hatası: ${err.message}`, 'error');
    }
  };

  const showToast = (message, type = 'success') => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), 4000);
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <Header onRefresh={fetchData} isRefreshing={isRefreshing} />

      {notification && (
        <div style={{
          position: 'fixed',
          top: '80px',
          right: '24px',
          zIndex: 1000,
          background: notification.type === 'error' ? 'rgba(244, 63, 94, 0.9)' : 'rgba(16, 185, 129, 0.9)',
          color: '#fff',
          padding: '0.85rem 1.25rem',
          borderRadius: '12px',
          boxShadow: '0 10px 25px rgba(0,0,0,0.4)',
          backdropFilter: 'blur(10px)',
          fontWeight: '600',
          fontSize: '0.875rem'
        }}>
          {notification.message}
        </div>
      )}

      <main className="dashboard-container">
        {/* System Health Section */}
        <section>
          <h2 style={{ fontSize: '1.1rem', fontWeight: '700', color: 'var(--text-muted)', marginBottom: '1rem' }}>
            🖥️ Canlı Sistem ve Altyapı Bağlantı Durumu
          </h2>
          <SystemHealth healthData={healthData} />
        </section>

        {/* Main Grid: Hierarchy Tree + Git Branch Status */}
        <div className="dashboard-grid">
          <BranchStatus />
          <HierarchyTree hierarchyData={hierarchyData} onSendSms={handleSendSms} />
        </div>
      </main>
    </div>
  );
}
