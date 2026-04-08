import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, doc, updateDoc, writeBatch, getDocs } from 'firebase/firestore';
import { db } from '../firebase';
import { UserCheck, Bus, Check, X, Info } from 'lucide-react';

const Approvals = () => {
  const [activeTab, setActiveTab] = useState('staff');
  const [staff, setStaff] = useState([]);
  const [buses, setBuses] = useState([]);
  const [assignments, setAssignments] = useState([]);

  useEffect(() => {
    // Listen to Pending Drivers
    const driversUnsub = onSnapshot(
      query(collection(db, 'drivers'), where('verificationStatus', '==', 'pending')),
      (snap) => {
        const drivers = snap.docs.map(d => ({ id: d.id, ...d.data(), role: 'driver', collection: 'drivers' }));
        setStaff(prev => {
          const conductors = prev.filter(s => s.collection === 'conductors');
          return [...drivers, ...conductors];
        });
      }
    );

    // Listen to Pending Conductors
    const conductorsUnsub = onSnapshot(
      query(collection(db, 'conductors'), where('verificationStatus', '==', 'pending')),
      (snap) => {
        const conductors = snap.docs.map(d => ({ id: d.id, ...d.data(), role: 'conductor', collection: 'conductors' }));
        setStaff(prev => {
          const drivers = prev.filter(s => s.collection === 'drivers');
          return [...drivers, ...conductors];
        });
      }
    );

    // Listen to Pending Buses
    const busesUnsub = onSnapshot(
      query(collection(db, 'buses'), where('verificationStatus', '==', 'pending')),
      (snap) => {
        setBuses(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      }
    );

    // Listen to Pending Assignments
    const assignUnsub = onSnapshot(
      query(collection(db, 'staffAssignments'), where('status', '==', 'pending_approval')),
      (snap) => {
        setAssignments(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      }
    );

    return () => {
      driversUnsub();
      conductorsUnsub();
      busesUnsub();
      assignUnsub();
    };
  }, []);

  const handleAction = async (collectionName, id, approve) => {
    const status = approve ? 'approved' : 'rejected';
    try {
      await updateDoc(doc(db, collectionName, id), {
        verificationStatus: status,
        verifiedAt: new Date(),
      });
    } catch (e) {
      alert("Error: " + e.message);
    }
  };

  const handleAssignment = async (assignId, data, approve) => {
    try {
      if (approve) {
        const batch = writeBatch(db);
        const assignRef = doc(db, 'staffAssignments', assignId);
        batch.update(assignRef, { status: 'active' });

        // Update Bus
        const busRef = doc(db, 'buses', data.busId);
        batch.update(busRef, {
          [data.role === 'driver' ? 'driverId' : 'conductorId']: data.userId
        });

        // Update Staff member
        const staffColl = data.role === 'driver' ? 'drivers' : 'conductors';
        const staffQuery = await getDocs(query(collection(db, staffColl), where('userId', '==', data.userId)));
        if (!staffQuery.empty) {
          batch.update(staffQuery.docs[0].ref, { assignedBusId: data.busId });
        }

        await batch.commit();
      } else {
        await updateDoc(doc(db, 'staffAssignments', assignId), { status: 'rejected' });
      }
    } catch (e) {
      alert("Error: " + e.message);
    }
  };

  return (
    <div>
      <div style={{ display: 'flex', gap: '32px', marginBottom: '32px', borderBottom: '1px solid var(--border-glass)' }}>
        <TabButton active={activeTab === 'staff'} onClick={() => setActiveTab('staff')} label="Staff Verifications" count={staff.length} />
        <TabButton active={activeTab === 'bus'} onClick={() => setActiveTab('bus')} label="Fleet Approval" count={buses.length} />
        <TabButton active={activeTab === 'assign'} onClick={() => setActiveTab('assign')} label="Assignments" count={assignments.length} />
      </div>

      <div className="glass" style={{ padding: '0' }}>
        <div className="table-container">
          <table>
            <thead>
              <tr>
                <th>Entity</th>
                <th>Registration / ID</th>
                <th>Details</th>
                <th>Requested</th>
                <th style={{ textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {activeTab === 'staff' && staff.map(item => (
                <tr key={item.id}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                      <div className="glass" style={{ padding: '8px', color: 'var(--primary)' }}><UserCheck size={18} /></div>
                      <div>
                        <p style={{ fontWeight: 600 }}>{item.role}</p>
                        <p style={{ fontSize: '12px', color: 'var(--text-muted)' }}>{item.userId?.substring(0, 10)}...</p>
                      </div>
                    </div>
                  </td>
                  <td>ID Card Verified</td>
                  <td><Badge label="New App" color="var(--accent)" /></td>
                  <td>{item.createdAt?.toDate().toLocaleDateString() || 'Today'}</td>
                  <td style={{ textAlign: 'right' }}>
                    <ActionButton icon={Check} color="var(--success)" onClick={() => handleAction(item.collection, item.id, true)} />
                    <ActionButton icon={X} color="var(--danger)" onClick={() => handleAction(item.collection, item.id, false)} />
                  </td>
                </tr>
              ))}

              {activeTab === 'bus' && buses.map(item => (
                <tr key={item.id}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                      <div className="glass" style={{ padding: '8px', color: 'var(--accent)' }}><Bus size={18} /></div>
                      <div>
                        <p style={{ fontWeight: 600 }}>{item.registrationNumber}</p>
                        <p style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Cap: {item.capacity}</p>
                      </div>
                    </div>
                  </td>
                  <td>Route {item.routeId}</td>
                  <td><Badge label="New Bus" color="var(--accent)" /></td>
                  <td>Recent</td>
                  <td style={{ textAlign: 'right' }}>
                    <ActionButton icon={Check} color="var(--success)" onClick={() => handleAction('buses', item.id, true)} />
                    <ActionButton icon={X} color="var(--danger)" onClick={() => handleAction('buses', item.id, false)} />
                  </td>
                </tr>
              ))}

              {activeTab === 'assign' && assignments.map(item => (
                <tr key={item.id}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                      <div className="glass" style={{ padding: '8px', color: '#F59E0B' }}><Info size={18} /></div>
                      <div>
                        <p style={{ fontWeight: 600 }}>Assignment</p>
                        <p style={{ fontSize: '12px', color: 'var(--text-muted)' }}>{item.role}</p>
                      </div>
                    </div>
                  </td>
                  <td>Bus: {item.busId}</td>
                  <td>UID: {item.userId?.substring(0, 8)}...</td>
                  <td>Recent</td>
                  <td style={{ textAlign: 'right' }}>
                    <ActionButton icon={Check} color="var(--success)" onClick={() => handleAssignment(item.id, item, true)} />
                    <ActionButton icon={X} color="var(--danger)" onClick={() => handleAssignment(item.id, item, false)} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {(activeTab === 'staff' ? staff : activeTab === 'bus' ? buses : assignments).length === 0 && (
            <div style={{ padding: '60px', textAlign: 'center', color: 'var(--text-muted)' }}>
              No pending requests found in this sector.
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

const TabButton = ({ active, onClick, label, count }) => (
  <button onClick={onClick} style={{ 
    padding: '16px 0', background: 'none', border: 'none', color: active ? 'var(--primary)' : 'var(--text-muted)',
    fontSize: '14px', fontWeight: 600, cursor: 'pointer', borderBottom: active ? '2px solid var(--primary)' : 'none',
    display: 'flex', alignItems: 'center', gap: '8px'
  }}>
    {label}
    {count > 0 && <span style={{ 
      background: active ? 'var(--primary)' : 'rgba(255,255,255,0.1)', color: 'white',
      padding: '2px 8px', borderRadius: '6px', fontSize: '11px' 
    }}>{count}</span>}
  </button>
);

const ActionButton = ({ icon: Icon, color, onClick }) => (
  <button onClick={onClick} className="glass glass-hover" style={{ 
    padding: '8px', marginLeft: '8px', color: color, cursor: 'pointer' 
  }}>
    <Icon size={18} />
  </button>
);

const Badge = ({ label, color }) => (
  <span className="status-badge" style={{ background: `${color}20`, color: color }}>
    {label}
  </span>
);

export default Approvals;
