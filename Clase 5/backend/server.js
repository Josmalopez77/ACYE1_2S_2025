const express = require('express');
const mqtt = require('mqtt');
const cors = require('cors');

const app = express();
const port = 3001;

// Configuración MQTT (misma que tu código Python)
const broker = 'mqtts://34d52f5960aa4de68c98b72bdee68942.s1.eu.hivemq.cloud:8883';
const username = 'hivemq.webclient.1755376879964';
const password = '65ag$!iM.uKB,WbG94Yo';
const topic = 'LE D';

// Middleware
app.use(cors());
app.use(express.json());

// Estado actual del LED
let ledStatus = 'OFF';

// Configuración del cliente MQTT
const client = mqtt.connect(broker, {
    username: username,
    password: password,
    protocol: 'mqtts',
    port: 8883
});

// Eventos MQTT
client.on('connect', () => {
    console.log('✅ Conectado exitosamente al broker HiveMQ desde Node.js');
    client.subscribe(topic, (err) => {
        if (err) {
            console.error('❌ Error al suscribirse al topic:', err);
        } else {
            console.log(`📡 Suscrito al topic: ${topic}`);
        }
    });
});

client.on('message', (receivedTopic, message) => {
    const msg = message.toString().trim().toUpperCase();
    console.log(`📩 Mensaje recibido en ${receivedTopic}: ${msg}`);
    
    if (msg === 'ON' || msg === 'OFF') {
        ledStatus = msg;
    }
});

client.on('error', (err) => {
    console.error('❌ Error MQTT:', err);
});

// Rutas de la API
app.get('/api/led/status', (req, res) => {
    res.json({ 
        status: ledStatus,
        timestamp: new Date().toISOString()
    });
});

app.post('/api/led/control', (req, res) => {
    const { action } = req.body;
    
    if (!action) {
        return res.status(400).json({ 
            error: 'Se requiere el parámetro "action"' 
        });
    }
    
    const command = action.toString().trim().toUpperCase();
    
    if (command !== 'ON' && command !== 'OFF') {
        return res.status(400).json({ 
            error: 'Acción inválida. Usa "ON" o "OFF"' 
        });
    }
    
    // Publicar mensaje MQTT
    client.publish(topic, command, (err) => {
        if (err) {
            console.error('❌ Error al publicar:', err);
            return res.status(500).json({ 
                error: 'Error al enviar comando al LED' 
            });
        }
        
        ledStatus = command;
        console.log(`💡 Comando enviado: ${command}`);
        
        res.json({ 
            success: true,
            action: command,
            message: `LED ${command === 'ON' ? 'encendido' : 'apagado'}`,
            timestamp: new Date().toISOString()
        });
    });
});

// Ruta de salud
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'OK',
        mqtt_connected: client.connected,
        timestamp: new Date().toISOString()
    });
});

// Iniciar servidor
app.listen(port, () => {
    console.log(`🚀 Servidor ejecutándose en http://localhost:${port}`);
    console.log(`📡 Conectando al broker MQTT: ${broker}`);
});

// Manejo de cierre
process.on('SIGINT', () => {
    console.log('\n🛑 Cerrando servidor...');
    client.end();
    process.exit(0);
});