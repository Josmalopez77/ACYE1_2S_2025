import time
import adafruit_dht
import board
from pymongo import MongoClient
from dotenv import load_dotenv
import os
from datetime import datetime

# Cargar variables de entorno
load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")
MONGO_DB = os.getenv("MONGO_DB")
MONGO_COLLECTION = os.getenv("MONGO_COLLECTION")
INTERVALO = int(os.getenv("INTERVALO_SEG", 10))  # default = 10s

# Conexión a MongoDB
client = MongoClient(MONGO_URI)
db = client[MONGO_DB]
collection = db[MONGO_COLLECTION]

print("Conexión a MongoDB establecida.")

# Inicializar sensor
dhtDevice = adafruit_dht.DHT11(board.D4)

try:
    while True:
        try:
            temperature = dhtDevice.temperature
            humidity = dhtDevice.humidity

            print(f"Temp: {temperature}°C  Hum: {humidity}%")

            # Documento que se guardará en MongoDB
            data = {
                "temperatura": temperature,
                "humedad": humidity,
                "timestamp": datetime.utcnow()
            }

            # Insertar en MongoDB
            result = collection.insert_one(data)
            print("Datos guardados en MongoDB. ID:", result.inserted_id)

        except Exception as e:
            print("Error leyendo sensor:", e)

        time.sleep(INTERVALO)

except KeyboardInterrupt:
    print("Programa detenido por el usuario.")

finally:
    dhtDevice.exit()
    print("Sensor liberado correctamente.")
