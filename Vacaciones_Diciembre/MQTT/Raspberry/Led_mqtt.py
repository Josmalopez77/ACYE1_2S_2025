import paho.mqtt.client as mqtt
import ssl
import RPi.GPIO as GPIO
from dotenv import load_dotenv
import os

load_dotenv() 

LED_PIN = 4  # Pin donde está conectado el LED
GPIO.setmode(GPIO.BCM)
GPIO.setup(LED_PIN, GPIO.OUT)

broker = os.environ.get("MQTT_BROKER")
port = int(os.environ.get("MQTT_PORT"))
username = os.environ.get("MQTT_USERNAME")
password = os.environ.get("MQTT_PASSWORD")
topic = os.environ.get("MQTT_TOPIC")

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Conectado al broker MQTT")
        client.subscribe(topic)
    else:
        print("Error de conexión, código:", rc)

def on_message(client, userdata, msg):
    message = msg.payload.decode()
    print(f"Mensaje recibido en {msg.topic}: {message}")
    if message.lower() == "on":
        GPIO.output(LED_PIN, GPIO.HIGH)  # Encender el LED
    elif message.lower() == "off":
        GPIO.output(LED_PIN, GPIO.LOW)   # Apagar el LED

client = mqtt.Client()
client.username_pw_set(username, password)
client.tls_set(cert_reqs=ssl.CERT_NONE)
client.tls_insecure_set(True)
client.on_connect = on_connect
client.on_message = on_message

try:
    client.connect(broker, port)
    client.loop_forever()
except KeyboardInterrupt:
    print("Desconectando...")
finally:
    GPIO.cleanup()