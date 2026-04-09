import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, Link, useLocation } from 'react-router-dom';
import { onAuthStateChanged, signOut } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from './firebase';
import { 
  LayoutDashboard, 
  UserCheck, 
  Bus, 
  MessageSquare, 
  LogOut, 
  Bell,
  Menu,
  X 
} from 'lucide-react';

// Pages (will be implemented next)
import DashboardPage from './pages/Dashboard';
import ApprovalsPage from './pages/Approvals';
import ComplaintsPage from './pages/Complaints';
import LoginPage from './pages/Login';

const Layout = ({ children }) => {
  const [isSidebarOpen, setSidebarOpen] = useState(true);
  const location = useLocation();

  const handleLogout = () => signOut(auth);

  const NavLink = ({ to, icon: Icon, label }) => {
    const isActive = location.pathname === to;
    return (
      <Link to={to} className={`sidebar-link ${isActive ? 'active' : ''}`}>
        <Icon size={20} style={{ marginRight: '12px' }} />
        {label}
      </Link>
    );
  };

  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: 'var(--bg-deep)' }}>
      {/* Sidebar */}
      <aside className="glass" style={{ 
        width: isSidebarOpen ? '260px' : '0', 
        overflow: 'hidden',
        transition: 'width 0.3s ease',
        margin: '16px',
        padding: isSidebarOpen ? '24px' : '0',
        display: 'flex',
        flexDirection: 'column',
        position: 'fixed',
        top: 0, bottom: 0, left: 0,
        zIndex: 100
      }}>
        <div style={{ marginBottom: '40px', display: 'flex', alignItems: 'center' }}>
          <div style={{ 
            width: '40px', height: '40px', background: 'var(--primary)', 
            borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center',
            marginRight: '12px', boxShadow: '0 0 15px var(--primary-glow)'
          }}>
            <Bus color="white" size={24} />
          </div>
          <h1 className="font-heading" style={{ fontSize: '20px', fontWeight: 800 }}>PAYROUTE</h1>
        </div>

        <nav style={{ flex: 1 }}>
          <NavLink to="/" icon={LayoutDashboard} label="Dashboard" />
          <NavLink to="/approvals" icon={UserCheck} label="Approvals" />
          <NavLink to="/complaints" icon={MessageSquare} label="Complaints" />
        </nav>

        <button onClick={handleLogout} className="sidebar-link" style={{ 
          background: 'none', border: 'none', width: '100%', cursor: 'pointer', textAlign: 'left' 
        }}>
          <LogOut size={20} style={{ marginRight: '12px' }} />
          Logout
        </button>
      </aside>

      {/* Main Content */}
      <main style={{ 
        flex: 1, 
        marginLeft: isSidebarOpen ? '292px' : '16px', 
        padding: '32px',
        transition: 'margin-left 0.3s ease'
      }}>
        <header style={{ 
          display: 'flex', justifyContent: 'space-between', alignItems: 'center', 
          marginBottom: '40px' 
        }}>
          <div>
            <h2 className="font-heading" style={{ fontSize: '28px', marginBottom: '4px' }}>
              {location.pathname === '/' ? 'Mission Control' : 
               location.pathname === '/approvals' ? 'Staff & Fleet' : 'User Reports'}
            </h2>
            <p style={{ color: 'var(--text-muted)', fontSize: '14px' }}>System Operational</p>
          </div>
          <div style={{ display: 'flex', gap: '16px' }}>
            <button className="glass glass-hover" style={{ padding: '10px', color: 'white' }}>
              <Bell size={20} />
            </button>
            <div className="glass" style={{ padding: '4px 16px', display: 'flex', alignItems: 'center', gap: '12px' }}>
              <div style={{ textAlign: 'right' }}>
                <p style={{ fontSize: '13px', fontWeight: 600 }}>Main Admin</p>
                <p style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Root Access</p>
              </div>
              <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: 'var(--accent)' }} />
            </div>
          </div>
        </header>

        {children}
      </main>
    </div>
  );
};

function App() {
  const [user, setUser] = useState(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    return onAuthStateChanged(auth, async (u) => {
      setUser(u);
      if (u) {
        try {
          const userDoc = await getDoc(doc(db, 'users', u.uid));
          const roles = userDoc.data()?.roles ?? [];
          setIsAdmin(Array.isArray(roles) && roles.includes('admin'));
        } catch {
          setIsAdmin(false);
        }
      } else {
        setIsAdmin(false);
      }
      setLoading(false);
    });
  }, []);

  if (loading) return (
    <div style={{ height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'var(--bg-deep)' }}>
      <div className="glass" style={{ padding: '40px', textAlign: 'center' }}>
        <p style={{ color: 'var(--primary)', fontWeight: 600 }}>Initializing Neural Link...</p>
      </div>
    </div>
  );

  return (
    <Router>
      <Routes>
        <Route path="/login" element={!user ? <LoginPage /> : <Navigate to="/" />} />
        <Route path="/*" element={
          user && isAdmin ? (
            <Layout>
              <Routes>
                <Route path="/" element={<DashboardPage />} />
                <Route path="/approvals" element={<ApprovalsPage />} />
                <Route path="/complaints" element={<ComplaintsPage />} />
              </Routes>
            </Layout>
          ) : (
            <Navigate to="/login" />
          )
        } />
      </Routes>
    </Router>
  );
}

export default App;
