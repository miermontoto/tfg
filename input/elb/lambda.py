import json
import urllib.request
import gzip
import base64

LOGSTASH_URL = "http://logstash.okticket.io:8080"


def lambda_handler(event, context):
    # Decodificar y descomprimir los datos de log
    compressed_payload = base64.b64decode(event['awslogs']['data'])
    uncompressed_payload = gzip.decompress(compressed_payload)
    log_data = json.loads(uncompressed_payload)

    # Extraer y procesar eventos de log
    for log_event in log_data['logEvents']:
        # Preparar el mensaje de log
        log_message = {
            'timestamp': log_event['timestamp'],
            'message': log_event['message'],
            'log_group': log_data['logGroup'],
            'log_stream': log_data['logStream']
        }

        # Enviar log a Logstash
        request = urllib.request.Request(LOGSTASH_URL)
        request.add_header('Content-Type', 'application/json')
        response = urllib.request.urlopen(request, json.dumps(log_message).encode('utf-8'))

    return {
        'statusCode': 200,
        'body': json.dumps('Logs enviados a Logstash exitosamente')
    }
