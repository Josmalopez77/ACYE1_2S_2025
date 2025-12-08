import React, { useState, useEffect } from 'react';
import { Power, Wifi, WifiOff, Activity } from 'lucide-react';

const API_URL = 'http://localhost:3001/api';

export default function LEDControlDashboard() {
  const [ledStatus, setLedStatus] = useState('OFF');
  const [isConnected, setIsConnected] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [lastUpdate, setLastUpdate] = useState(null);
  const [error, setError] = useState(null);

  // Verificar estado inicial y conexión
  useEffect(() => {
    checkHealth();
    fetchStatus();
    
    // Polling cada 2 segundos para mantener sincronizado
    const interval = setInterval(fetchStatus, 2000);
    return () => clearInterval(interval);
  }, []);

  const checkHealth = async () => {
    try {
      const response = await fetch(`${API_URL}/health`);
      const data = await response.json();
      setIsConnected(data.mqtt_connected);
    } catch (err) {
      setIsConnected(false);
      setError('No se puede conectar al servidor');
    }
  };

  const fetchStatus = async () => {
    try {
      const response = await fetch(`${API_URL}/led/status`);
      const data = await response.json();
      setLedStatus(data.status);
      setLastUpdate(new Date(data.timestamp));
      setError(null);
    } catch (err) {
      setError('Error al obtener estado');
    }
  };

  const toggleLED = async () => {
    setIsLoading(true);
    setError(null);
    
    const newAction = ledStatus === 'ON' ? 'OFF' : 'ON';
    
    try {
      const response = await fetch(`${API_URL}/led/control`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: newAction })
      });
      
      const data = await response.json();
      
      if (data.success) {
        // Esperar un momento para que el mensaje MQTT se procese
        setTimeout(fetchStatus, 300);
      } else {
        setError('Error al enviar comando');
      }
    } catch (err) {
      setError('Error de conexión');
    } finally {
      setIsLoading(false);
    }
  };

  const isOn = ledStatus === 'ON';

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center gap-2 mb-3">
            <Activity className="w-6 h-6 text-purple-400" />
            <h1 className="text-3xl font-bold text-white">LED Control</h1>
          </div>
          <p className="text-slate-400 text-sm">Sistema de control remoto MQTT</p>
        </div>

        {/* Main Card */}
        <div className="bg-white/10 backdrop-blur-lg rounded-3xl p-8 shadow-2xl border border-white/20">
          
          {/* Connection Status */}
          <div className="flex items-center justify-between mb-6 pb-6 border-b border-white/10">
            <span className="text-slate-300 text-sm font-medium">Estado de Conexión</span>
            <div className="flex items-center gap-2">
              {isConnected ? (
                <>
                  <Wifi className="w-4 h-4 text-green-400" />
                  <span className="text-green-400 text-sm font-medium">Conectado</span>
                </>
              ) : (
                <>
                  <WifiOff className="w-4 h-4 text-red-400" />
                  <span className="text-red-400 text-sm font-medium">Desconectado</span>
                </>
              )}
            </div>
          </div>

          {/* LED Status Display */}
          <div className="text-center mb-8">
            <div className="relative inline-block mb-4">
              <div className={`w-32 h-32 rounded-full transition-all duration-500 ${
                isOn 
                  ? 'bg-gradient-to-br from-yellow-300 to-yellow-500 shadow-[0_0_60px_rgba(250,204,21,0.6)]' 
                  : 'bg-gradient-to-br from-slate-700 to-slate-800 shadow-lg'
              }`}>
                <div className={`absolute inset-0 rounded-full transition-opacity duration-500 ${
                  isOn ? 'opacity-100' : 'opacity-0'
                }`}>
                  <div className="absolute inset-4 rounded-full bg-yellow-200 animate-pulse"></div>
                </div>
              </div>
            </div>
            
            <h2 className={`text-2xl font-bold mb-1 transition-colors duration-300 ${
              isOn ? 'text-yellow-300' : 'text-slate-400'
            }`}>
              {isOn ? 'Encendido' : 'Apagado'}
            </h2>
            <p className="text-slate-400 text-xs">
              {lastUpdate && `Actualizado: ${lastUpdate.toLocaleTimeString()}`}
            </p>
          </div>

          {/* Control Button */}
          <button
            onClick={toggleLED}
            disabled={isLoading || !isConnected}
            className={`w-full py-4 rounded-2xl font-semibold text-white text-lg transition-all duration-300 flex items-center justify-center gap-3 ${
              isOn
                ? 'bg-gradient-to-r from-red-500 to-pink-500 hover:from-red-600 hover:to-pink-600 shadow-lg hover:shadow-red-500/50'
                : 'bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 shadow-lg hover:shadow-green-500/50'
            } disabled:opacity-50 disabled:cursor-not-allowed active:scale-95`}
          >
            <Power className="w-5 h-5" />
            {isLoading ? 'Procesando...' : isOn ? 'Apagar LED' : 'Encender LED'}
          </button>

          {/* Error Message */}
          {error && (
            <div className="mt-4 p-3 bg-red-500/20 border border-red-500/30 rounded-xl">
              <p className="text-red-300 text-sm text-center">{error}</p>
            </div>
          )}

          {/* Info Footer */}
          <div className="mt-6 pt-6 border-t border-white/10">
            <div className="grid grid-cols-2 gap-4 text-center">
              <div>
                <p className="text-slate-500 text-xs mb-1">Protocolo</p>
                <p className="text-white text-sm font-medium">MQTT</p>
              </div>
              <div>
                <p className="text-slate-500 text-xs mb-1">Estado</p>
                <p className={`text-sm font-medium ${isOn ? 'text-yellow-300' : 'text-slate-400'}`}>
                  {ledStatus}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <p className="text-center text-slate-500 text-xs mt-6">
          Control IoT • HiveMQ Broker • Node.js Backend
        </p>
      </div>
    </div>
  );
}