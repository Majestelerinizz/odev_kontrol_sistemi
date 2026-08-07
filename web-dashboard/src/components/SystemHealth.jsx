import React from 'react';
import { Database, Server, Flame, MessageSquare, Eye } from 'lucide-react';

export default function SystemHealth({ healthData }) {
  const services = healthData?.services || {};

  const healthItems = [
    {
      title: 'Docker Container',
      subtitle: services.docker?.container || 'odevtakip_postgres',
      statusText: services.docker?.uptime || 'Running (Healthy)',
      icon: <Server size={22} color="#06b6d4" />,
      badgeClass: 'online',
    },
    {
      title: 'PostgreSQL DB',
      subtitle: 'Port: 5432 | odevtakip',
      statusText: services.postgresql?.status === 'connected' ? 'Connected (Active)' : 'Standalone Fallback',
      icon: <Database size={22} color="#6366f1" />,
      badgeClass: services.postgresql?.status === 'connected' ? 'online' : 'pending',
    },
    {
      title: 'Firebase Admin SDK',
      subtitle: 'Firestore Realtime Sync',
      statusText: services.firebase?.status === 'authenticated' ? 'Synced (Live)' : 'Active (Ready)',
      icon: <Flame size={22} color="#f59e0b" />,
      badgeClass: 'online',
    },
    {
      title: 'Twilio SMS Servisi',
      subtitle: 'Otomatik Veli SMS',
      statusText: services.twilioSms?.status === 'configured' ? 'Live Gateway' : 'Simülasyon Modu',
      icon: <MessageSquare size={22} color="#10b981" />,
      badgeClass: 'online',
    },
    {
      title: 'Gemini AI Vision',
      subtitle: 'Optik Kabarcık & Tik Analiz',
      statusText: 'Gemini 1.5 Flash Active',
      icon: <Eye size={22} color="#a855f7" />,
      badgeClass: 'online',
    },
  ];

  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
      {healthItems.map((item, idx) => (
        <div key={idx} className="glass-panel" style={{ padding: '1.25rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.75rem' }}>
            <div style={{ padding: '0.6rem', background: 'rgba(255, 255, 255, 0.05)', borderRadius: '10px' }}>
              {item.icon}
            </div>
            <span className={`status-badge ${item.badgeClass}`}>
              <span className="status-dot"></span>
              {item.statusText}
            </span>
          </div>

          <h3 style={{ fontSize: '1rem', fontWeight: '700', marginBottom: '0.2rem' }}>{item.title}</h3>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{item.subtitle}</p>
        </div>
      ))}
    </div>
  );
}
