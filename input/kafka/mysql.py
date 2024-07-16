import json
import logging
import os
import time

import pymysql
from dotenv import load_dotenv
from kafka import KafkaProducer

# Configurar logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Cargar variables de entorno
load_dotenv()

# Configuracion de conexion a MySQL
mysql_config = {
    'host': os.getenv('MYSQL_HOST'),
    'user': os.getenv('MYSQL_USER'),
    'password': os.getenv('MYSQL_PASSWORD'),
    'database': os.getenv('MYSQL_DATABASE')
}

# Configuracion del productor de Kafka
producer = KafkaProducer(bootstrap_servers=[os.getenv('KAFKA_BOOTSTRAP_SERVERS')],
                         value_serializer=lambda x: json.dumps(x).encode('utf-8'))


# Funcion para enviar logs a Kafka
def send_to_kafka(log):
    producer.send(os.getenv('KAFKA_TOPIC'), value=log)
    logging.info(f"Enviado log a Kafka: ID {log['id']}")


# Funcion para obtener logs de MySQL
def fetch_mysql_logs(cursor, last_id):
    query = f"SELECT * FROM mysql_general_log WHERE id > {last_id} ORDER BY id ASC"
    cursor.execute(query)
    return cursor.fetchall()


# Funcion principal para procesar logs de MySQL
def process_mysql_logs():
    logging.info("Iniciando procesamiento de logs de MySQL")
    connection = pymysql.connect(**mysql_config)
    cursor = connection.cursor(pymysql.cursors.DictCursor)

    last_processed_id = 0

    while True:
        new_logs = fetch_mysql_logs(cursor, last_processed_id)

        for log in new_logs:
            send_to_kafka(log)
            last_processed_id = log['id']

        logging.info(f"Ultimo ID procesado: {last_processed_id}")
        time.sleep(1)


if __name__ == "__main__":
    process_mysql_logs()
