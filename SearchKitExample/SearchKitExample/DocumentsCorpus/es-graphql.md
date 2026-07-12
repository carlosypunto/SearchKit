---
id: es-graphql
title: GraphQL desde el cliente móvil
language: es
family: web-backend
---
GraphQL sustituye la colección de endpoints REST por un único endpoint con lenguaje de consulta: el cliente declara exactamente qué campos necesita y el servidor responde con esa forma exacta. Para móvil, el atractivo es doble: adiós al over-fetching (descargar campos que no usas) y al under-fetching (encadenar tres peticiones para pintar una pantalla).

El esquema es el contrato central, tipado y con introspección: tipos, campos y relaciones consultables por herramientas. Las operaciones son de tres clases: queries para leer, mutations para escribir y subscriptions para datos en tiempo real sobre websockets.

Una pantalla de detalle pide en una sola consulta el usuario, sus pedidos recientes y el estado de envío, navegando el grafo de relaciones — lo que en REST serían tres viajes o un endpoint a medida por pantalla.

En iOS, Apollo es el cliente de referencia: genera tipos Swift desde el esquema y las consultas (tipado de extremo a extremo), y aporta caché normalizada que reutiliza datos ya descargados y actualiza vistas al mutar.

Los costes existen: la caché HTTP clásica no aplica (todo es POST al mismo endpoint), el servidor debe protegerse de consultas patológicamente profundas, y el backend requiere resolvers bien diseñados para no convertir la flexibilidad del cliente en consultas N+1 a la base de datos.
