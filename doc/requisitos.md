# Listado inicial de requisitos
## Requisitos funcionales

- **RF1. Integración de Datos**: El datalake debe ser capaz de integrar datos de fuentes internas como las bases de datos de la empresa (MySQL y MongoDB), así como de fuentes externas como APIs RESTful y parseo de datos web mediante scraping. La integración debe incluir la capacidad de realizar operaciones CRUD en los datos.

- **RF2. Transformación de Datos**: Debe ofrecer funcionalidades para transformar los datos a un formato JSON estándar, permitiendo operaciones como la normalización de datos, la conversión de tipos de datos y la manipulación de fechas y horas.

- **RF3. Limpieza de Datos**: El sistema debe ser capaz de limpiar los datos, eliminando duplicados, valores nulos, y errores de formato. Debe ser capaz de detectar y manejar outliers, rellenar datos incompletos y resolver conflictos de datos.

- **RF4. Gestión de Metadatos**: El sistema debe gestionar metadatos, permitiendo a los usuarios entender el origen, el contenido y el contexto de los datos. A la hora de visualizar los datos, algunos de estos metadatos (como empresa de origen, fechas, etc.) deben ser mostrados en la interfaz de consulta.

- **RF5. Automatización del Flujo de Datos**: Automatización en la ingesta, transformación, y carga de datos (ETL) para asegurar la actualización y disponibilidad constante de los mismos. Debe soportar la programación de trabajos ETL y la monitorización de su estado y rendimiento.

- **RF6. Soporte para Análisis de Datos**: Debe permitir el análisis de datos complejos, incluyendo el procesamiento de grandes volúmenes de datos mediante búsquedas con el objetivo de segmentar la información. Deberá implementarse mediante un lenguaje de dominio específico (DSL), o bien un lenguaje ya existente como SQL.

- **RF7. Interfaz de Consulta Flexible**: El datalake debe ofrecer una interfaz de consulta flexible y potente, permitiendo a los usuarios realizar búsquedas complejas y obtener información de los datos integrados. La interfaz debe soportar consultas SQL y debe ser capaz de mostrar datos relevantes sobre toda la información aglomerada (dashboards).
	- **RF7.1. Interfaz interna:** Interfaz de consulta para los empleados de Okticket a través de una intranet. Debe soportar autenticación y autorización basada en roles.

	- **RF7.2. Interfaz externa:** Interfaz de consulta para los clientes de Okticket a través de la plataforma base o algún otro medio de consulta. Debe soportar autenticación y autorización basada en roles.

- **RF8. Gestión de la Calidad de Datos**: Herramientas y procesos para monitorear y mejorar continuamente la calidad de los datos almacenados en el datalake. Debe soportar la generación de informes de calidad de datos y la configuración de alertas basadas en umbrales de calidad de datos.

## Requisitos no funcionales
- **RNF1. Escalabilidad**: Capacidad de escalar el volumen de datos sin degradar el rendimiento o la disponibilidad.
- **RNF2. Disponibilidad**: Alta disponibilidad del sistema, incluyendo redundancia y mecanismos de recuperación y tolerancia a fallos para asegurar el acceso continuo a los datos.
- **RNF3. Seguridad de la información**: Implementación de mecanismos de seguridad avanzados, incluyendo control de acceso basado en roles, encriptación de datos en reposo y en tránsito, auditorías de seguridad y protección contra amenazas internas y externas.
- **RNF4. Rendimiento**: Capacidad de minimizar los tiempos de respuesta a menos de 2 segundos atendiendo a grandes volúmenes de información y/o consultas complejas.
- **RNF5. Eficiencia de costes**: Optimización del uso de recursos para minimizar los costes operativos y de almacenamiento, incluyendo el uso eficiente del almacenamiento y los costes de despliegue asociados a los servicios cloud.
- **RNF6. Mantenibilidad**: Facilidad para actualizar, configurar y mantener el sistema, incluyendo la documentación adecuada y el soporte para la detección y solución de problemas mediante el uso de patrones y buenas prácticas de desarrollo.
- **RNF7. Cumplimiento normativo y privacidad**: Asegurar que el sistema cumple con todas las leyes y regulaciones relevantes con la RGPD/LOPD, alineándose con la normativa de la plataforma sobre la que se origina.
