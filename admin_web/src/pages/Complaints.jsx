import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { MessageSquare, Trash2, CheckCircle, User, Bus, AlertCircle } from 'lucide-react';

const Complaints = () => {
  const [complaints, setComplaints] = useState([]);

  useEffect(() => {
    return onSnapshot(collection(db, 'complaints'), (snap) => {
      setComplaints(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });
  }, []);

  const resolveComplaint = async (id) => {
    try {
      await deleteDoc(doc(db, 'complaints', id));
    } catch (e) {
      alert("Error resolving: " + e.message);
    }
  };

  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(400px, 1fr))', gap: '24px' }}>
        {complaints.map(item => (
          <div key={item.id} className="glass glass-hover" style={{ padding: '24px', display: 'flex', flexDirection: 'column' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '20px' }}>
              <div style={{ padding: '8px', background: 'rgba(239, 68, 68, 0.1)', color: 'var(--danger)', borderRadius: '10px' }}>
                <AlertCircle size={20} />
              </div>
              <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>{item.timestamp?.toDate().toLocaleString() || 'Recent'}</span>
            </div>

            <h3 style={{ fontSize: '18px', marginBottom: '8px' }}>{item.category || 'General Issue'}</h3>
            <p style={{ color: 'var(--text-muted)', fontSize: '14px', lineHeight: '1.6', flex: 1, marginBottom: '24px' }}>
              {item.description}
            </p>

            <div style={{ display: 'flex', gap: '12px', marginBottom: '32px' }}>
               <div className="glass" style={{ padding: '8px 12px', fontSize: '12px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                 <User size={14} color="var(--primary)" />
                 {item.passengerId?.substring(0, 10)}
               </div>
               <div className="glass" style={{ padding: '8px 12px', fontSize: '12px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                 <Bus size={14} color="var(--accent)" />
                 {item.busId}
               </div>
            </div>

            <div style={{ display: 'flex', gap: '12px' }}>
               <button onClick={() => resolveComplaint(item.id)} className="neon-btn" style={{ 
                 flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px',
                 background: 'var(--success)', boxShadow: 'none'
               }}>
                 <CheckCircle size={18} />
                 Mark as Resolved
               </button>
               <button className="glass glass-hover" style={{ padding: '12px', color: 'var(--danger)' }}>
                 <Trash2 size={18} />
               </button>
            </div>
          </div>
        ))}
        {complaints.length === 0 && (
          <div className="glass" style={{ padding: '40px', gridColumn: '1 / -1', textAlign: 'center' }}>
            <p style={{ color: 'var(--text-muted)' }}>All clear! No active complaints found in the sector.</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default Complaints;
