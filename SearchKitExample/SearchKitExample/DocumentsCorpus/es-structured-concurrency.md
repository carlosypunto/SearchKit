---
id: es-structured-concurrency
title: Concurrencia estructurada
language: es
family: swift-concurrency
---
La concurrencia estructurada organiza las tareas en un árbol: toda tarea hija nace dentro del ámbito de su padre y no puede sobrevivirlo. Esta jerarquía aporta tres garantías: la cancelación se propaga hacia abajo, los errores suben hacia arriba, y ninguna tarea queda huérfana ejecutándose sin control.

`async let` lanza trabajo concurrente ligado al ámbito actual: declaras varias `async let` seguidas y las esperas juntas, obteniendo paralelismo con sintaxis mínima. Para un número dinámico de tareas está `withTaskGroup` y su variante throwing: añades tareas al grupo, consumes resultados a medida que terminan, y el grupo no retorna hasta que todas acaban.

La cancelación es cooperativa. Cancelar una tarea marca una bandera; el código debe comprobarla con `Task.checkCancellation()` o `Task.isCancelled` en los puntos oportunos, típicamente dentro de bucles largos o antes de operaciones caras. Ignorar la cancelación desperdicia trabajo; comprobarla en exceso ensucia el código.

Las tareas no estructuradas (`Task { }` y `Task.detached`) escapan del árbol y deben gestionarse a mano. Úsalas solo en las fronteras: reaccionar a un botón, arrancar trabajo desde código síncrono. Dentro del mundo async, deja que la estructura trabaje por ti.

Los task groups premian unos cuantos idiomas que no se deducen de su firma. Los resultados llegan en orden de finalización, no de envío, así que cuando el orden importa conviene que cada hija devuelva su índice junto al valor y reensamblar al final — el patrón clásico es rellenar un array predimensionado o construir un diccionario indexado. Para acotar la concurrencia sobre una lista grande de trabajo, siembra el grupo con N tareas y añade el siguiente elemento cada vez que una termina; esa ventana deslizante mantiene N tareas en vuelo sin materializar miles por adelantado. Y recuerda que el ámbito del grupo es el punto de sincronización: mutar estado compartido desde dentro de los closures de las hijas es un data race, mientras que recoger valores por el iterador async del grupo es seguro por construcción.

La prioridad y la herencia también siguen el árbol. Una tarea hija hereda la prioridad de su padre, los valores task-local y — en `async let` y grupos — la cancelación de sus ancestros. La escalada de prioridad se propaga sola cuando una tarea de prioridad alta espera a una de prioridad baja, lo que desactiva la mayoría de los escenarios de inversión de prioridad sin intervención manual. Los valores task-local merecen mención aparte: viajan con el árbol de tareas, no con los hilos, de modo que los identificadores de petición y el contexto de logging fluyen por el código concurrente sin diccionarios globales indexados por hilo.

Los patrones pre-async a los que esto sustituye explican el valor del diseño. Las pirámides de callbacks perdían el contexto de error entre saltos y hacían casi imposible razonar sobre fallos parciales. Los dispatch groups exigían una contabilidad manual de enter/leave que se desincronizaba en cada refactor. Las Operations prometían cancelación pero solo la cumplían cuando cada subclase comprobaba diligentemente `isCancelled`. La concurrencia estructurada no añadió tanto capacidad como eliminó modos de fallo: el compilador impone ahora lo que antes se pedía por convención.

Una lista de comprobación práctica al revisar código Swift concurrente: cada `Task { }` debería responder a "¿quién cancela esto, y cuándo?" — si la respuesta es nadie, probablemente debería ser una tarea hija dentro de un ámbito. Cada bucle que lanza hijas debería declarar su cota de concurrencia. Cada hija de larga duración debería mostrar dónde comprueba la cancelación. Y `Task.detached` debería llevar un comentario que justifique por qué renuncia a la prioridad, los task-locals y el contexto de actor, porque noventa y nueve de cada cien veces lo correcto es un `Task { }` normal o una tarea hija.
