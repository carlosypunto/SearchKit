---
id: es-terminal-zsh
title: Productividad en la terminal
language: es
family: devops
---
La terminal es la herramienta con mejor relación aprendizaje-beneficio para un desarrollador. Las interfaces gráficas optimizan lo ocasional; la línea de comandos optimiza lo repetido, y el desarrollo está hecho de repeticiones.

El modelo Unix es composición: programas pequeños que hacen una cosa, conectados por tuberías. `grep` filtra, `sort` ordena, `uniq -c` cuenta, `wc` mide; encadenados con `|`, responden preguntas que ninguna GUI tiene previstas. La redirección (`>`, `>>`, `2>&1`) dirige los flujos a ficheros o entre sí.

En zsh, el shell por defecto de macOS, la productividad se acumula en detalles: autocompletado con Tab (extensible por herramienta), búsqueda histórica con Ctrl+R, globbing avanzado (`**/*.swift` recorre recursivamente), y alias y funciones en `.zshrc` que convierten comandos de cuarenta caracteres en tres letras.

El kit moderno merece adopción: `ripgrep` busca en código respetando el gitignore a velocidad absurda, `fzf` añade filtrado difuso interactivo a cualquier lista (histórico, ficheros, ramas), `fd` reemplaza a `find` con sintaxis humana, y `jq` transforma JSON en la tubería.

La inversión se amortiza sola: cada tarea que scripteas deja de consumir atención, y la atención es el recurso escaso.
