import json
import logging
import os
import time

from dotenv import load_dotenv
from kafka import KafkaProducer

# Configurar logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Cargar variables de entorno
load_dotenv()

# Configuracion del productor de Kafka
producer = KafkaProducer(bootstrap_servers=[os.getenv('KAFKA_BOOTSTRAP_SERVERS')],
                         value_serializer=lambda x: json.dumps(x).encode('utf-8'))


# Funcion para enviar logs a Kafka
def send_to_kafka(log):
    producer.send(os.getenv('KAFKA_TOPIC'), value=log)
    logging.info(f"Enviado log a Kafka: {log['timestamp']}")


# Funcion para analizar las lineas de log de Laravel
def parse_laravel_log(line):
    parts = line.split('] ')
    if len(parts) >= 3:
        timestamp = parts[0][1:]
        level = parts[1][1:-1]
        message = '] '.join(parts[2:])
        return {
            'timestamp': timestamp,
            'level': level,
            'message': message.strip()
        }
    return None


# Funcion principal para procesar logs de Laravel
def process_laravel_logs():
    logging.info(f"Iniciando procesamiento de logs de Laravel desde {os.getenv('LARAVEL_LOG_FILE')}")
    with open(os.getenv('LARAVEL_LOG_FILE'), 'r') as file:
        file.seek(0, 2)
        while True:
            line = file.readline()
            if not line:
                time.sleep(0.1)
                continue
            log_entry = parse_laravel_log(line)
            if log_entry:
                send_to_kafka(log_entry)
            else:
                logging.warning(f"No se pudo analizar la linea: {line.strip()}")


if __name__ == "__main__":
    process_laravel_logs()
