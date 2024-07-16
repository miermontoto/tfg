import json
import logging
import os
from datetime import datetime

import pymongo
from dotenv import load_dotenv

from kafka import KafkaProducer

# Configurar logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Cargar variables de entorno
load_dotenv()

# Conexion a MongoDB
mongo_client = pymongo.MongoClient(f"mongodb://{os.getenv('MONGO_HOST')}:{os.getenv('MONGO_PORT')}/")
db = mongo_client[os.getenv('MONGO_DB')]
logs_collection = db[os.getenv('MONGO_COLLECTION')]

# Configuracion del productor de Kafka
producer = KafkaProducer(bootstrap_servers=[os.getenv('KAFKA_BOOTSTRAP_SERVERS')],
                         value_serializer=lambda x: json.dumps(x).encode('utf-8'))


# Funcion para enviar logs a Kafka
def send_to_kafka(log):
    producer.send(os.getenv('KAFKA_TOPIC'), value=log)
    logging.info(f"Enviado log a Kafka: {log['_id']}")


# Bucle principal para obtener y enviar logs continuamente
def process_mongodb_logs():
    last_processed_time = datetime.min

    logging.info("Iniciando procesamiento de logs de MongoDB")
    while True:
        new_logs = logs_collection.find({"timestamp": {"$gt": last_processed_time}})

        for log in new_logs:
            log['_id'] = str(log['_id'])
            send_to_kafka(log)
            last_processed_time = log['timestamp']

        logging.info(f"Ultimo timestamp procesado: {last_processed_time}")


if __name__ == "__main__":
    process_mongodb_logs()
