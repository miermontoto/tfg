# Listado inicial de requisitos
## Requisitos funcionales
- **RF1. Integración de Datos**: El datalake ha de ser capaz de integrar datos provenientes de las fuentes de datos internas (e.g. bases de datos, repositorios...) de Okticket, así como de fuentes externas, incluyendo aplicaciones de terceros y otras bases de datos.
- **RF2. Transformación de Datos**: Debe ofrecer funcionalidades para transformar los datos a un formato coherente y estándar, sobre el que se pueda operar posteriormente.
- **RF3. Limpieza de Datos:** El sistema debe ser capaz de limpiar los datos, eliminando duplicados, valores nulos, errores y otros problemas de calidad de datos, asegurando su integridad y fiabilidad.
- **RF4. Gestión de Metadatos**: El sistema debe gestionar metadatos de manera eficaz, permitiendo a los usuarios entender el origen, el contenido y el contexto de los datos almacenados en el mismo.
- **RF5. Automatización del Flujo de Datos**: Automatización en la ingestión, transformación, y carga de datos (ETL) para asegurar la actualización y disponibilidad constante de los mismos.
- **RF6. Soporte para Análisis de Datos**: Debe permitir el análisis de datos complejos, incluyendo el procesamiento de grandes volúmenes de datos mediante búsquedas con el objetivo de segmentar la información. Deberá implementarse mediante un lenguaje o metalenguaje.
- **RF7. Interfaz de Consulta Flexible**: El datalake debe ofrecer una interfaz de consulta flexible y potente, permitiendo a los usuarios realizar búsquedas complejas y obtener insights de los datos integrados. El sistema ha de estar pensado para poder ofrecer diferentes salidas de datos como pueden ser una intranet y consultas para clientes de la plataforma base. La interfaz ha de ser capaz de mostrar
datos relevantes sobre toda la información aglomerada (dashboards).
  - **RF7.1. Interfaz interna:** Interfaz de consulta para los empleados de Okticket a través de una intranet.
  - **RF7.2. Interfaz externa:** Interfaz de consulta para los clientes de Okticket a través de la plataforma base o algún otro medio de consulta.
- **RF8. Integración**: Debe poder ofrecer un sistema que permita la integración con otras aplicaciones, facilitando la extracción, carga y manipulación de datos desde sistemas externos.
- **RF9. Gestión de la Calidad de Datos**: Herramientas y procesos para monitorear y mejorar continuamente la calidad de los datos almacenados en el datalake.

## Requisitos no funcionales
- **RNF1. Escalabilidad**: Capacidad de escalar horizontal y verticalmente para manejar el aumento en volumen de datos sin degradar el rendimiento o la disponibilidad.
- **RNF2. Disponibilidad**: Alta disponibilidad del sistema, incluyendo redundancia y mecanismos de recuperación y tolerancia a fallos para asegurar el acceso continuo a los datos.
- **RNF3. Seguridad de la información**: Implementación de mecanismos de seguridad avanzados, incluyendo control de acceso basado en roles, encriptación de datos en reposo y en tránsito, auditorías de seguridad y protección contra amenazas internas y externas.
- **RNF4. Rendimiento**: Capacidad de minimizar los tiempos de respuesta atendiendo a grandes volúmenes de información y/o consultas complejas.
- **RNF5. Eficiencia de costes**: Optimización del uso de recursos para minimizar los costes operativos y de almacenamiento, incluyendo el uso eficiente del almacenamiento y los costes de despliegue asociados a los servicios cloud.
- **RNF6. Mantenibilidad**: Facilidad para actualizar, configurar y mantener el sistema, incluyendo la documentación adecuada y el soporte para la detección y solución de problemas mediante el uso de patrones
y buenas prácticas de desarrollo.
- **RNF7. Cumplimiento normativo y privacidad**: Asegurar que el sistema cumple con todas las leyes y regulaciones relevantes con la GDPR, alineándose con la normativa de la plataforma sobre la que se origina.
