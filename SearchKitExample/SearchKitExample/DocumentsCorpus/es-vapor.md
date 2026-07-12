---
id: es-vapor
title: Servidores Swift con Vapor
language: es
family: web-backend
---
Vapor es el framework de servidor más consolidado del ecosistema Swift: rutas, middleware, ORM, websockets y cliente HTTP sobre SwiftNIO, la base de red asíncrona y de alto rendimiento. Para un desarrollador iOS, la promesa es compartir lenguaje, tipos y hasta paquetes entre app y backend.

Un proyecto arranca con la CLI (`vapor new`) y define rutas en una sintaxis directa: `app.get("usuarios", ":id")` extrae parámetros tipados de la URL. El contenido entra y sale con `Content`, una extensión de Codable: los DTOs se decodifican del cuerpo automáticamente y las respuestas se serializan igual.

Fluent, el ORM, modela tablas como clases con property wrappers (`@ID`, `@Field`, `@Parent`) y soporta Postgres, MySQL y SQLite. Las migraciones son código versionado que evoluciona el esquema. El middleware intercepta la cadena petición-respuesta para autenticación, CORS o logging.

Con async/await, los handlers son funciones async que devuelven Content — el modelo mental es idéntico al de una app moderna. El despliegue típico es un contenedor Docker en cualquier nube, o plataformas gestionadas.

¿Cuándo elegirlo? Equipos Swift que quieren un backend a medida sin cambiar de lenguaje, APIs para sus propias apps, o servicios donde compartir los DTOs en un paquete SPM elimina toda una clase de errores de contrato.
