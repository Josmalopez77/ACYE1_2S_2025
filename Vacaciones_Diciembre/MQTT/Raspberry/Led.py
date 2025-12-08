import RPi.GPIO as GPIO
import time

LED_PIN = 4  # Pin donde está conectado el LED

GPIO.setmode(GPIO.BCM)
GPIO.setup(LED_PIN, GPIO.OUT)

try:
    while True:
        GPIO.output(LED_PIN, GPIO.HIGH)  # Encender el LED
        time.sleep(3)                     # Esperar 1 segundo
        GPIO.output(LED_PIN, GPIO.LOW)   # Apagar el LED
        time.sleep(3)        
                     # Esperar 1 segundo
except KeyboardInterrupt:
    print("Programa terminado por el usuario.")
finally:
    GPIO.cleanup()  # Limpiar la configuración de los pines GPIO