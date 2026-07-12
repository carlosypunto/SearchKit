---
id: es-docker
title: Docker y contenedores
language: es
family: devops
---
Un contenedor empaqueta un proceso con todo su entorno — binarios, librerías, configuración — y lo ejecuta aislado sobre el kernel del anfitrión. Frente a la máquina virtual, que emula hardware y arranca un sistema operativo entero, el contenedor pesa megabytes y arranca en milisegundos. El "en mi máquina funciona" muere aquí: la imagen que pasa los tests es el mismo artefacto que corre en producción.

El Dockerfile describe la imagen por capas: una imagen base, ficheros copiados, comandos ejecutados. Cada instrucción crea una capa cacheable — el orden importa: lo que cambia poco (dependencias) va antes que lo que cambia siempre (tu código), para que las reconstrucciones aprovechen la caché. Los builds multi-etapa compilan en una imagen completa y copian solo el binario a una imagen final mínima.

Para un desarrollador Swift, Docker es la vía natural de desplegar Vapor (imágenes oficiales de Swift para Linux) y de levantar dependencias de desarrollo — un Postgres efímero con `docker run` en vez de instalaciones locales. Docker Compose orquesta el conjunto: base de datos, caché y API declaradas en un YAML, levantadas con un comando.

Higiene mínima: imágenes pequeñas (alpine o slim), nunca secretos horneados en capas, y usuario no-root en producción.
