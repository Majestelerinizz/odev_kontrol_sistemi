import React from 'react';
import { GitBranch, User, Code2, ShieldAlert } from 'lucide-react';

export default function BranchStatus() {
  const teamMembers = [
    {
      name: '👑 Yusuf',
      role: 'Proje Lideri & Yapay Zeka Uzmanı',
      branch: 'yusuf',
      avatarBg: 'rgba(234, 179, 8, 0.15)',
      borderColor: '#eab308',
      responsibilities: 'Optik form (A, B, C, D) okuma & Gemini AI Vision tik/çarpı analizi',
    },
    {
      name: '🐘 Anıl',
      role: 'Mobil UI/UX Mimarı',
      branch: 'anil',
      avatarBg: 'rgba(99, 102, 241, 0.15)',
      borderColor: '#6366f1',
      responsibilities: 'Flutter arayüzü, AiExamScannerScreen & Veli/Öğretmen grafik panelleri',
    },
    {
      name: '🤖 Seyid',
      role: 'Backend & Veritabanı Mimarı',
      branch: 'seyid',
      avatarBg: 'rgba(16, 185, 129, 0.15)',
      borderColor: '#10b981',
      responsibilities: 'Node.js Express REST API, PostgreSQL şeması & Firebase Sync',
    },
    {
      name: '📱 Abdullah',
      role: 'Entegrasyon, SMS & DevOps Uzmanı',
      branch: 'abdullah',
      avatarBg: 'rgba(6, 182, 212, 0.15)',
      borderColor: '#06b6d4',
      responsibilities: 'Twilio SMS servisi, Push bildirimleri & Store yayın süreçleri',
    },
  ];

  return (
    <div className="glass-panel" style={{ padding: '1.5rem' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1.25rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
          <GitBranch size={20} color="var(--primary)" />
          <h2 style={{ fontSize: '1.1rem', fontWeight: '700' }}>Git Flow & Ekip Branch İzleme</h2>
        </div>
        <span className="status-badge online" style={{ fontSize: '0.7rem' }}>
          main (Protected Base)
        </span>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
        {teamMembers.map((member, idx) => (
          <div 
            key={idx}
            style={{
              padding: '1rem',
              background: 'rgba(15, 23, 42, 0.6)',
              borderRadius: '12px',
              borderLeft: `4px solid ${member.borderColor}`,
              borderTop: '1px solid rgba(255,255,255,0.05)',
              borderRight: '1px solid rgba(255,255,255,0.05)',
              borderBottom: '1px solid rgba(255,255,255,0.05)',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.35rem' }}>
              <span style={{ fontWeight: '700', fontSize: '0.95rem', color: '#fff' }}>{member.name}</span>
              <code style={{ 
                background: 'rgba(99, 102, 241, 0.15)', 
                color: '#a855f7', 
                padding: '0.2rem 0.5rem', 
                borderRadius: '6px',
                fontSize: '0.75rem',
                fontWeight: '600'
              }}>
                branch: {member.branch}
              </code>
            </div>

            <p style={{ fontSize: '0.8rem', color: member.borderColor, fontWeight: '600', marginBottom: '0.4rem' }}>
              {member.role}
            </p>

            <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
              {member.responsibilities}
            </p>
          </div>
        ))}
      </div>
    </div>
  );
}
