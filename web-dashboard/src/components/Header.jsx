import React from 'react';
import { Compass, ShieldCheck, RefreshCw } from 'lucide-react';

export default function Header({ onRefresh, isRefreshing }) {
  return (
    <header className="app-header">
      <div className="header-brand">
        <div className="header-logo-icon">
          <Compass className="pulse" />
        </div>
        <div className="header-title">
          <h1>MatPusula Kontrol Paneli</h1>
          <p className="header-subtitle">Canlı Sistem Sağlığı & Hiyerarşik "Soy Ağacı" İzleme Portalı</p>
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <span className="status-badge online">
          <span className="status-dot"></span>
          Docker & PG Connected
        </span>

        <button 
          className="btn-secondary" 
          onClick={onRefresh}
          disabled={isRefreshing}
          title="Verileri Yenile"
        >
          <RefreshCw size={16} className={isRefreshing ? 'pulse' : ''} />
          {isRefreshing ? 'Yenileniyor...' : 'Yenile'}
        </button>
      </div>
    </header>
  );
}
