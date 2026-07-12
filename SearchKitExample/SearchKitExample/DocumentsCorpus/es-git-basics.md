---
id: es-git-basics
title: Git esencial
language: es
family: devops
---
Git es un sistema de control de versiones distribuido: cada clon contiene la historia completa del proyecto, y casi todas las operaciones son locales e instantáneas. Entender su modelo mental — no memorizar comandos — es lo que separa usarlo con confianza de usarlo con miedo.

Los ficheros transitan tres zonas: el directorio de trabajo (tus ediciones), el área de preparación o staging (`git add` selecciona qué entra en la próxima foto) y el repositorio (`git commit` sella la foto con mensaje, autor y fecha). El staging permite commits quirúrgicos: de diez ficheros tocados, confirmar solo los tres que forman un cambio coherente.

Cada commit apunta a sus padres, formando un grafo dirigido; una rama no es más que una etiqueta móvil sobre un commit, por eso crear ramas en Git es gratis. `git log` recorre la historia, `git diff` compara zonas, `git status` orienta siempre.

Con remotos, el ciclo es `pull` para traer e integrar, `push` para publicar. Los mensajes de commit son documentación para tu yo futuro: una línea de resumen en imperativo y, si hace falta, un cuerpo explicando el porqué.

Consejo antipánico: antes de operaciones que reescriben historia, `git branch respaldo` crea una salida de emergencia gratuita, y `git reflog` recuerda dónde estuvo todo.
