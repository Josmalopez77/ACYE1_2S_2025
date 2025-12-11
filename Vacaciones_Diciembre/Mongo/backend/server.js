const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors({
  origin: 'http://localhost:3000',
  credentials: true
}));
app.use(express.json());

// Variables de entorno
const MONGO_URI = process.env.MONGO_URI;
const MONGO_DB = process.env.MONGO_DB;
const MONGO_COLLECTION = process.env.MONGO_COLLECTION;
const PORT = process.env.PORT || 5000;

// Cliente MongoDB
let db;
let collection;

// Conectar a MongoDB
MongoClient.connect(MONGO_URI)
  .then(client => {
    console.log('✅ Conectado a MongoDB');
    db = client.db(MONGO_DB);
    collection = db.collection(MONGO_COLLECTION);
  })
  .catch(err => {
    console.error('❌ Error conectando a MongoDB:', err);
    process.exit(1);
  });

// Rutas
// GET - Obtener todos los datos de sensores
app.get('/api/sensores', async (req, res) => {
  try {
    const datos = await collection
      .find({})
      .sort({ timestamp: -1 })
      .limit(100)
      .toArray();
    
    res.json(datos);
  } catch (error) {
    console.error('Error obteniendo datos:', error);
    res.status(500).json({ error: 'Error al obtener los datos' });
  }
});

// GET - Obtener el último dato
app.get('/api/sensores/ultimo', async (req, res) => {
  try {
    const ultimoDato = await collection
      .find({})
      .sort({ timestamp: -1 })
      .limit(1)
      .toArray();
    
    res.json(ultimoDato[0] || null);
  } catch (error) {
    console.error('Error obteniendo último dato:', error);
    res.status(500).json({ error: 'Error al obtener el último dato' });
  }
});

// GET - Obtener datos por rango de fechas
app.get('/api/sensores/rango', async (req, res) => {
  try {
    const { inicio, fin } = req.query;
    
    if (!inicio || !fin) {
      return res.status(400).json({ 
        error: 'Se requieren parámetros inicio y fin' 
      });
    }

    const datos = await collection
      .find({
        timestamp: {
          $gte: new Date(inicio),
          $lte: new Date(fin)
        }
      })
      .sort({ timestamp: 1 })
      .toArray();
    
    res.json(datos);
  } catch (error) {
    console.error('Error obteniendo datos por rango:', error);
    res.status(500).json({ error: 'Error al obtener los datos' });
  }
});

// GET - Estadísticas
app.get('/api/sensores/estadisticas', async (req, res) => {
  try {
    const datos = await collection
      .find({})
      .sort({ timestamp: -1 })
      .limit(100)
      .toArray();

    if (datos.length === 0) {
      return res.json({
        promedioTemp: 0,
        promedioHum: 0,
        maxTemp: 0,
        minTemp: 0,
        maxHum: 0,
        minHum: 0
      });
    }

    const temperaturas = datos.map(d => d.temperatura);
    const humedades = datos.map(d => d.humedad);

    const stats = {
      promedioTemp: (temperaturas.reduce((a, b) => a + b, 0) / temperaturas.length).toFixed(2),
      promedioHum: (humedades.reduce((a, b) => a + b, 0) / humedades.length).toFixed(2),
      maxTemp: Math.max(...temperaturas),
      minTemp: Math.min(...temperaturas),
      maxHum: Math.max(...humedades),
      minHum: Math.min(...humedades),
      totalLecturas: datos.length
    };

    res.json(stats);
  } catch (error) {
    console.error('Error obteniendo estadísticas:', error);
    res.status(500).json({ error: 'Error al obtener estadísticas' });
  }
});

// Ruta de prueba
app.get('/', (req, res) => {
  res.json({ 
    mensaje: '🌡️ API de Sensores DHT11',
    endpoints: [
      'GET /api/sensores - Todos los datos',
      'GET /api/sensores/ultimo - Última lectura',
      'GET /api/sensores/rango?inicio=fecha&fin=fecha - Datos por rango',
      'GET /api/sensores/estadisticas - Estadísticas'
    ]
  });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});