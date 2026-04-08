import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, getDocs } from 'firebase/firestore';
import { db } from '../firebase';
import { 
  Users, 
  Bus, 
  TrendingUp, 
  DollarSign,
  ArrowUpRight,
  ArrowDownRight,
  Activity
} from 'lucide-react';
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  AreaChart,
  Area 
} from 'recharts';

const StatCard = ({ title, value, icon: Icon, trend, color }) => (
  <div className="glass glass-hover" style={{ padding: '24px' }}>
    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
      <div style={{ 
        width: '48px', height: '48px', borderRadius: '12px', background: `${color}20`,
        display: 'flex', alignItems: 'center', justifyContent: 'center', color: color
      }}>
        <Icon size={24} />
      </div>
      {trend && (
        <div style={{ 
          display: 'flex', alignItems: 'center', gap: '4px', fontSize: '13px',
          color: trend > 0 ? 'var(--success)' : 'var(--danger)'
        }}>
          {trend > 0 ? <ArrowUpRight size={16} /> : <ArrowDownRight size={16} />}
          {Math.abs(trend)}%
        </div>
      )}
    </div>
    <p style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '4px' }}>{title}</p>
    <h3 style={{ fontSize: '24px', fontWeight: 700 }}>{value}</h3>
  </div>
);

const Dashboard = () => {
  const [stats, setStats] = useState({
    totalUsers: 0,
    activeBuses: 0,
    totalRevenue: 0,
    pendingVerifs: 0
  });

  const [graphData, setGraphData] = useState([
    { name: 'Mon', rev: 4000 },
    { name: 'Tue', rev: 3000 },
    { name: 'Wed', rev: 6000 },
    { name: 'Thu', rev: 5000 },
    { name: 'Fri', rev: 8000 },
    { name: 'Sat', rev: 11000 },
    { name: 'Sun', rev: 9000 },
  ]);

  useEffect(() => {
    // Listen to Buses
    const busUnsub = onSnapshot(collection(db, 'buses'), (snap) => {
      setStats(prev => ({ ...prev, activeBuses: snap.size }));
    });

    // Listen to Users
    const userUnsub = onSnapshot(collection(db, 'users'), (snap) => {
      setStats(prev => ({ ...prev, totalUsers: snap.size }));
    });

    // Listen to Pending
    const pendingUnsub = onSnapshot(
      query(collection(db, 'drivers'), where('verificationStatus', '==', 'pending')),
      (snap) => {
        setStats(prev => ({ ...prev, pendingVerifs: snap.size }));
      }
    );

    return () => {
      busUnsub();
      userUnsub();
      pendingUnsub();
    };
  }, []);

  return (
    <div>
      <div className="stats-grid">
        <StatCard title="Total Network Users" value={stats.totalUsers} icon={Users} trend={12.5} color="#8B5CF6" />
        <StatCard title="Active Fleet" value={stats.activeBuses} icon={Bus} trend={4.2} color="#3B82F6" />
        <StatCard title="Daily Revenue" value="LKR 42,500" icon={DollarSign} trend={8.1} color="#10B981" />
        <StatCard title="Pending Verifications" value={stats.pendingVerifs} icon={Activity} trend={-15} color="#F59E0B" />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px' }}>
        {/* Revenue Chart */}
        <div className="glass" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '32px' }}>
            <h3 className="font-heading">Revenue Analytics</h3>
            <select className="glass" style={{ padding: '4px 12px', background: 'none', color: 'white', fontSize: '13px' }}>
              <option>Last 7 Days</option>
              <option>Last 30 Days</option>
            </select>
          </div>
          <div style={{ width: '100%', height: '300px' }}>
            <ResponsiveContainer>
              <AreaChart data={graphData}>
                <defs>
                  <linearGradient id="colorRev" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--primary)" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="var(--primary)" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                <XAxis dataKey="name" stroke="var(--text-muted)" fontSize={12} tickLine={false} axisLine={false} />
                <YAxis stroke="var(--text-muted)" fontSize={12} tickLine={false} axisLine={false} />
                <Tooltip 
                  contentStyle={{ background: 'var(--bg-deep)', border: '1px solid var(--border-glass)', borderRadius: '12px' }}
                  itemStyle={{ color: 'var(--primary)' }}
                />
                <Area type="monotone" dataKey="rev" stroke="var(--primary)" fillOpacity={1} fill="url(#colorRev)" strokeWidth={3} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* System Health */}
        <div className="glass" style={{ padding: '24px' }}>
          <h3 className="font-heading" style={{ marginBottom: '24px' }}>System Health</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            <HealthItem label="Core Functions" status="Optimal" color="var(--success)" />
            <HealthItem label="Real-time Tracking" status="Live" color="var(--accent)" />
            <HealthItem label="Payment Gateway" status="Stable" color="var(--success)" />
            <HealthItem label="Azure Functions" status="Syncing" color="#F59E0B" />
          </div>
          
          <div style={{ marginTop: 'auto', paddingTop: '32px' }}>
             <button className="neon-btn" style={{ width: '100%' }}>
               Run Diagnostics
             </button>
          </div>
        </div>
      </div>
    </div>
  );
};

const HealthItem = ({ label, status, color }) => (
  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
    <p style={{ fontSize: '14px' }}>{label}</p>
    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
      <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: color }} />
      <span style={{ fontSize: '13px', color: color, fontWeight: 600 }}>{status}</span>
    </div>
  </div>
);

export default Dashboard;
