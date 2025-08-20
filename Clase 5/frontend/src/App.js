import { useState, useEffect } from 'react';
import { Lightbulb, Power, Wifi, WifiOff } from 'lucide-react';

const styles = {
  container: {
    minHeight: '100vh',
    background: 'linear-gradient(135deg, #1e3a8a 0%, #7c3aed 50%, #3730a3 100%)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    padding: '1rem',
    fontFamily: 'system-ui, -apple-system, sans-serif'
  },
  card: {
    maxWidth: '400px',
    width: '100%',
    background: 'rgba(255, 255, 255, 0.1)',
    backdropFilter: 'blur(10px)',
    borderRadius: '24px',
    padding: '2rem',
    boxShadow: '0 25px 50px rgba(0, 0, 0, 0.25)',
    border: '1px solid rgba(255, 255, 255, 0.2)'
  },
  header: {
    textAlign: 'center',
    marginBottom: '2rem'
  },
  iconContainer: {
    position: 'relative',
    display: 'flex',
    justifyContent: 'center',
    marginBottom: '1rem'
  },
  title: {
    fontSize: '2rem',
    fontWeight: 'bold',
    color: 'white',
    marginBottom: '0.5rem',
    margin: 0
  },
  subtitle: {
    color: '#d1d5db',
    margin: 0
  },
  connectionStatus: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '0.5rem',
    padding: '0.5rem 1rem',
    borderRadius: '9999px',
    fontSize: '0.875rem',
    marginBottom: '1.5rem'
  },
  connected: {
    background: 'rgba(34, 197, 94, 0.2)',
    color: '#86efac',
    border: '1px solid rgba(34, 197, 94, 0.3)'
  },
  disconnected: {
    background: 'rgba(239, 68, 68, 0.2)',
    color: '#fca5a5',
    border: '1px solid rgba(239, 68, 68, 0.3)'
  },
  statusContainer: {
    textAlign: 'center',
    marginBottom: '2rem'
  },
  statusBadge: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '0.5rem',
    padding: '0.75rem 1.5rem',
    borderRadius: '16px',
    fontWeight: '600',
    fontSize: '1.125rem'
  },
  ledOn: {
    background: 'rgba(34, 197, 94, 0.2)',
    color: '#86efac',
    border: '1px solid rgba(34, 197, 94, 0.3)'
  },
  ledOff: {
    background: 'rgba(107, 114, 128, 0.2)',
    color: '#d1d5db',
    border: '1px solid rgba(107, 114, 128, 0.3)'
  },
  buttonContainer: {
    display: 'flex',
    flexDirection: 'column',
    gap: '1rem'
  },
  button: {
    width: '100%',
    padding: '1rem 1.5rem',
    borderRadius: '16px',
    fontWeight: '600',
    fontSize: '1.125rem',
    border: 'none',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '0.5rem'
  },
  buttonOn: {
    background: '#059669',
    color: 'white',
    boxShadow: '0 10px 25px rgba(5, 150, 105, 0.25)'
  },
  buttonOnActive: {
    background: '#047857'
  },
  buttonOff: {
    background: '#dc2626',
    color: 'white',
    boxShadow: '0 10px 25px rgba(220, 38, 38, 0.25)'
  },
  buttonOffActive: {
    background: '#b91c1c'
  },
  buttonDisabled: {
    opacity: '0.5',
    cursor: 'not-allowed'
  },
  error: {
    marginTop: '1.5rem',
    padding: '1rem',
    background: 'rgba(239, 68, 68, 0.2)',
    border: '1px solid rgba(239, 68, 68, 0.3)',
    borderRadius: '16px',
    color: '#fca5a5',
    textAlign: 'center',
    fontSize: '0.875rem'
  },
  footer: {
    marginTop: '2rem',
    textAlign: 'center',
    color: '#9ca3af',
    fontSize: '0.875rem'
  },
  spinner: {
    width: '20px',
    height: '20px',
    border: '2px solid rgba(255, 255, 255, 0.3)',
    borderTop: '2px solid white',
    borderRadius: '50%',
    animation: 'spin 1s linear infinite'
  }
};

// Añadir la animación de spin
const spinKeyframes = `
  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
`;

// Inyectar los keyframes
if (!document.querySelector('#spin-animation')) {
  const style = document.createElement('style');
  style.id = 'spin-animation';
  style.textContent = spinKeyframes;
  document.head.appendChild(style);
}

export default function LEDController() {
  const [ledStatus, setLedStatus] = useState('OFF');
  const [isConnected, setIsConnected] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  
  const API_BASE = 'http://localhost:3001/api';

  // Verificar estado inicial y conexión
  useEffect(() => {
    checkConnection();
    fetchLedStatus();
    
    // Polling cada 5 segundos para mantener sincronización
    const interval = setInterval(() => {
      checkConnection();
      fetchLedStatus();
    }, 5000);
    
    return () => clearInterval(interval);
  }, []);

  const checkConnection = async () => {
    try {
      const response = await fetch(`${API_BASE}/health`);
      const data = await response.json();
      setIsConnected(data.mqtt_connected);
      setError('');
    } catch (err) {
      setIsConnected(false);
      console.error('Error checking connection:', err);
    }
  };

  const fetchLedStatus = async () => {
    try {
      const response = await fetch(`${API_BASE}/led/status`);
      const data = await response.json();
      setLedStatus(data.status);
    } catch (err) {
      console.error('Error fetching LED status:', err);
    }
  };

  const controlLED = async (action) => {
    setIsLoading(true);
    setError('');
    
    try {
      const response = await fetch(`${API_BASE}/led/control`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ action }),
      });
      
      const data = await response.json();
      
      if (response.ok) {
        setLedStatus(action);
      } else {
        setError(data.error || 'Error al controlar el LED');
      }
    } catch (err) {
      setError('Error de conexión con el servidor');
      console.error('Error controlling LED:', err);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        
        {/* Header */}
        <div style={styles.header}>
          <div style={styles.iconContainer}>
            <Lightbulb 
              size={64}
              color={ledStatus === 'ON' ? '#fbbf24' : '#9ca3af'}
              style={{
                filter: ledStatus === 'ON' ? 'drop-shadow(0 0 10px #fbbf24)' : 'none',
                transition: 'all 0.5s ease'
              }}
            />
          </div>
          
          <h1 style={styles.title}>Control de LED</h1>
          <p style={styles.subtitle}>Raspberry Pi</p>
        </div>

        {/* Estado de conexión */}
        <div style={{display: 'flex', justifyContent: 'center', marginBottom: '1.5rem'}}>
          <div style={{
            ...styles.connectionStatus,
            ...(isConnected ? styles.connected : styles.disconnected)
          }}>
            {isConnected ? <Wifi size={16} /> : <WifiOff size={16} />}
            <span>{isConnected ? 'Conectado' : 'Desconectado'}</span>
          </div>
        </div>

        {/* Estado actual del LED */}
        <div style={styles.statusContainer}>
          <div style={{
            ...styles.statusBadge,
            ...(ledStatus === 'ON' ? styles.ledOn : styles.ledOff)
          }}>
            <Power size={20} />
            <span>LED {ledStatus === 'ON' ? 'ENCENDIDO' : 'APAGADO'}</span>
          </div>
        </div>

        {/* Botones de control */}
        <div style={styles.buttonContainer}>
          <button
            onClick={() => controlLED('ON')}
            disabled={isLoading || !isConnected}
            style={{
              ...styles.button,
              ...(ledStatus === 'ON' ? styles.buttonOnActive : styles.buttonOn),
              ...(isLoading || !isConnected ? styles.buttonDisabled : {})
            }}
            onMouseEnter={(e) => {
              if (!isLoading && isConnected) {
                e.target.style.transform = 'scale(1.05)';
              }
            }}
            onMouseLeave={(e) => {
              e.target.style.transform = 'scale(1)';
            }}
          >
            {isLoading && ledStatus !== 'ON' ? (
              <>
                <div style={styles.spinner}></div>
                Encendiendo...
              </>
            ) : (
              <>💡 Encender LED</>
            )}
          </button>

          <button
            onClick={() => controlLED('OFF')}
            disabled={isLoading || !isConnected}
            style={{
              ...styles.button,
              ...(ledStatus === 'OFF' ? styles.buttonOffActive : styles.buttonOff),
              ...(isLoading || !isConnected ? styles.buttonDisabled : {})
            }}
            onMouseEnter={(e) => {
              if (!isLoading && isConnected) {
                e.target.style.transform = 'scale(1.05)';
              }
            }}
            onMouseLeave={(e) => {
              e.target.style.transform = 'scale(1)';
            }}
          >
            {isLoading && ledStatus !== 'OFF' ? (
              <>
                <div style={styles.spinner}></div>
                Apagando...
              </>
            ) : (
              <>⚫ Apagar LED</>
            )}
          </button>
        </div>

        {/* Mensaje de error */}
        {error && (
          <div style={styles.error}>
            <p>{error}</p>
          </div>
        )}

        {/* Footer */}
        <div style={styles.footer}>
          <p>🤖 Controlado desde React</p>
        </div>
      </div>
    </div>
  );
}