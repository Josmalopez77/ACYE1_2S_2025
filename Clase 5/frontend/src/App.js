const express = require('express');
const mqtt = require('mqtt');
const cors = require('cors');
// Agrega la carga de dotenv al inicio
require('dotenv').config(); 

const app = express();
// Usa la variable de entorno o el valor por defecto
const port = process.env.API_PORT || 3001; 

// 1. Configuración MQTT (cargada desde .env)
const brokerUrl = process.env.MQTT_BROKER; 
const username = process.env.MQTT_USERNAME;
const password = process.env.MQTT_PASSWORD;
const topic = process.env.MQTT_TOPIC;

// Middleware
app.use(cors());
app.use(express.json());

// Estado actual del LED
let ledStatus = 'OFF';

// 2. Configuración del cliente MQTT 
const client = mqtt.connect(brokerUrl, {
    username: username,
    password: password,

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
    client.publish(topic, command, { qos: 1 }, (err) => { 
        if (err) {
            console.error('❌ Error al publicar:', err);
            return res.status(500).json({ 
                error: 'Error al enviar comando al LED' 
            });
        }
        
        console.log(`💡 Comando enviado: ${command}`);
        
        res.json({ 
            success: true,
            action: command,
            message: `Comando publicado: ${command}`,
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
    console.log(`📡 Conectando al broker MQTT: ${brokerUrl}`);
});

// Manejo de cierre
process.on('SIGINT', () => {
    console.log('\n🛑 Cerrando servidor...');
    client.end();
    process.exit(0);
});