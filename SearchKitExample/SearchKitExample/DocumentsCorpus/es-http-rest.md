---
id: es-http-rest
title: APIs REST y HTTP
language: es
family: web-backend
---
REST es el estilo arquitectónico dominante para APIs web: recursos identificados por URLs, manipulados con los verbos estándar de HTTP, comunicados normalmente en JSON y sin estado entre peticiones.

Los verbos tienen semántica precisa. GET lee sin efectos secundarios y es cacheable; POST crea o dispara acciones; PUT reemplaza un recurso completo de forma idempotente; PATCH modifica parcialmente; DELETE elimina. La idempotencia — repetir la petición produce el mismo estado — decide qué operaciones pueden reintentarse con seguridad ante un timeout.

Los códigos de estado comunican el resultado: 200 OK, 201 Created, 204 sin contenido, 400 petición malformada, 401 sin autenticar, 403 sin permisos, 404 no encontrado, 429 demasiadas peticiones y 5xx errores del servidor. Un cliente robusto distingue entre errores reintentables (503, timeouts) y definitivos (400, 404).

El diseño de rutas sigue convenciones: sustantivos en plural (`/usuarios/42/pedidos`), anidamiento moderado, filtros y paginación por query string. Las cabeceras transportan autenticación (`Authorization: Bearer token`), negociación de contenido y control de caché con ETags.

Versiona la API desde el primer día — en la ruta o en cabeceras — porque los clientes móviles viejos seguirán vivos durante años y romperlos es romper usuarios.
