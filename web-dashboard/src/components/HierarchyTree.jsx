import React, { useState } from 'react';
import { Network, ChevronDown, ChevronRight, User, Users, Smartphone, Send, CheckCircle, Clock, AlertTriangle, BookOpen } from 'lucide-react';

export default function HierarchyTree({ hierarchyData, onSendSms }) {
  const [expandedClasses, setExpandedClasses] = useState(['class-8a', 'class-8b']);
  const [selectedStudent, setSelectedStudent] = useState(null);
  const [sendingSmsId, setSendingSmsId] = useState(null);

  const toggleClass = (classId) => {
    setExpandedClasses((prev) =>
      prev.includes(classId) ? prev.filter((id) => id !== classId) : [...prev, classId]
    );
  };

  const handleSmsTrigger = async (student, parent) => {
    setSendingSmsId(student.id);
    await onSendSms(student, parent);
    setSendingSmsId(null);
  };

  const nodes = hierarchyData?.nodes || [];

  return (
    <div className="glass-panel tree-container">
      <div className="tree-root-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
          <div style={{ padding: '0.5rem', background: 'rgba(99, 102, 241, 0.15)', borderRadius: '10px' }}>
            <Network size={24} color="var(--primary)" />
          </div>
          <div>
            <h2 style={{ fontSize: '1.25rem', fontWeight: '700' }}>
              {hierarchyData?.schoolName || ' MatPusula Özel Eğitim Koleji'}
            </h2>
            <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
              Okul ➔ Sınıf ➔ Öğretmen ➔ Öğrenci ➔ Veli "Soy Ağacı" & SMS Takip Haritası
            </p>
          </div>
        </div>

        <div style={{ display: 'flex', gap: '1.5rem', fontSize: '0.85rem' }}>
          <div>
            <span style={{ color: 'var(--text-muted)' }}>Sınıflar: </span>
            <strong style={{ color: '#fff' }}>{hierarchyData?.totalClasses || 3}</strong>
          </div>
          <div>
            <span style={{ color: 'var(--text-muted)' }}>Öğrenciler: </span>
            <strong style={{ color: '#fff' }}>{hierarchyData?.totalStudents || 6}</strong>
          </div>
          <div>
            <span style={{ color: 'var(--text-muted)' }}>Veliler: </span>
            <strong style={{ color: '#fff' }}>{hierarchyData?.totalParents || 6}</strong>
          </div>
        </div>
      </div>

      {/* Tree Nodes List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
        {nodes.map((cls) => {
          const isExpanded = expandedClasses.includes(cls.id);

          return (
            <div key={cls.id} className="tree-node">
              {/* Class Node Header */}
              <div className="tree-node-header" onClick={() => toggleClass(cls.id)}>
                <div className="tree-node-title">
                  {isExpanded ? <ChevronDown size={18} color="var(--primary)" /> : <ChevronRight size={18} color="var(--text-muted)" />}
                  <BookOpen size={18} color="var(--accent-cyan)" />
                  <span>{cls.name}</span>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{cls.teacher}</span>
                  <span className="status-badge online" style={{ fontSize: '0.7rem' }}>
                    {cls.students?.length || 0} Öğrenci
                  </span>
                </div>
              </div>

              {/* Students & Parents Sub-Tree */}
              {isExpanded && (
                <div className="tree-node-children">
                  {cls.students?.map((std) => (
                    <div 
                      key={std.id} 
                      className="student-card"
                      style={{
                        flexDirection: 'column',
                        alignItems: 'stretch',
                        gap: '0.5rem'
                      }}
                    >
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div className="student-info">
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                            <User size={16} color="var(--accent-cyan)" />
                            <h4>{std.name}</h4>
                            <span style={{ fontSize: '0.75rem', color: 'var(--text-dim)' }}>#{std.studentNo}</span>
                          </div>
                        </div>

                        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                          <div style={{ textAlign: 'right' }}>
                            <div style={{ fontSize: '0.85rem', fontWeight: '700', color: '#10b981' }}>
                              {std.lastExamNet} Net
                            </div>
                            <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>
                              Son LGS Denemesi
                            </div>
                          </div>
                        </div>
                      </div>

                      {/* Parent Sub-Card (Connected Tree Leaf) */}
                      {std.parent && (
                        <div className="parent-subcard">
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
                            <Smartphone size={15} color="var(--primary)" />
                            <div>
                              <strong style={{ color: '#fff' }}>{std.parent.name}</strong>
                              <span style={{ marginLeft: '0.5rem', color: 'var(--text-muted)', fontSize: '0.75rem' }}>
                                ({std.parent.phone})
                              </span>
                            </div>
                          </div>

                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                            <span className={`status-badge ${std.parent.smsStatus}`}>
                              <span className="status-dot"></span>
                              {std.parent.smsStatusText}
                            </span>

                            <button
                              className="btn-primary"
                              style={{ padding: '0.3rem 0.65rem', fontSize: '0.75rem' }}
                              onClick={() => handleSmsTrigger(std, std.parent)}
                              disabled={sendingSmsId === std.id}
                            >
                              <Send size={12} />
                              {sendingSmsId === std.id ? 'Gönderiliyor...' : 'SMS Gönder'}
                            </button>
                          </div>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
