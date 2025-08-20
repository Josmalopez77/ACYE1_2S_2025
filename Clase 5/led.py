import paho.mqtt.client as mqtt
import ssl
import RPi.GPIO as GPIO

LED_PIN = 4
GPIO.setmode(GPIO.BCM)
GPIO.setup(LED_PIN, GPIO.OUT)
GPIO.output(LED_PIN, GPIO.LOW)

broker = "34d52f5960aa4de68c98b72bdee68942.s1.eu.hivemq.cloud"  # Solo dominio
port = 8883
username = "hivemq.webclient.1755304058895"
password = "9Zf72F6J#ElY!.,waOqm"
topic = "LED"

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Conectado exitosamente al broker HiveMQ")
        client.subscribe(topic)
    else:
        print("Error en la conexión. Código:", rc)

def on_message(client, userdata, msg):
    mensaje = msg.payload.decode().strip().upper()
    print(f"📩 Mensaje recibido en {msg.topic}: {mensaje}")

    if mensaje == "ON":
        GPIO.output(LED_PIN, GPIO.HIGH)
        print("💡 LED ENCENDIDO")
    elif mensaje == "OFF":
        GPIO.output(LED_PIN, GPIO.LOW)
        print("💡 LED APAGADO")
    else:
        print("⚠ Mensaje no reconocido. Usa ON u OFF.")

client = mqtt.Client()
client.tls_set(tls_version=ssl.PROTOCOL_TLS)
client.username_pw_set(username, password)

client.on_connect = on_connect
client.on_message = on_message

try:
    client.connect(broker, port)
    client.loop_forever()
except KeyboardInterrupt:
    print("\n🛑 Saliendo...")
finally:
    GPIO.cleanup()
