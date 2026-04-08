import React, { useState } from 'react';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '../firebase';
import { Shield, Lock, Mail } from 'lucide-react';

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      await signInWithEmailAndPassword(auth, email, password);
    } catch (err) {
      setError('Invalid admin credentials. Access Denied.');
      setLoading(false);
    }
  };

  return (
    <div style={{ 
      height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', 
      background: 'radial-gradient(circle at center, #1a1a2e 0%, var(--bg-deep) 100%)' 
    }}>
      <div className="glass" style={{ padding: '48px', width: '100%', maxWidth: '440px', textAlign: 'center' }}>
        <div style={{ 
          width: '64px', height: '64px', background: 'var(--primary)', borderRadius: '16px',
          display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 24px',
          boxShadow: '0 0 30px var(--primary-glow)'
        }}>
          <Shield size={32} color="white" />
        </div>
        
        <h2 className="font-heading" style={{ fontSize: '28px', marginBottom: '8px' }}>Admin Login</h2>
        <p style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '32px' }}>
          Secure access to PayRoute Mission Control
        </p>

        {error && (
          <div style={{ 
            padding: '12px', background: 'rgba(239, 68, 68, 0.1)', color: 'var(--danger)', 
            borderRadius: '12px', fontSize: '13px', marginBottom: '24px' 
          }}>
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div style={{ position: 'relative' }}>
            <Mail size={18} style={{ position: 'absolute', top: '14px', left: '16px', color: 'var(--text-muted)' }} />
            <input 
              type="email" 
              placeholder="Admin Email" 
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="glass"
              style={{ width: '100%', padding: '14px 14px 14px 48px', color: 'white', background: 'rgba(255,255,255,0.03)' }}
            />
          </div>

          <div style={{ position: 'relative' }}>
            <Lock size={18} style={{ position: 'absolute', top: '14px', left: '16px', color: 'var(--text-muted)' }} />
            <input 
              type="password" 
              placeholder="Authorization Key" 
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="glass"
              style={{ width: '100%', padding: '14px 14px 14px 48px', color: 'white', background: 'rgba(255,255,255,0.03)' }}
            />
          </div>

          <button type="submit" disabled={loading} className="neon-btn" style={{ marginTop: '12px' }}>
            {loading ? 'Authorizing...' : 'Initialize Mission Control'}
          </button>
        </form>

        <p style={{ marginTop: '32px', fontSize: '12px', color: 'var(--text-muted)' }}>
          Session logged for security auditing.
        </p>
      </div>
    </div>
  );
};

export default Login;
