---
id: es-git-branching
title: Ramas, merge y rebase
language: es
family: devops
---
Las ramas de Git son punteros baratos, y esa baratura habilita el flujo moderno: una rama corta por cada cambio, integrada mediante pull request y borrada al fusionar.

Integrar tiene dos filosofías. `git merge` une dos líneas de historia con un commit de fusión que tiene dos padres: la historia es veraz pero se llena de rombos. `git rebase` reescribe tus commits uno a uno sobre la punta de la rama destino: la historia queda lineal y legible, al precio de ser una reescritura. La regla social es absoluta: nunca rebases commits que otros ya tienen; reserva el rebase para ramas locales aún no compartidas.

Los conflictos no son errores sino solapamientos que requieren criterio humano: Git marca las regiones en disputa, tú eliges el resultado, añades y continúas. Un conflicto se resuelve mejor pronto — integra la rama base con frecuencia para trocearlos.

Herramientas de cirugía fina: `git cherry-pick` copia un commit suelto a otra rama (típico para hotfixes), `git stash` aparta cambios sin confirmar para cambiar de contexto, y el rebase interactivo (`-i`) reordena, funde y reescribe commits antes de publicar, convirtiendo una serie caótica de "wip" en una narración revisable.

El criterio final: la historia publicada es un documento para el equipo; edítala antes de publicar, jamás después.
