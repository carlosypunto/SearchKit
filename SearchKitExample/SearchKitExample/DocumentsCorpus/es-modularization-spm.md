---
id: es-modularization-spm
title: Modularización con Swift Package Manager
language: es
family: architecture
---
Modularizar es partir la app en paquetes con fronteras explícitas. Swift Package Manager convirtió esta práctica en infraestructura gratuita: paquetes locales en el mismo repositorio, declarados en un manifiesto Package.swift que es código Swift.

Las motivaciones son concretas. Tiempos de compilación: los módulos sin cambios no se recompilan, y el enlace incremental mejora. Fronteras reales: el control de acceso `public`/`internal` pasa a significar algo — lo no público es invisible entre módulos, y las dependencias entre capas son declaraciones verificables en vez de convenciones violables. Previews y tests más rápidos: una feature aislada compila sola, sin arrastrar la app entera.

Una descomposición típica: módulos de feature (Búsqueda, Perfil, Ajustes) sobre módulos de servicios (Red, Persistencia, Analítica) sobre módulos base (Modelos de dominio, Extensiones, DesignSystem). La regla de oro es que las dependencias fluyen hacia abajo y nunca lateralmente entre features — dos features que necesitan hablar lo hacen a través de una abstracción inferior.

Los tropiezos habituales: el módulo "Común" que se convierte en vertedero acoplado a todo; los recursos (imágenes, strings) que ahora viven en `Bundle.module`; y la sobre-modularización temprana — quince paquetes para tres pantallas es ingeniería de currículum.

Empieza por extraer el dominio y los servicios; las features pueden esperar a que el equipo crezca.
