import React, { useState, useEffect, useCallback } from 'react';
import { Thermometer, Droplets, RefreshCw, Wifi, WifiOff } from 'lucide-react';
import { styles } from './styles';

const SensorDashboard = () => {
  const [readings, setReadings] = useState([]);
  const [latestReading, setLatestReading] = useState(null);
  const [isConnected, setIsConnected] = useState(false);
  const [loading, setLoading] = useState(false);
  const [pagination, setPagination] = useState({ page: 1, limit: 20, total: 0, pages: 0 });
  
  const API_URL = 'http://localhost:3001';

  // Conectar a Socket.IO para datos en tiempo real
  useEffect(() => {
    const script = document.createElement('script');
    script.src = 'https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.7.4/socket.io.js';
    script.onload = () => {
      const socket = window.io(API_URL);
      
      socket.on('connect', () => {
        setIsConnected(true);
        console.log('Conectado al servidor');
      });
      
      socket.on('disconnect', () => {
        setIsConnected(false);
        console.log('Desconectado del servidor');
      });
      
      socket.on('newReading', (data) => {
        setLatestReading(data);
        // Actualizar la tabla si estamos en la primera página
        if (pagination.page === 1) {
          fetchReadings(1);
        }
      });
      
      return () => {
        socket.disconnect();
      };
    };
    
    document.head.appendChild(script);
    
    return () => {
      document.head.removeChild(script);
    };
  }, [pagination.page]);

  // Función para obtener lecturas
  const fetchReadings = useCallback(async (page = 1) => {
    setLoading(true);
    try {
      const response = await fetch(`${API_URL}/api/readings?page=${page}&limit=${pagination.limit}`);
      const data = await response.json();
      
      setReadings(data.data || []);
      setPagination(data.pagination);
    } catch (error) {
      console.error('Error fetching readings:', error);
    } finally {
      setLoading(false);
    }
  }, [pagination.limit]);

  // Obtener última lectura
  const fetchLatestReading = async () => {
    try {
      const response = await fetch(`${API_URL}/api/readings/latest`);
      const data = await response.json();
      setLatestReading(data);
    } catch (error) {
      console.error('Error fetching latest reading:', error);
    }
  };

  // Cargar datos iniciales
  useEffect(() => {
    fetchReadings();
    fetchLatestReading();
  }, [fetchReadings]);

  // Formatear fecha
  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleString('es-ES');
  };

  return (
    <div style={styles.container}>
      <div style={styles.maxWidth}>
        {/* Header */}
        <div style={{...styles.card, ...styles.header}}>
          <div style={styles.headerContent}>
            <div>
              <h1 style={styles.title}>Dashboard de Sensores DHT11</h1>
              <p style={styles.subtitle}>Monitoreo en tiempo real de temperatura y humedad</p>
            </div>
            <div>
              {isConnected ? (
                <div style={styles.statusConnected}>
                  <Wifi size={16} style={{marginRight: '6px'}} />
                  <span>Conectado</span>
                </div>
              ) : (
                <div style={styles.statusDisconnected}>
                  <WifiOff size={16} style={{marginRight: '6px'}} />
                  <span>Desconectado</span>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Temperatura actual */}
        {latestReading && (
          <div style={{display: 'flex', justifyContent: 'center', marginBottom: '30px'}}>
            <div 
              style={{...styles.statCard, minWidth: '350px'}}
              onMouseEnter={(e) => {
                Object.assign(e.currentTarget.style, styles.statCardHover);
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.boxShadow = '0 8px 25px rgba(0, 0, 0, 0.08)';
              }}
            >
              <div style={{...styles.iconContainer, ...styles.temperatureIcon}}>
                <Thermometer size={28} color="white" />
              </div>
              <div style={styles.statLabel}>Temperatura Actual</div>
              <div style={{...styles.statValue, fontSize: '2.8rem'}}>{latestReading.temperature}°C</div>
              <div style={{...styles.statSubtext, fontSize: '13px', marginTop: '12px'}}>
                Última actualización: {formatDate(latestReading.timestamp)}
              </div>
            </div>
          </div>
        )}

        {/* Tabla de datos */}
        <div style={styles.tableContainer}>
          <div style={styles.tableHeader}>
            <div style={styles.tableHeaderContent}>
              <h2 style={styles.tableTitle}>Historial de Lecturas</h2>
              <div style={styles.buttonGroup}>
                <button
                  onClick={() => fetchReadings(pagination.page)}
                  style={{...styles.button, ...styles.secondaryButton}}
                >
                  <RefreshCw size={16} />
                  Actualizar
                </button>
              </div>
            </div>
          </div>

          <div style={{overflowX: 'auto'}}>
            {loading ? (
              <div style={styles.loadingContainer}>
                <RefreshCw size={24} style={{animation: 'spin 1s linear infinite', marginRight: '10px'}} />
                <span>Cargando...</span>
              </div>
            ) : (
              <table style={styles.table}>
                <thead style={styles.tableHead}>
                  <tr>
                    <th style={styles.th}>Fecha y Hora</th>
                    <th style={styles.th}>Temperatura (°C)</th>
                    <th style={styles.th}>Humedad (%)</th>
                  </tr>
                </thead>
                <tbody>
                  {readings.map((reading, index) => (
                    <tr 
                      key={reading._id || index} 
                      style={styles.tableRow}
                      onMouseEnter={(e) => {
                        e.currentTarget.style.backgroundColor = '#f8fafc';
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.backgroundColor = 'transparent';
                      }}
                    >
                      <td style={styles.td}>
                        {formatDate(reading.timestamp)}
                      </td>
                      <td style={styles.td}>
                        <div style={styles.valueDisplay}>
                          <Thermometer size={16} color="#ef4444" />
                          {reading.temperature}°C
                        </div>
                      </td>
                      <td style={styles.td}>
                        <div style={styles.valueDisplay}>
                          <Droplets size={16} color="#3b82f6" />
                          {reading.humidity}%
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          {/* Paginación */}
          {pagination.pages > 1 && (
            <div style={styles.pagination}>
              <div style={styles.paginationInfo}>
                Mostrando <strong>{((pagination.page - 1) * pagination.limit) + 1}</strong> a{' '}
                <strong>{Math.min(pagination.page * pagination.limit, pagination.total)}</strong> de{' '}
                <strong>{pagination.total}</strong> resultados
              </div>
              <div style={styles.paginationButtons}>
                <button
                  onClick={() => fetchReadings(pagination.page - 1)}
                  disabled={pagination.page <= 1}
                  style={{
                    ...styles.pageButton,
                    opacity: pagination.page <= 1 ? 0.5 : 1,
                    cursor: pagination.page <= 1 ? 'not-allowed' : 'pointer'
                  }}
                >
                  Anterior
                </button>
                
                {[...Array(Math.min(5, pagination.pages))].map((_, i) => {
                  const pageNum = i + 1;
                  return (
                    <button
                      key={pageNum}
                      onClick={() => fetchReadings(pageNum)}
                      style={
                        pageNum === pagination.page
                          ? {...styles.pageButton, ...styles.activePageButton}
                          : styles.pageButton
                      }
                    >
                      {pageNum}
                    </button>
                  );
                })}
                
                <button
                  onClick={() => fetchReadings(pagination.page + 1)}
                  disabled={pagination.page >= pagination.pages}
                  style={{
                    ...styles.pageButton,
                    opacity: pagination.page >= pagination.pages ? 0.5 : 1,
                    cursor: pagination.page >= pagination.pages ? 'not-allowed' : 'pointer'
                  }}
                >
                  Siguiente
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      <style>{`
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
        
        input:focus {
          outline: none;
          border-color: #667eea !important;
          box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        button:hover {
          transform: translateY(-2px);
          box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
        }
        
        button:active {
          transform: translateY(0);
        }
      `}</style>
    </div>
  );
};

export default SensorDashboard;