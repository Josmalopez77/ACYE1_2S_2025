import time
import board
import adafruit_dht

dht_device = adafruit_dht.DHT11(board.D4)

while True:
    try:
        temperature_c = dht_device.temperature
        humidity = dht_device.humidity

        if temperature_c is not None and humidity is not None:
            print("Temperatura: {:.1f} C".format(temperature_c))
            print("Humedad: {:.1f} %".format(humidity))
        else:
            print("Error: No se pudo leer el sensor. Reintentando...")

    except RuntimeError as error:
        print("Error de lectura: {}".format(error.args[0]))

    time.sleep(5)