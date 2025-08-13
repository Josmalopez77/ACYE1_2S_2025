import time
import board
import adafruit_dht
from datetime import datetime
from pymongo import MongoClient

# Configuración de la conexión a MongoDB, la da automaticamente solo cambiar password
url = "mongodb+srv://usuario:password@cluster.e1gykov.mongodb.net/?retryWrites=true&w=majority&appName=ACYE1"

client = MongoClient(url)
db = client.get_database("sensor_data") #nombre de la base de datos
collection = db.get_collection("dht11_readings") #nombre de la colección

dhtDevice = adafruit_dht.DHT11(board.D4) 

while True:
    try:
        temperature_c = dhtDevice.temperature
        humidity = dhtDevice.humidity
        
        if temperature_c is not None and humidity is not None:
            data = {
                "temperature": float(temperature_c),
                "humidity": float(humidity),
                "timestamp": datetime.now()
            }
            collection.insert_one(data)
            print(f"Temperature: {temperature_c}")
            print(f"Humedad: {humidity}")
        else:
            print("Error: No se pudo leer la temperatura o la humedad.")
    except RuntimeError as error:
        print(f"Error reading temperature: {error}")
    time.sleep(5)
