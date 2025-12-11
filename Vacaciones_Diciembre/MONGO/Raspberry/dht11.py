import adafruit_dht
import board
import time

dhtDevice = adafruit_dht.DHT11(board.D4)

try:
    while True:
        try:
            temperature = dhtDevice.temperature
            humidity = dhtDevice.humidity
            print(f"Temp: {temperature} °C   Hum: {humidity} %")

        except Exception as e:
            print("Error leyendo sensor:", e)

        time.sleep(2)

except KeyboardInterrupt:
    print("Saliendo del programa...")

finally:
    dhtDevice.exit()
    print("Sensor DHT liberado correctamente.")
