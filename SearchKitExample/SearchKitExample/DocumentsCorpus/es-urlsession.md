---
id: es-urlsession
title: Redes con URLSession
language: es
family: web-backend
---
`URLSession` es la puerta de red de las plataformas Apple. Con async/await, una petición se reduce a `let (data, response) = try await URLSession.shared.data(from: url)`, y el manejo de errores sigue los cauces normales de `throws`.

Una petición completa se construye con `URLRequest`: método HTTP, cabeceras (autenticación, content type) y cuerpo codificado con `JSONEncoder`. La respuesta llega en dos piezas: los datos crudos y una `HTTPURLResponse` cuyo `statusCode` debes comprobar — URLSession no considera error un 404; para ella, recibir respuesta ya es éxito de transporte.

La configuración de la sesión controla el comportamiento global: timeouts, política de caché, cabeceras adicionales y conectividad. Las sesiones en segundo plano (`background`) continúan descargas con la app suspendida, con la complejidad de delegados que eso implica.

El patrón de capa de red recomendable es fino: un tipo que construye requests desde endpoints tipados, ejecuta, valida el código de estado, decodifica al DTO esperado y traduce fallos a un error de dominio propio (sin conexión, no autorizado, servidor caído). Con un protocolo delante, los tests inyectan un transporte falso y verifican la lógica sin tocar la red — o se usa `URLProtocol` para interceptar a nivel de sistema.
