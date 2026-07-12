---
id: es-snapshot-testing
title: Snapshot testing de interfaces
language: es
family: testing
---
El snapshot testing verifica interfaces comparando contra una referencia grabada: la primera ejecución renderiza la vista y guarda una imagen (o texto) de referencia; las siguientes renderizan de nuevo y comparan píxel a píxel. Cualquier diferencia falla el test y muestra qué cambió.

Su punto fuerte es la amplitud barata: un test de pocas líneas protege el layout completo de una pantalla — tipografías, márgenes, colores, truncamientos — contra regresiones accidentales. Multiplicado por configuraciones, la cobertura crece geométricamente: modo oscuro, tamaños de Dynamic Type, idiomas con textos largos, anchos de dispositivo distintos.

La librería de referencia en Swift es swift-snapshot-testing de Point-Free, que soporta estrategias más allá de la imagen: jerarquías de vistas como texto, JSON codificado, incluso peticiones URLRequest — cualquier cosa comparable puede ser snapshot.

Sus riesgos exigen disciplina. El determinismo es crítico: fechas fijas, datos estáticos y mismo simulador (renderizados de GPU distintos producen diffs falsos). La revisión de cambios es el punto débil humano: cuando un cambio legítimo regenera cuarenta snapshots, la tentación de aprobar sin mirar es alta — y un snapshot aprobado a ciegas ya no protege nada. Trátalos como código en la revisión: cada imagen cambiada merece una mirada.

Complementan, no sustituyen: los snapshots detectan el qué cambió visualmente; los tests unitarios explican el porqué lógico.
