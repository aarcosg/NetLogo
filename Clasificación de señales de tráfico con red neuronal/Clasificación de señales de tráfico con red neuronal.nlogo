globals [
  data-list      ; Lista de pares [Entrada Salida] para entrenar el sistema
  entradas       ; Lista que contendrá cada una de las entradas individuales en el entrenamiento (binario)
  salidas        ; Lista que contendrá cada una de las salidas individuales en el entrenamiento (binario)
  epoch-error    ; error que se comete en cada iteración del entrenamiento
  contador-datos ; almacena el número de muestras que se han introducido para entrenar
  drawer         ; tortuga que se usa para dibujar los patrones que se deben reconocer
  test-data-list ; Lista de pares [Entrada Salida] para testear el sistema
  resultado-test ; Lista de tupla de tres [Entrada Clase Predicción]
]

links-own [peso]


breed [nodos-entrada nodo-entrada]
nodos-entrada-own [
  activacion
  dev
  p2
  patch-rel ;; referencia al patch del que tomó su color
]
breed [nodos-salida nodo-salida]
nodos-salida-own [activacion dev p2 id]
breed [nodos-ocultos nodo-oculto]
nodos-ocultos-own [activacion dev p2]


;;;
;;; Procedimientos de Setup
;;;


to setup
  clear-all

  ; Creación de la red
  setup-nodos
  setup-links

  ; Recoloreado de los nodos y links
  recolor

  limpia-fondo

  ; Inicialización de variables globales

  set epoch-error 0
  set contador-datos 0
  set data-list []

  ; Creación de la tortuga que dibuja los patrones en pequeño
  crt 1 [
    set drawer self
    set size (1 / 8)
    set shape "drawer"
    set color 32
    ]
  reset-ticks
end

to setup-nodos
  set-default-shape nodos-entrada "square"
  set-default-shape nodos-salida "nodo-neuronal"
  set-default-shape nodos-ocultos "nodo-neuronal"

  ; Creación de las neuronas que sirven de entrada. Una matriz de 40x40
  foreach sort patches
  [ask ? [
      sprout-nodos-entrada 1 [
        set activacion random-float 0.1
        set patch-rel ?
        set color [pcolor] of ?
        set size .5
        set shape "square"
        setxy (xcor / 2) - 9 (ycor / 2)
        ]
      ]
  ]

  ; Creación de neuronas de la capa intermedia
  foreach (n-values Num-nodos-ocultos [?]) [
    create-nodos-ocultos 1 [
      setxy 6 (- int (Num-nodos-ocultos / 2) + 1 + ?) * 1.5
      set activacion random-float 0.1
      set size 1.5
      ]
    ]

  ; Creación de las neuronas de salida
  let nombres-clases ["background" "ceda paso" "prohibido" "stop" "limite velocidad"]
  foreach (reverse n-values 5 [?]) [
    create-nodos-salida 1 [
      setxy 13 (? - 2) * 1.5
      set activacion random-float 0.1
      set size 1.5
      set label item ? nombres-clases
      set id ?
      set label-color orange
      ]
    ]
end

to setup-links
  conecta nodos-entrada nodos-ocultos
  conecta nodos-ocultos nodos-salida
end

to conecta [nodos1 nodos2]
  ask nodos1 [
    create-links-to nodos2 [
      set peso random-float 0.2 - 0.1
     hide-link
    ]
  ]
end

to recolor

  ifelse dataset = "HSV rojo"
    [
      ask turtles with [self != drawer][
        set color item (step activacion) [white yellow]
      ]
    ]
    [
      ask nodos-entrada[
        set color activacion * 140
      ]

      ask turtles with [self != drawer and not member? self nodos-entrada][
        set color item (step activacion) [white yellow]
      ]
    ]

  let MaxP max [abs peso] of links
  ask links [
    set thickness 0.05 * abs peso
    ifelse peso > 0
      [ set color lput (255 * abs peso / MaxP) [0 0 255]]
      [ set color lput (255 * abs peso / MaxP) [255 0 0]]
  ]
end

;; Limpia el fondo del mundo
to limpia-fondo
  ask patches [set pcolor black]
end

;;;
;;; Procedimiento de entrenamiento
;;;

to entrena
  set epoch-error 0
  ask links [set peso random-float 0.2 - 0.1]
  ; Repetimos las iteraciones deseadas
  repeat muestras-por-epoch [
    ; Para cada dato de entrenamiento
    foreach data-list [
      ; Recuperamos la entrada y salida deseada
      set entradas first bf ?
      set salidas last ?
      ; Cargamos la entrada en los nodos de entrada
      (foreach (sort nodos-entrada) entradas [
        ask ?1 [set activacion ?2]])
      ; Propagamos la señal
      propaga
      ; Propagamos hacia atrás el error respecto de la salida esperada
      back-propaga

    ]
    plotxy ticks epoch-error ;;plot the error
    set epoch-error (epoch-error / muestras-por-epoch)
    tick
  ]
end


;;;
;;; Procedimientos de Propagación
;;;

;; Propagación de la señal a lo largo de la red
to propaga
  ask nodos-ocultos [ set activacion calcula-activacion ]
  ask nodos-salida  [ set activacion calcula-activacion ]
  recolor
end

to-report calcula-activacion
  report sigmoide sum [[activacion] of end1 * peso] of my-in-links
end

;; Función sigmoide
to-report sigmoide [x]
  report 1 / (1 + e ^ (- x))
end

;; Función step
to-report step [x]
  ifelse x > 0.5
    [ report 1 ]
    [ report 0 ]
end

;; Propagación hacia atrás del error cometido en las salidas
to back-propaga
  let error-ejemplo 0
  ; Se calcula el error de las salidas
  (foreach (sort nodos-salida) salidas [
    ask ?1 [ set dev activacion * (1 - activacion) * (?2 - activacion) ]
    set error-ejemplo error-ejemplo + ( (?2 - [activacion] of ?1) ^ 2 )])
  ; Se acuumula el error medio de las salidas en el error del epoch actual
  set epoch-error epoch-error + (error-ejemplo / count nodos-salida)
  ; Se calcula el error en los nodos de la capa oculta
  ask nodos-ocultos [
    set dev activacion * (1 - activacion) * sum [peso * [dev] of end2] of my-out-links
  ]
  ; Se actualizan los pesos de las aristas
  ask links [
    set peso peso + tasa-aprendizaje * [dev] of end2 * [activacion] of end1
  ]
  set epoch-error epoch-error / 2
end


;;
;; Procedimientos de entrada
;;

;; Cargar datos de entrenamiento leídos de un fichero de texto
to carga-datos-entrenamiento [f]
  set data-list []
  if f = false [stop]
  file-open f
  while [not file-at-end?]
  [
    let linea (read-from-string (word "[" file-read-line "]"))
    let imagen first linea
    import-pcolors imagen
    let colores []
    ifelse dataset = "HSV rojo"
    [
      ;; Poner a 0 (blanco) o 1 (negro) los colores de la imagen que se utilizarán como entrada de la red
      foreach sort patches [set colores lput (ifelse-value ([pcolor] of ? >= 5) [0][1]) colores]
    ]
    [
      foreach sort patches [
        ;; Normalizar color del patch a un valor entre 0 y 0.99999 para que la función sigmoide no de error
        let val 0.99999 * ([pcolor] of ?) / 140
        set colores lput val colores
      ]
    ]

    ask nodos-entrada[
      set color [pcolor] of [patch-rel] of self
    ]

    let clase last linea
    let salida [0 0 0 0 1]
    if clase = 1 [set salida [0 0 0 1 0]]
    if clase = 2 [set salida [0 0 1 0 0]]
    if clase = 3 [set salida [0 1 0 0 0]]
    if clase = 4 [set salida [1 0 0 0 0]]
    set data-list lput (list imagen colores salida) data-list
    limpia-fondo
  ]

  file-close-all
  set contador-datos 5

end

to limpia-entradas
  ask nodos-entrada [set color white]
end


to carga-datos-test [f]
  set test-data-list []
  file-open f
  while [not file-at-end?]
  [
    let linea (read-from-string (word "[" file-read-line "]"))
    let imagen first linea
    let clase last linea
    set test-data-list lput (list imagen clase) test-data-list
  ]
end

to graba-resultado-test
  ifelse dataset = "HSV rojo"
  [file-open (word "resultados_HSV_" Num-nodos-ocultos ".txt")]
  [file-open (word "resultados_color_" Num-nodos-ocultos ".txt")]
  foreach resultado-test [
    file-print (word item 0 ? ";" item 1 ? ";" item 2 ?)
  ]
  file-close-all
end


;;;
;;; Procedimientos de test
;;;


to cargar-imagen [file]
  ;; Cargar imagen en los patches del mundo
  import-pcolors file
  ;; Colorear los nodos de entrada con el color del patch que tenga asociado
  ask nodos-entrada[
    set color [pcolor] of [patch-rel] of self
  ]
  limpia-fondo
end

;; Se leen las neuronas de entrada activas y se propaga la señal
to test
  let patron map [[color] of ?] (sort nodos-entrada)

  ifelse dataset = "HSV rojo"
  [set entradas map [ifelse-value (? >= 5) [0] [1]] patron]
  [set entradas map [0.99999 * ? / 140 ] patron]

  activar-entradas
  propaga
end

; Activamos los nodos de entrada en función de las entradas leidas
to activar-entradas
(foreach entradas (sort nodos-entrada )
  [ask ?2 [set activacion ?1]])
  recolor
end

; Recolorea los nodos en función de su valor de activación, sin considerar
; la función step. Útil para cuando no hay una clasificación clara (activacion < .5)
to recolor-c
  ask (turtle-set nodos-ocultos nodos-salida) [
    set color scale-color yellow activacion 0 .5
  ]
end


;;
;; Funciones para calcular la inversa, es decir, el nivel e activación
;;  que debe tener un nodo de entrada para que sea útil para una salida
;;  específica (tras pulsar "Invertir" se debe pulsar sobre uno de los
;;  nodos de salida)
;;

; Este procedimiento hace una especie de back-propagation desde el nodo n
; hasta los nodos de entrada
to inversa-salida [n]
  ask n[
    ; calculamos los límtes maximo y minimo para hacer bien el escalado de color
    let Pmax max [peso] of my-in-links
    let Pmin min [peso] of my-in-links
    let pm2 max (list pmax (abs pmin))
    ask my-in-links [
      let p peso
      ask end1 [
        set p2 p
        ifelse p2 > 0 [set color scale-color blue p2 -1 (Pmax + 1)] [set color scale-color red p2 (Pmin - 1) 1]
        set color lput (abs p2 * 255 / Pm2) extract-rgb color
      ]
    ]
  ]
  ask nodos-entrada [
    set p2 sum [peso * [p2] of end2] of my-out-links
    set p2 p2 / Num-nodos-ocultos
    ifelse p2 > 0 [set color scale-color blue p2 -1 2] [set color scale-color red p2 -3 0 ]
  ]
end

; Procedimiento de gestión del ratón para decidir el nodo de salida/oculto que
; se quiere invertir/analizar
to invertir
  if mouse-down?
  [
    let seleccion nodos-salida with [distancexy mouse-xcor mouse-ycor < .5]
    if any? seleccion [
      inversa-salida one-of seleccion
      wait .1]
    set seleccion nodos-ocultos with [distancexy mouse-xcor mouse-ycor < .5]
    if any? seleccion [
      analiza-oculto one-of seleccion
      wait .1]
  ]
end

; Este procedimiento muestra la importancia (peso) que tiene el nodo oculto n
; en la capa de entrada y en la capa de salida
to analiza-oculto [n]
  ask n [
    ask my-in-links [
      let p peso
      ask end1 [
        set p2 p
        ifelse p2 > 0 [set color scale-color blue p2 -1 2] [set color scale-color red p2 -3 0 ]
      ]
    ]
    ask my-out-links [
      let p peso
      ask end2 [
        set p2 p
        ifelse p2 > 0 [set color scale-color blue p2 -1 2] [set color scale-color red p2 -3 0 ]
      ]
    ]
  ]
end

;;;
;;; Ejecutar todo
;;;

;; Procedimiento para ejecutar automáticamente un experimento completo
to ejecutar-todo
  let i 5
  while [i < 16][
    show (word "Empezar ejecución con " i " nodos ocultos")
    set Num-nodos-ocultos i
    setup
    show "Cargar datos de entrenamiento."
    ifelse dataset = "HSV rojo"
    [carga-datos-entrenamiento "training/GT_todo.txt"]
    [carga-datos-entrenamiento "color/training/GT_todo.txt"]
    show "Datos de entrenamiento cargados."
    show "Comenzar entrenamiento..."
    entrena
    show "Cargar datos de test"
    ifelse dataset = "HSV rojo"
    [carga-datos-test "testing/GT_todo_sin_bg.txt"]
    [carga-datos-test "color/testing/GT_todo.txt"]
    show "Datos de test cargados"
    show "Comenzar testeo..."
    set resultado-test []
    foreach test-data-list[
      let imagen first ?
      let clase last ?
      cargar-imagen imagen
      test
      ;; Asignar como predicción el valor -1 si no se activa ninguna salida de la red neuronal
      let prediccion -1
      if (not empty? sort nodos-salida with [color = yellow]) [
        set prediccion [id] of one-of nodos-salida with [color = yellow]
      ]
      set resultado-test lput (list imagen clase prediccion) resultado-test
    ]
    show "Test finalizado"
    show "Grabar datos en fichero de texto"
    graba-resultado-test
    set i i + 1
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
345
10
970
656
20
20
15.0
1
10
1
1
1
0
0
0
1
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
10
120
330
153
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
25
75
170
108
tasa-aprendizaje
tasa-aprendizaje
0.0
1.0
0.2
1.0E-4
1
NIL
HORIZONTAL

PLOT
65
220
265
370
Error vs. Epochs
Epochs
Error
0.0
10.0
0.0
0.5
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

SLIDER
170
35
315
68
muestras-por-epoch
muestras-por-epoch
0
500
20
5
1
NIL
HORIZONTAL

BUTTON
170
180
330
215
Entrenar Red Neuronal
entrena
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
170
400
330
435
Clasificar
test
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
170
435
330
468
Limpiar
limpia-entradas
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
25
35
170
68
Num-nodos-ocultos
Num-nodos-ocultos
1
20
10
1
1
NIL
HORIZONTAL

BUTTON
10
495
330
530
Ver pesos
recolor-c
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
10
530
330
563
Analizar
Invertir
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
15
565
226
595
Tras pulsar en este botón, pulsa en el nodo de salida/oculto que quieres analizar
11
0.0
1

BUTTON
10
400
170
435
Cargar imagen
cargar-imagen user-file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
10
180
170
215
Cargar datos entrenamiento
carga-datos-entrenamiento user-file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
170
70
315
115
dataset
dataset
"HSV rojo" "Color"
0

TEXTBOX
90
10
255
28
----- CONFIGURACIÓN -----
14
0.0
1

TEXTBOX
85
160
260
178
----- ENTRENAMIENTO -----
14
0.0
1

TEXTBOX
115
380
225
398
----- TESTEO -----
14
0.0
1

TEXTBOX
115
475
230
493
----- ANÁLISIS -----\n
14
0.0
1

BUTTON
10
620
330
665
Ejecutar todo
ejecutar-todo
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
110
600
260
618
-------------------------
14
0.0
1

BUTTON
10
435
170
468
Mostrar aristas
ask links [show-link]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
# CLASIFICADOR DE SEÑALES DE TRÁFICO
## ¿QUÉ ES?

Modelo de clasificacíon de señales de tráfico que usa el método de propagación hacia atrás sobre una red neuronal. Se pretende que la red neuronal sea capaz de dedicir qué tipo de señal de tráfico se he introducido, entre 4 posibles clases:
- Ceda el paso
- Prohibido
- Stop
- Límite de velocidad


## DATASETS
Se ha utilizado como punto de partida imágenes de señales de tráfico de dos datasets públicos y utilizados frecuentemente en artículos de investigacion:
- **Belgium Traffic Signal Dataset**. Disponible en: http://btsd.ethz.ch/shareddata/
- **The German Traffic Sign Recognition Dataset**. Disponible en: http://benchmark.ini.rub.de/?section=gtsrb&subsection=dataset

Estas imágenes no se han usado tal cual, sino que se han adaptado a las características de Netlogo y a los objetivos del presente trabajo. En concreto, se han creado dos datasets con diferentes características que se describen en el siguiente apartado.

## PREPARACIÓN
### DATASET HSV FILTRO ROJO
Dataset formado por imágenes de 40x40 píxeles convertidas al espacio de colores HSV y filtradas en el rango perteneciente al color rojo. Para facilitar esta tarea, se ha empleado la librería OpenCV para Java. El código fuente puede consultarse en el archivo adjunto al trabajo: _DatasetPreparation.java_. El resultado de aplicar este filtro es una imagen compuesta únicamente por píxeles de colores blanco y negros (o cercanos al negro).

Como las imágenes están afectadas por oclusiones y efectos relacionados con la iluminación de la escena, se eliminaron del dataset aquellas imágenes que tras aplicarles el filtro HSV no tenían ningún contenido debido a que el rojo de la señal se encontraba fuera de los rangos establecidos.

Para generar las imágenes de fondo, se tomaron como base las del dataset original y aleatoriamente se recortaron 10 regiones de 40x40 píxeles en cada una de ellas. Para evitar la sobrecarga de la red neuronal con imágenes de este tipo, la mayor parte de ellas fueron desechadas aleatoriamente para que el número de instancias fuese similar al de las otras clases (ceda el paso, prohibido, stop y límite de velocidad).

Este proceso de preparación se efectuó tanto en las imágenes de entrenamiento como en las de testeo.

### DATASET COLOR
Dataset formado por imágenes RGB de 40x40 píxeles sin ningún tipo de filtro aplicado. En este caso no se ha realizado ninguna discriminación de imágenes, es decir, no se ha eliminado ninguna por tener efectos de luz adversos o oclusiones, por lo que el número de instancias de cada tipo de señal es mucho mayor que en el dataset anterior.

## CARGA DE DATOS EN NETLOGO
La carga del dataset en Netlogo es análoga para ambos conjuntos de imágenes, aunque existen leves diferencias que se describen en los siguientes apartados. Para realizar esta carga, se importan las imágenes a clasificar o testear en el mundo mediante la función _import-pcolors imagen_ y se cargan los color en los nodos de entrada (tortugas). Estos nodos además guardan una referencia al patch del que tomaron su color.

### DATASET HSV FILTRO ROJO
Como las imágenes solo tienen píxeles blancos o negros, el listado que almacena la imagen de entrada está formado por valores binarios, 1 o 0. Un píxel toma el valor 1 cuando su color (en el rango de colores de Netlogo) es menor a 5 (tonalidad de gris), y 0 en cualquier otro caso.
### DATASET COLOR
En este caso se normalizan los valores de los colores de cada píxel al rango 0...0.99999, ya que si no se realiza esta operación, la función sigmoide lanza una excepción al tener que calcular un valor numérico superior al soportado por Netlogo.

## ENTRENAMIENTO Y TESTEO
El proceso de entrenamiento de la red neuronal y posterior testeo es análogo para ambos conjuntos de imágenes. Se recorren los datos de entrada y salida cargados mediante el proceso descrito anteriormente, y se entrena la red utilizando el método de propagación hacia atrás. En el entrenamiento se usan los 4 tipos de señales e imágenes de fondo que no tienen ninguna señal.

Una vez entrenada, se cargan los datos de testeo en Netlogo y se lanzan sobre la red neuronal para obtener el resultado de la clasificación. En el testeo no se evalúa el rendimiento de la red para las imágenes de fondo. Los resultados se guardan en un archivo de texto para su posterior análisis cuando se ejecuta la función de ejecutar el proceso completo del modelo.

## ANÁLISIS DE RESULTADOS
Para la evaluación de los resultados se ha tomado el porcentaje de aciertos de la red neuronal respecto al número de nodos en la capa oculta. Los resultados pueden ser consultados de forma detallada en los archivos Excel adjuntos al trabajo.

La batería de resultados se ha obtenido lanzando el proceso completo de carga de datos, entrenamiento y testeo 10 veces, aumentando el número de nodos ocultos de 5 a 15 sucesivamente.

### DATASET HSV FILTRO ROJO
Los mejores resultados se obtienen a partir de la utilización de 7 nodos en la capa oculta. A partir de este momento, aunque se aumente el número de nodos en esta capa, el porcentaje de acierto se mantiene. El mejor resultado se obtiene con 12 nodos (95,64%) y el peor con 6 nodos (91,53%).

En general, el tipo de señal que peor se clasifica es la de stop. Esto puede ser debido a que la forma de la señal al aplicar el filtro HSV rojo no es tan uniforme como en el resto de clases, debido a las letras que hay en el centro de la señal.

Destacar que se ha conseguido un 100% de acierto para el tipo de señal de prohibido utilizando 13 nodos en la capa oculta.

### DATASET COLOR
El mejor resultado se obtiene utilizando la capa oculta de 5 nodos (51,52%) y el peor la de 7 nodos (38,21%). Aunque estos resultados no se pueden comparar con los del anterior dataset porque que las imágenes seleccionadas son distintas, observamos que los resultados son peores. Esto puede ser debido, en primer lugar, a que no se eliminaron imágenes conflictivas en las que hasta un humano podría tener dudas a la hora de reconocer qué tipo de señal es, y en segundo lugar, a que los colores reales de la imagen no son los que realmente ha aprendido la red neuronal, sino los del espacio de colores de Netlogo.

Entrando en detalles, todos los experimentos consiguen obtener más de un 90% de acierto en las señales de ceda el paso, siendo estas las mejor clasificadas por la red neuronal. En el lado opuesto encontramos las señales de stop, al igual que pasaba en el otro dataset (para 10 nodos en la capa oculta se consigue un 4,44% de acierto). Los porcentajes de las señales de límite de velocidad han disminuido drásticamente también a consecuencia de que en el experimento con el anterior dataset la red neuronal aprendía simplemente una forma circular, y en este caso, tiende a aprender la forma, el color y el número del límite de velocidad, mucho más complejo.

## CÓMO SE USA

Usa el deslizador _NUM NODOS OCULTOS_ para configurar el número de nodos ocultos que se crearán en la capa oculta.

Usa el deslizador _TASA APRENDIZAJE_ para controlar cuánto aprenderá la red neuronal de cada ejemplo.

Usa el deslizador _MUESTRAS POR EPOCH_ para controlar el número de veces que el entrenamiento tomará como entrada cada una de las instancias/imágenes.

Usa el seleccionador _DATASET_ para indicar si se va a utilizar el dataset formado por imágenes filtradas en el espacio HSV o las imágenes en color RGB.

Pulsa en _SETUP_ para crear una red e inicializar los pesos con pequeños números aleatorios. También se limpiará la región destinada a mostrar las imágenes.

Pulsa en _CARGAR DATOS ENTRENAMIENTO_ para cargar un fichero de texto que contenga en cada línea el nombre de la imagen y la clase a la que pertenece. Este botón se puede usar para cargar los datos de entrada antes de lanzar el entrenamiento de la red neuronal.

Pulsa en _ENTRENAR RED NEURONAL_ para lanzar el proceso de entrenamiento de la red neuronal una vez se hayan cargado los datos de las imágenes.

Pulsa en _CARGAR IMAGEN_ para cargar una imagen en la matriz de nodos de entrada.

Pulsa en _LIMPIAR_ para eliminar los datos representados en la matriz de nodos de entrada.

Pulsa en _CLASIFICAR_ una vez se haya cargado una imagen en la matriz de nodos de entrada mediante el botón _CARGAR IMAGEN_ para ver a qué clase pertenece la imagen.

Pulsa en _EJECUTAR TODO_ para lanzar automáticamente los procesos de carga, aprendizaje y testeo. Proceso muy lento.

## AUTOR
Álvaro Arcos García


## CREDITS AND REFERENCES
This model is part of NeuroLab, a set of neuroscience-related simulations in NetLogo written by
 Luis F. Schettino
Psychology Department
Lafayette College
Easton, PA, USA.
https://sites.lafayette.edu/schettil

From the original Artificial Neural Net Model:
The code for this model is inspired by the pseudo-code which can be found in Tom M. Mitchell's "Machine Learning" (1997).

Thanks to Craig Brozefsky for his work in improving this model.

To refer to this model in academic publications, please use:  Rand, W. and Wilensky, U. (2006).  NetLogo Artificial Neural Net model.  http://ccl.northwestern.edu/netlogo/models/ArtificialNeuralNet.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

In other publications, please use:  Copyright 2006 Uri Wilensky.  All rights reserved.  See http://ccl.northwestern.edu/netlogo/models/ArtificialNeuralNet for terms of use.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bias-node
false
0
Circle -16777216 true false 0 0 300
Circle -7500403 true true 30 30 240
Polygon -16777216 true false 120 60 150 60 165 60 165 225 180 225 180 240 135 240 135 225 150 225 150 75 135 75 150 60

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

drawer
false
0
Rectangle -7500403 true true 0 0 300 300

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0

nodo-neuronal
false
1
Circle -7500403 true false 0 0 300
Circle -2674135 true true 30 30 240
Polygon -7500403 true false 195 75 90 75 150 150 90 225 195 225 195 210 195 195 180 210 120 210 165 150 120 90 180 90 195 105 195 75

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -6459832 true false 0 0 300 300
Rectangle -7500403 true true 15 15 285 285

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.1
@#$#@#$#@
setup repeat 100 [ train ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0

@#$#@#$#@
1
@#$#@#$#@
