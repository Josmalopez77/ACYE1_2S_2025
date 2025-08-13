const express = require('express');
const { MongoClient } = require('mongodb');
const cors = require('cors');
const http = require('http');
const socketIo = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Configuración de MongoDB
const uri = "mongodb+srv://3013781500101:jose1234@acye1.e1gykov.mongodb.net/?retryWrites=true&w=majority&appName=ACYE1";
const client = new MongoClient(uri);

let db;
let collection;

// Middleware
app.use(cors());
app.use(express.json());

// Conexión a MongoDB
async function connectDB() {
  try {
    await client.connect();
    console.log('Conectado a MongoDB');
    db = client.db("sensor_data");
    collection = db.collection("dht11_readings");
    
    // Monitorear cambios en la colección
    watchChanges();
  } catch (error) {
    console.error('Error conectando a MongoDB:', error);
  }
}

// Función para monitorear cambios en tiempo real
function watchChanges() {
  const changeStream = collection.watch();
  
  changeStream.on('change', async (change) => {
    if (change.operationType === 'insert') {
      // Emitir el nuevo dato a todos los clientes conectados
      const latestData = await getLatestReading();
      io.emit('newReading', latestData);
    }
  });
}

// Función para obtener la lectura más reciente
async function getLatestReading() {
  try {
    const latest = await collection
      .findOne({}, { sort: { timestamp: -1 } });
    return latest;
  } catch (error) {
    console.error('Error obteniendo última lectura:', error);
    return null;
  }
}

// Rutas de la API

// Obtener todas las lecturas con paginación (sin filtros)
app.get('/api/readings', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const skip = (page - 1) * limit;
    
    const readings = await collection
      .find({})
      .sort({ timestamp: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();
    
    const total = await collection.countDocuments();
    
    res.json({
      data: readings,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error obteniendo lecturas:', error);
    res.status(500).json({ error: 'Error del servidor' });
  }
});

// Obtener la lectura más reciente
app.get('/api/readings/latest', async (req, res) => {
  try {
    const latest = await getLatestReading();
    res.json(latest);
  } catch (error) {
    console.error('Error obteniendo última lectura:', error);
    res.status(500).json({ error: 'Error del servidor' });
  }
});

// Obtener estadísticas
app.get('/api/stats', async (req, res) => {
  try {
    const stats = await collection.aggregate([
      {
        $group: {
          _id: null,
          avgTemperature: { $avg: "$temperature" },
          avgHumidity: { $avg: "$humidity" },
          maxTemperature: { $max: "$temperature" },
          minTemperature: { $min: "$temperature" },
          maxHumidity: { $max: "$humidity" },
          minHumidity: { $min: "$humidity" },
          count: { $sum: 1 }
        }
      }
    ]).toArray();
    
    res.json(stats[0] || {});
  } catch (error) {
    console.error('Error obteniendo estadísticas:', error);
    res.status(500).json({ error: 'Error del servidor' });
  }
});

// Conexión de Socket.IO
io.on('connection', (socket) => {
  console.log('Cliente conectado:', socket.id);
  
  // Enviar la última lectura al conectarse
  getLatestReading().then(latest => {
    if (latest) {
      socket.emit('newReading', latest);
    }
  });
  
  socket.on('disconnect', () => {
    console.log('Cliente desconectado:', socket.id);
  });
});

const PORT = process.env.PORT || 3001;

connectDB().then(() => {
  server.listen(PORT, () => {
    console.log(`Servidor corriendo en puerto ${PORT}`);
  });
});

// Cerrar conexión al finalizar
process.on('SIGINT', async () => {
  console.log('Cerrando conexión a MongoDB...');
  await client.close();
  process.exit(0);
});