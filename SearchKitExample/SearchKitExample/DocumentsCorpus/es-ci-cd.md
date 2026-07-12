---
id: es-ci-cd
title: Integración y entrega continuas
language: es
family: devops
---
La integración continua (CI) automatiza la verificación de cada cambio: cada push dispara una máquina que compila, ejecuta tests y analiza el código. Su valor es el tiempo de detección: un fallo encontrado a los cinco minutos del commit se arregla en caliente; el mismo fallo tres semanas después exige arqueología.

La entrega continua (CD) extiende la automatización hasta el despliegue: artefactos construidos, firmados y publicados sin manos humanas. En el mundo Apple eso significa compilar con xcodebuild, gestionar certificados y perfiles de aprovisionamiento (el eterno dolor, domesticado por fastlane match), y subir a TestFlight.

Las opciones para iOS: Xcode Cloud, integrado en Xcode y App Store Connect; GitHub Actions con runners macOS, flexible y ubicuo; y fastlane como capa de automatización que funciona sobre cualquiera — sus lanes descriptibles (build, test, beta, release) son la lingua franca del CD móvil.

Un pipeline sano es rápido (menos de quince minutos o los desarrolladores dejan de mirar), determinista (los tests intermitentes se arreglan o se apartan, nunca se reintentan a ciegas), y disciplinado con los secretos: claves de firma y tokens de API viven en el almacén del CI, jamás en el repositorio.

El principio director: si un paso del release requiere recordar algo, fallará; escríbelo como código.
