;;-------;;
;; Razas ;;
;;-------;;

breed [personas persona]
breed [dinosaurios dinosaurio]

;;-------------;;
;; Extensiones ;;
;;-------------;;

; Extensión de Netlogo para reporducir sonidos
extensions [sound]

;;--------------------;;
;; Variables globales ;;
;;--------------------;;

globals
[
  calcular-camino? ;; Variable para ejecutar solo una vez el algoritmo de búsqueda de camino por parte de la persona
  tiempo-ejecucion ;; Variable para mostrar en el monitor el tiempo de ejecución
  reproducir-sonido? ;; Variable que indica si se puede reproducir un sonido o no
  obstaculo-aleatorio ;; Variable aleatoria que se usa para generar elementos del terreno
  posicion-dinosaurio ;; Posición actual del dinosaurio
  posicion-persona ;; Posición actual de la persona
  camino-optimo ;; Listado de patches desde el inicio hasta la salida
]

;;----------------------------;;
;; Propiedades extras patches ;;
;;----------------------------;;

patches-own
[
  padre ;; Patch del que viene el actual
  coste-camino ;; Coste del camino hasta el punto actual
]

;;-----------------------------;;
;; Propiedades extras tortugas ;;
;;-----------------------------;;

turtles-own
[
  tiempo ;; Tiempo que tarda en pasar por el patch actual
  espera ;; Contador del tiempo que lleva la tortuga esperando en el patch actual
  camino-actual ;; Camino que aún no se ha recorrido
]

;;----------------------------------;;
;; Propiedades extras raza personas ;;
;;----------------------------------;;

personas-own[
  coche? ;; Indica si la persona va en coche o no
]

;;-------------------------------------;;
;; Propiedades extras raza dinosaurios ;;
;;-------------------------------------;;

dinosaurios-own[
  tipo ;; Indica el tipo de dinosaurio
]

;;---------------;;
;; Crear persona ;;
;;---------------;;

to Crea-persona
  ask one-of patches with[pcolor = green][
    set plabel "Inicio"
    sprout-personas 1 [
      set coche? en-coche?
      ifelse coche?
      [set shape "van side"]
      [set shape "person"]
      set color red
    ]
  ]
end

;;--------------;;
;; Crear salida ;;
;;--------------;;

to Crea-salida
  ask one-of patches with[pcolor = green][
    set plabel "Salida"
    sprout 1  [set shape "jpdoor"]
  ]
end


;;------------------;;
;; Crear dinosaurio ;;
;;------------------;;

to Crea-dinosaurio
  ask one-of patches with [pcolor = green]
  [
    sprout-dinosaurios 1
    [
      set color 32
      set tipo seleccionar-tipo-dinosaurio
      if tipo = "T-Rex"[set shape "trex"]
      if tipo = "Velociraptor"[set shape "velociraptor"]
    ]
  ]
end

;;---------------------;;
;; Crear terreno vacío ;;
;;---------------------;;

;; Crea un terreno vacío, sin obstáculos, únicamente con una persona y una salida
to Crear-terreno-vacio
  ca

  set calcular-camino? true
  set reproducir-sonido? true

  ask patches
  [
    set pcolor green
    set coste-camino 0
  ]

  crea-persona
  crea-salida

  reset-ticks
end

;;-------------------------;;
;; Crear terreno aleatorio ;;
;;-------------------------;;

;; Crear escenario con una salida, una persona, un número aleatorio de obstáculos y un número aleatorio de tipos de terreno
to Crear-terreno-aleatorio
  ca

  set calcular-camino? true
  set reproducir-sonido? true

  ask patches[
    set pcolor green
    set coste-camino 0
  ]

  ask patches[
    if %obstaculos > random 100
    [
      ask one-of patches
      [
        set obstaculo-aleatorio random 3
        if obstaculo-aleatorio = 0 [set pcolor blue]; Agua.
        if obstaculo-aleatorio = 1 [set pcolor green - 1]; Colina.
        if obstaculo-aleatorio = 2 [set pcolor brown]; Barro.
      ]
    ]
  ]

  ;; Debe haber al menos dos patches de terreno normal para colocar a la persona y la salida
  ask n-of 2 patches
  [
    set pcolor green
  ]

  crea-persona
  crea-salida

  reset-ticks
end

;;-------------------------;;
;; Crear terreno por radio ;;
;;-------------------------;;

;; Crear escenario con una salida, una persona, y obstáculos y tipos de terrenos que se generan de forma radial
to Crear-terreno-por-radio
  ca

  set calcular-camino? true
  set reproducir-sonido? true

  ask patches
  [
    set pcolor green
    set coste-camino 0
  ]

  ask patches
  [
    if %obstaculos > random 1000
    [
      ask one-of patches
      [
        set obstaculo-aleatorio random 3
        if obstaculo-aleatorio = 0[set pcolor blue]; Agua.
        if obstaculo-aleatorio = 1[set pcolor green - 1]; Colina.
        if obstaculo-aleatorio = 2[set pcolor brown]; Barro.
        ask patches in-radius radio
        [
          if obstaculo-aleatorio = 0[set pcolor blue]; Agua.
          if obstaculo-aleatorio = 1[set pcolor green - 1]; Colina.
          if obstaculo-aleatorio = 2[set pcolor brown]; Barro.
        ]
      ]
    ]
  ]

  ask n-of 2 patches
  [
    set pcolor green
  ]

  crea-persona
  crea-salida

  reset-ticks
end

;;-------------------;;
;; Limpiar escenario ;;
;;-------------------;;

;; Procedimiento para limpiar el escenario al completo. No se dibuja ningún elemento
to Limpiar-escenario
  ca

  set calcular-camino? true
  set reproducir-sonido? true

  ask patches
  [
    set pcolor green
    set coste-camino 0
  ]

  reset-ticks
end

;;-------------------;;
;; Dibujar escenario ;;
;;-------------------;;

;; Procedimiento para añadir y borrar elementos del escenario manualmente
to Dibujar-escenario

  if mouse-inside?[

    ;;---- Dibujar persona ----;;
    if seleccionar-agente-a-dibujar = "Persona"
    [
      if mouse-down?
      [
        if [plabel] of patch mouse-xcor mouse-ycor != "Salida" ;;No se puede dibujar a la persona en la salida
        [
          ask patches with [plabel = "Inicio"]
          [
            set pcolor green
            set plabel ""
          ]
          ask personas[die]
          ask patch mouse-xcor mouse-ycor[
            set plabel "Inicio"
            sprout-personas 1 [
              set coche? en-coche?
              ifelse coche?
              [set shape "van side"]
              [set shape "person"]
              set color red
            ]
          ]
        ]
      ]
    ]


    ;;---- Dibujar salida ----;;
    if seleccionar-agente-a-dibujar = "Salida"
    [
      if mouse-down?
      [

        if [plabel] of patch mouse-xcor mouse-ycor != "Inicio" ;;No se puede dibujar la salida encima de una persona
        [
          ask patches with [plabel = "Salida"]
          [
            set pcolor green
            set plabel ""
            ask turtles-here [die]
          ]
          ask patch mouse-xcor mouse-ycor
          [
            set plabel "Salida"
            sprout 1 [set shape "jpdoor"]
          ]
        ]
      ]
    ]

    ;;---- Dibujar dinosaurio ----;;
    if seleccionar-agente-a-dibujar = "Dinosaurio"
    [
      if mouse-down?
      [
        if [plabel] of patch mouse-xcor mouse-ycor != "Inicio" and [plabel] of patch mouse-xcor mouse-ycor != "Salida" ;;No se pueden dibujar dinosaurios en una salida ni encima de una persona
        [
          ask patch mouse-xcor mouse-ycor
          [
            if not any? turtles-here
            [
              set pcolor green
              sprout-dinosaurios 1
              [
                set color 32
                set tipo seleccionar-tipo-dinosaurio
                if tipo = "T-Rex"[set shape "trex"]
                if tipo = "Velociraptor"[set shape "velociraptor"]
              ]
            ]
          ]
        ]
      ]
    ]

    ;;---- Dibujar agua ----;;
    if seleccionar-agente-a-dibujar = "Agua"
    [
      if mouse-down?
      [
        if [plabel] of patch mouse-xcor mouse-ycor != "Inicio" and [plabel] of patch mouse-xcor mouse-ycor != "Salida" ;;No se pueden dibujar agua ni en una salida ni en el patch donde se encuentre una persona
        [
          ask patch mouse-xcor mouse-ycor
          [
            set pcolor blue
          ]
        ]
      ]
    ]

    ;;---- Dibujar barro ----;;
    if seleccionar-agente-a-dibujar = "Barro"
    [
      if mouse-down?
      [
        if [plabel] of patch mouse-xcor mouse-ycor != "Inicio" and [plabel] of patch mouse-xcor mouse-ycor != "Salida" ;;No se pueden dibujar barro ni en una salida ni en el patch donde se encuentre una persona
        [
          ask patch mouse-xcor mouse-ycor
          [
            set pcolor brown
          ]
        ]
      ]
    ]

    ;;---- Dibujar monte ----;;
    if seleccionar-agente-a-dibujar = "Monte"
    [
      if mouse-down?
      [
        if [plabel] of patch mouse-xcor mouse-ycor != "Inicio" and [plabel] of patch mouse-xcor mouse-ycor != "Salida" ;;No se pueden dibujar un monte ni en una salida ni en el patch donde se encuentre una persona
        [
          ask patch mouse-xcor mouse-ycor
          [
            set pcolor green - 1
          ]
        ]
      ]
    ]

    ;;---- Borrar obstáculos ----;;
    ;; Se cambia el agua, el barro o un monte por terreno normal
    if seleccionar-agente-a-dibujar = "Borrar obstáculos"
    [
      if mouse-down?
      [
        if [pcolor] of patch mouse-xcor mouse-ycor = blue or
        [pcolor] of patch mouse-xcor mouse-ycor = green - 1 or
        [pcolor] of patch mouse-xcor mouse-ycor = brown
        [
          ask patch mouse-xcor mouse-ycor
          [
            set pcolor green
          ]
        ]
      ]
    ]

    ;;---- Borrar dinosuarios ----;;
    if seleccionar-agente-a-dibujar = "Borrar dinosaurio"
    [
      if mouse-down?
      [
        ask dinosaurios-on patch mouse-xcor mouse-ycor[die]
      ]
    ]
    tick
  ]

end

;;------------;;
;; Algoritmos ;;
;;------------;;

;;====;;
;; A* ;;
;;====;;

;; Entrada:
;;   - patch-inicio     : el punto de partida
;;   - patch-fin        : el punto de llegada
;;
;; Devuelve:
;;   - Si hay camino   : lista de patches que forman el camino óptimo
;;   - Si no hay camino: nada


to-report A* [ patch-inicio patch-fin]

  ;; Inicialización de variables locales
  let busqueda-terminada? false ;; Variable para controlar cuando hay que dejar de buscar
  let patch-actual 0
  let abiertos [] ;; Listado de patches abiertos (sin visitar)
  let cerrados [] ;; Listado de patches cerrados (visitados)

  ;; Indicar que el patch de inicio no tiene padre
  ask patch-inicio [set padre nobody]

  ;; Insertar el patch de inicio en el listado de abiertos
  set abiertos lput patch-inicio abiertos

  ;; Ejecutar el bucle hasta que se encuentre un camino al patch final o hasta que el listado de abiertos se quede vacío
  while [not busqueda-terminada?]
  [
    ifelse not empty? abiertos
    [

      ;; Ordenar los patches del listado de abiertos por el coste de camino de cada uno. El primer patch del listado será el que tenga el menor coste de camino
      set abiertos sort-by [[coste-camino] of ?1 < [coste-camino] of ?2] abiertos

      ;; Obtener el primer patch de abiertos y eliminarlo del listado
      set patch-actual item 0 abiertos
      set abiertos remove-item 0 abiertos

      ;; Insertar el patch actual en el listado de patches cerrados (visitados)
      set cerrados lput patch-actual cerrados

      ask patch-actual
      [
        ;; Preguntar a los vecinos del patch actual si hay algún que sea el patch final. En caso afirmativo, parar la búsqueda
        ifelse any? neighbors with [(pxcor = [pxcor] of patch-fin) and (pycor = [pycor] of patch-fin)]
        [
          set busqueda-terminada? true
        ]
        [
          ;; Ignorar los vecinos que sean patches con agua o que ya hayan sido visitados
          ask neighbors with [ pcolor != blue and (not member? self cerrados)]
          [
            ;; Los patches candidatos no deben estar incluidos en el listado de abiertos ni ser el patch de inicio o el patch de fin
            if not member? self abiertos and self != patch-inicio and self != patch-fin
            [
              ;; Insertar patch candidato en el listado de abiertos
              set abiertos lput self abiertos

              ;; Indicar que el padre del patch candidato es el patch actual
              set padre patch-actual

              ;; Calcular y almacenar el coste total del camino que une el patch inicial con el patch final y pasa por el patch candidato
              set coste-camino ([coste-camino] of padre + 1 + Heuristica patch-fin)

            ]
          ]
        ]
      ]
    ]
    [
      ;; Si la lista de abiertos se queda vacía antes de encontrar un camino óptimo, mostrarle un mensaje al usuario indicándole
      ;; que nunca podrá escapar del parque (no hay ningún camino desde el inicio hasta el fin)
      user-message( "Nunca podrás escapar de Jurassic Park. Pulsa DETENER para finalizar" )
    ]
  ]

  ;; Indicarle al patch final que su padre es el patch actual
  ask patch-fin [set padre patch-actual]

  ;; Reconstruir el camino óptimo que va desde el patch inicial al patch final
  report reconstruye-camino patch-fin

end

;;================;;
;; Heurísticas A* ;;
;;================;;


to-report Heuristica [patch-fin]
  let resultado 0
  let D 1
  let D2 1

  if seleccionar-heuristica = "Euclidian"[
    set resultado distance patch-fin
  ]

  if seleccionar-heuristica = "Euclidian Tie Breaker"[
    set resultado distance patch-fin
    let h-escala (1 + (16 / 8 / world-width * world-height))
    set resultado resultado * h-escala
  ]

  if seleccionar-heuristica = "Manhattan"[
    let diferencia-x abs(pxcor - [pxcor] of patch-fin)
    let diferencia-y abs(pycor - [pycor] of patch-fin)
    set resultado diferencia-x + diferencia-y
  ]
  if seleccionar-heuristica = "Diagonal"[
    set D2 1.414214
    let diferencia-x abs(pxcor - [pxcor] of patch-fin)
    let diferencia-y abs(pycor - [pycor] of patch-fin)
    let h_diagonal min (list diferencia-x diferencia-y)
    let h_recta diferencia-x + diferencia-y
    set resultado D2 * h_diagonal + D * ( h_recta - 2 * h_diagonal )
  ]
  if seleccionar-heuristica = "Diagonal Tie Breaker"[
    set D2 1.414214
    let diferencia-x abs(pxcor - [pxcor] of patch-fin)
    let diferencia-y abs(pycor - [pycor] of patch-fin)
    let h_diagonal min (list diferencia-x diferencia-y)
    let h_recta diferencia-x + diferencia-y
    set resultado D2 * h_diagonal + D * ( h_recta - 2 * h_diagonal )
    let h-escala (1 + (16 / 8 / world-width * world-height))
    set resultado resultado * h-escala
  ]
  if seleccionar-heuristica = "Chebyshev"[
    let diferencia-x abs(pxcor - [pxcor] of patch-fin)
    let diferencia-y abs(pycor - [pycor] of patch-fin)
    set resultado (D * (diferencia-x + diferencia-y) + (D2 - 2 * D) * min (list diferencia-x diferencia-y))
  ]
  if seleccionar-heuristica = "Octile"[
    set D2 sqrt 2
    let diferencia-x abs(pxcor - [pxcor] of patch-fin)
    let diferencia-y abs(pycor - [pycor] of patch-fin)
    set resultado (D * (diferencia-x + diferencia-y) + (D2 - 2 * D) * min (list diferencia-x diferencia-y))
  ]

  let factor-terreno 1 ;; El terreno normal tiene peso 1
  if aplicar-factor-terreno-a-heuristica?[
    if [pcolor] of self = brown [set factor-terreno 2] ;; El barro tiene peso 2
    if [pcolor] of self = green - 1 [set factor-terreno 4] ;; El monte tiene peso 4
  ]

  report resultado * factor-terreno
end

;;============================;;
;; Breadth First Search (BFS) ;;
;;============================;;

;; Entrada:
;;   - patch-inicio     : el punto de partida
;;   - patch-fin        : el punto de llegada
;;
;; Devuelve:
;;   - Si hay camino   : lista de patches que forman el camino óptimo
;;   - Si no hay camino: nada

to-report BFS [patch-inicio patch-fin]

  ;; Inicialización de variables locales
  let abiertos [] ;; Listado de patches abiertos (sin visitar)
  let cerrados [] ;; Listado de patches cerrados (visitados)
  let patch-actual 0

  ;; Indicar que el patch de inicio no tiene padre
  ask patch-inicio [set padre nobody]

  ;; Insertar el patch de inicio en el listado de abiertos
  set abiertos lput patch-inicio abiertos

  ;; El algoritmo se ejecuta hasta que la lista de patches abiertos se quede vacía
  while [not empty? abiertos][

    ;; Obtener el primer elemento del listado de abiertos y eliminarlo de dicho listado
    set patch-actual first abiertos
    set abiertos (remove-item 0 abiertos)

    ;; Finalizar la búsqueda si el patch actual es el mismo que el patch final, y devolver el camino
    ifelse patch-actual = patch-fin [report Reconstruye-camino patch-fin]
    [
      ;; Insertar el patch actual en el listado de cerrados
      set cerrados lput patch-actual cerrados

      ;; Seleccionar los vecinos del patch actual que no sean azules (agua)
      ask patch-actual[
        ask neighbors with [pcolor != blue][
          ;; Si el vecino no se encuentra ni en el listado de visitados ni en el de abiertos, seleccionarlo como patch candidato
          if (not member? self cerrados) and (not member? self abiertos)[

            ;; Indicar que el padre del patch candidato es el patch actual
            set padre patch-actual

            ;; Insertar el patch candidato al final del listado de abiertos
            set abiertos lput self abiertos
          ]
        ]
      ]
    ]
  ]

  ;; Si se ha llegado a este punto de la ejecución de la función significará que no se ha encontrado un camino
  ;; entre el patch de inicio y el patch de fin, y por lo tanto le mostramos un mensaje al usuario.
  while [true][
    user-message( "Nunca podrás escapar de Jurassic Park. Pulsa DETENER para finalizar" )
  ]
end


;;==============================;;
;; Reconstruir camino calculado ;;
;;==============================;;

;; Función que devuelve un camino desde el patch inicial al patch final que ya haya sido calculado con algún algoritmo
;; Parte del patch final y va obteniendo los padres de los patches para generar el camino

to-report Reconstruye-camino [patch-fin]
  let camino []
  let patch-camino patch-fin
  while [[padre] of patch-camino != nobody][ ;; El bucle se ejecuta mientras que los padres de los patches no sean nobody. El patch que tiene como padre a nobody es el patch inicial
    set camino fput patch-camino camino
    set patch-camino [padre] of patch-camino
  ]
  set camino fput patch-camino camino
  report camino
end

;;---------;;
;; Escapar ;;
;;---------;;

;; Procedimiento encargado de lanzar la primera ejecución del algortimo de búsqueda de camino y de controlar el movimiento de las tortugas

to Escapar

  if Persona-cazada? [stop]

  Busca-camino-hasta-salida

  set tiempo-ejecucion timer

  Calcular-movimiento-persona

  Calcular-movimiento-dinosaurio

  tick
end



;;-----------------------------------------------;;
;; Buscar camino desde el inicio hasta la salida ;;
;;-----------------------------------------------;;

to Busca-camino-hasta-salida

  ;; Llamar al algoritmo de búsqueda de camino óptimo solo una vez, desde la posición de la persona hasta la posición de la salida
  if calcular-camino?
  [
    ;; Ejecutar el algoritmo seleccionado en la interfaz de usuario (A* o BFS)
    if seleccionar-algoritmo = "A*"[
      ask one-of personas
      [
        set camino-actual bf A* one-of patches with [plabel = "Inicio"] one-of patches with [plabel = "Salida"]
        set camino-optimo camino-actual ;; Mostrar en el monitor la longitud del camino óptimo
      ]
    ]

    if seleccionar-algoritmo = "BFS"[
      ask one-of personas
      [
        set camino-actual bf BFS one-of patches with [plabel = "Inicio"] one-of patches with [plabel = "Salida"]
        set camino-optimo camino-actual ;; Mostrar en el monitor la longitud del camino óptimo
      ]
    ]

    reset-timer
    reset-ticks
    set calcular-camino? false;
  ]
end

;;------------------;;
;; ¿Persona cazada? ;;
;;------------------;;

to-report Persona-cazada?
  let cazada? false

  ;; Un dinosaurio cazará a una persona cuando los dos se encuentren en el mismo patch
  ask dinosaurios
  [
    if posicion-persona = patch-here
    [
      if musica? and reproducir-sonido?
      [
        if tipo = "T-Rex" [sound:play-sound "trex.wav"]
        if tipo = "Velociraptor" [sound:play-sound "raptor.wav"]

        set reproducir-sonido? false
      ]
      set cazada? true
      user-message( "¡Te han cazado!. Los dinosaurios se están dando un festín contigo. Pulsa el botón DETENER para finalizar" )
    ]
  ]
  report cazada?
end

;;--------------------------------;;
;; Calcular movimiento de persona ;;
;;--------------------------------;;

to Calcular-movimiento-persona

  ask one-of personas
  [
    ifelse pcolor = green
    [set tiempo ifelse-value coche? [0.5] [2]] ;; En terreno normal el coche tiene una velocidad de 0.5 y la persona de 2
    [ifelse pcolor = brown
      [set tiempo ifelse-value coche? [1] [3]] ;; En barro el coche tiene una velocidad de 1 y la persona de 3
      [if pcolor = green - 1
        [set tiempo ifelse-value coche? [2] [5]] ;; En un monte el coche tiene una velocidad de 2 y la persona de 5
      ]
    ]

    ;; Guardar la posición de la persona en la variable global para que luego la use el dinosaurio en su búsqueda
    set posicion-persona patch-here

    ;; Terminar la persecución y reproducir un sonido cuando la persona llega a la salida del parque
    if [plabel] of patch-here = "Salida"
    [
      if musica? and reproducir-sonido?
      [
        sound:play-sound "jpark.wav"
        set reproducir-sonido? false
      ]
      user-message("¡Has escapado sano y salvo!. Pulsa el botón DETENER para finalizar")
    ]

    ;; La persona tiene que esperar un determinado tiempo en el patch para poder seguir avanzando
    ifelse espera > tiempo
    [
      set espera 0
      if not empty? camino-actual ;; Si el camino que tiene que recorrer aún no se ha acabado
      [
        pd
        Mover-persona-siguiente-patch ;; Mover la persona al siguiente patch
      ]

    ][
    set espera espera + 1
    ]
  ]
end

;;-----------------------------------;;
;; Calcular movimiento de dinosaurio ;;
;;-----------------------------------;;

to Calcular-movimiento-dinosaurio

  ask dinosaurios
  [
    ifelse pcolor = green
    [set tiempo ifelse-value (tipo = "T-Rex") [0.5] [1]] ;; En terreno normal el T-Rex tiene una velocidad de 0.5 y el velociraptor de 1
    [ifelse pcolor = brown
      [set tiempo ifelse-value (tipo = "T-Rex") [1] [2]] ;; En barro el T-Rex tiene una velocidad de 1 y el velociraptor de 2
      [if pcolor = green - 1
        [set tiempo ifelse-value (tipo = "T-Rex") [2] [3]] ;; En un monte el T-Rex tiene una velocidad de 2 y el velociraptor de 3
      ]
    ]

    set posicion-dinosaurio patch-here

    ;; El dinosaurio tiene que esperar un determinado tiempo en el patch para poder seguir avanzando
    ifelse espera > tiempo
    [
      ;; Calcular el camino entre el dinosaurio y la persona una vez por tick
      if seleccionar-algoritmo = "A*" [set camino-actual A* posicion-dinosaurio posicion-persona]
      if seleccionar-algoritmo = "BFS" [set camino-actual BFS posicion-dinosaurio posicion-persona]

      set espera 0
      if not empty? camino-actual ;; Si el camino que tiene que recorrer aún no se ha acabado
      [
        pd
        Mover-dinosaurio-siguiente-patch ;; Mover el dinosaurio al siguiente patch
      ]
    ]
    [
      set espera espera + 1
    ]
  ]
end

;;---------------------------------------------;;
;; Mover persona al siguiente patch del camino ;;
;;---------------------------------------------;;

to Mover-persona-siguiente-patch
  if not empty? camino-actual[
    face first camino-actual
    fd 1
    move-to first camino-actual
    set camino-actual bf camino-actual
  ]
end

;;------------------------------------------------;;
;; Mover dinosaurio al siguiente patch del camino ;;
;;------------------------------------------------;;

to Mover-dinosaurio-siguiente-patch
  if not empty? bf camino-actual[
    face first bf camino-actual
    fd 1
    move-to (first bf camino-actual)
    set camino-actual bf camino-actual
  ]
end








@#$#@#$#@
GRAPHICS-WINDOW
349
10
1184
566
16
10
25.0
1
10
1
1
1
0
0
0
1
-16
16
-10
10
1
1
1
ticks
30.0

BUTTON
5
90
171
124
Crear terreno vacío
Crear-terreno-vacio
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
6
206
168
250
Dibujar escenario
Dibujar-escenario
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
171
205
338
250
seleccionar-agente-a-dibujar
seleccionar-agente-a-dibujar
"Persona" "Salida" "Dinosaurio" "Barro" "Monte" "Agua" "Borrar obstáculos" "Borrar dinosaurio"
0

BUTTON
6
127
170
161
Crear terreno aleatorio
Crear-terreno-aleatorio
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
173
127
338
160
%obstaculos
%obstaculos
0
100
60
1
1
NIL
HORIZONTAL

BUTTON
7
166
169
200
Crear terreno por radio
Crear-terreno-por-radio
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
173
167
337
200
radio
radio
0
3
2
1
1
NIL
HORIZONTAL

MONITOR
1217
33
1335
78
Longitud del camino
length camino-optimo
17
1
11

CHOOSER
168
285
340
330
seleccionar-tipo-dinosaurio
seleccionar-tipo-dinosaurio
"T-Rex" "Velociraptor"
1

BUTTON
7
285
166
328
Crear dinosaurio aleatorio
crea-dinosaurio
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
8
492
332
526
Escapar
Escapar
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1339
33
1496
78
Tiempo ejecución (segundos)
tiempo-ejecucion
17
1
11

CHOOSER
171
361
334
406
seleccionar-heuristica
seleccionar-heuristica
"Euclidian" "Euclidian Tie Breaker" "Manhattan" "Diagonal" "Diagonal Tie Breaker" "Chebyshev" "Octile"
4

SWITCH
196
30
286
63
musica?
musica?
0
1
-1000

SWITCH
8
29
120
62
en-coche?
en-coche?
0
1
-1000

CHOOSER
8
361
165
406
seleccionar-algoritmo
seleccionar-algoritmo
"A*" "BFS"
0

TEXTBOX
12
70
162
88
Configurar terreno
12
0.0
1

TEXTBOX
10
10
160
28
Configurar persona
12
0.0
1

TEXTBOX
9
267
159
285
Configurar dinosaurios
12
0.0
1

TEXTBOX
9
337
159
355
Configurar algoritmo
12
0.0
1

TEXTBOX
197
10
347
28
Configurar música
12
0.0
1

TEXTBOX
45
469
311
487
[===========================]
12
0.0
1

BUTTON
98
536
238
569
Limpiar escenario
Limpiar-escenario
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
10
420
335
453
aplicar-factor-terreno-a-heuristica?
aplicar-factor-terreno-a-heuristica?
1
1
-1000

TEXTBOX
1218
10
1368
28
Resultados
12
0.0
1

@#$#@#$#@
# Escapar de Jurassic Park

## ¿QUÉ ES ESTO?

Modelo que simula la ejecución del problema de buscar un camino entre una posición inicial y una posición final a través de la aplicación de dos posibles algoritmos:
1. A-estrella (A*)
2. Búsqueda en anchura (BFS)

El modelo muestra a modo de juego como una persona situada en la posición inicial debe escapar de Jurassic Park a través de una salida situada en la posición final. Mientras tanto, varios dinosaurios intentarán dar caza a la persona que huye.

## CÓMO FUNCIONA

Se ejecuta la búsqueda del camino entre la persona y la salida aplicando uno de los dos algoritmos anteriormente citados, una única vez. Los dinosaurios, lanzarán la búsqueda del camino entre ellos y la persona continuamente.

Hay cuatro tipos de tortugas:
1. Persona a pie.
2. Persona en coche.
3. Dinosaurio T-Rex.
4. Dinosaurio Velociraptor.

Hay cuatro tipos de terreno:
1. Terreno normal. Patches de color _green_.
2. Terreno con barro. Patches de color _brown_.
3. Terreno con monte. Patches de color _green-1_.
4. Terreno con agua. Patches de color _blue_.

Ni la persona ni los dinosaurios puede pasar por encima del agua.

El resto de tipos de terreno llevan asociados un peso. Este peso se aplica a la heurística si se selecciona la opción _aplicar-factor-terreno-a-heuristica?_ en la interfaz de usuario. Independientemente de si se aplica o no esta opción, todas las tortugas tardarán un tiempo concreto en cruzar los distintos tipos de terrenos. Por ejemplo, una persona a pie tardará más en subir un monte que una persona en coche.

El juego finaliza cuando la persona consigue escapar del parque o cuando uno de los dinosaurios caza a la persona.

## CÓMO SE USA
Utilizar los elementos de la interfaz gráfica que se describen a continuación para generar el modelo y después pulsar en "Escapar" para ejecutarlo.

En la interfaz de usuario se encuentran los siguientes elementos:

### Configurar persona

- _en-coche?_ (interruptor): Establece si la persona que se creará irá montada en coche o no. Si va en coche, la velocidad de la persona será mayor que si va andando.

### Configurar música

- _musica?_ (interruptor): Establece si se escucharán distintos sonidos a lo largo de la simulación. En concreto, se reproducirán sonidos cuando la persona alcance la salida o cuando un dinosaurio de caza a la persona.

### Configurar terreno

- _Crear terreno vacío_ (botón): Crea un escenario vacío, sin obstáculos, únicamente con una persona y una salida situados aleatoriamente.

- _Crear terreno aleatorio_ (botón): Crear escenario con una salida y una persona situados de forma aleatoria, y un número aleatorio de obstáculos de tipos de terreno. La generación de este escenario depende en gran medida de la variable %obstaculos.

- _%obstaculos_ (deslizador): Proporción de obstáculos y tipos de terreno que se crearán en el escenario.


- _Crear terreno por radio_ (botón): Crear escenario con una salida y una persona situados de forma aleatoria, y obstáculos y tipos de terrenos generados con forma radial (dependen de la variable radio).


- _radio_ (deslizador): Establece el radio que utilizará el botón "Crear terreno por radio" para generar los elementos del escenario.


- _Dibujar escenario_ (botón): Se usa para dibujar o borrar los elementos del escenario que se hayan indicado en el selector "seleccionar-agente-a-dibujar". Lo primero que hay que hacer es seleccionar el elemento que se quiera dibujar o eliminar, luego pulsar en el botón "Dibujar escenario", seguidamente hacer click en el escenario para que se dibuje o elimine el elemento, y por último volver a pulsar en el botón "Dibujar escenario" para que se desactive.


- _Selecciona-agente-a-dibujar_ (selector): Ofrece 8 opciones:

	1. Persona. Seleccionar esta opción para colocar a la persona (patch inicial) en una posición concreta.
	2. Salida. Seleccionar esta opción para colocar la salida (patch final) en una posición concreta.
	3. Dinosaurio. Seleccionar esta opción para dibujar en el mapa un dinosaurio del tipo que se haya seleccionado en el correspondiente selector.
	4. Barro. Seleccionar esta opción para dibujar en el mapa terreno de tipo barro.
	5. Monte. Seleccionar esta opción para dibujar en el mapa terreno de tipo monte.
	6. Agua. Seleccionar esta opción para dibujar en el mapa agua. Ni la persona ni los dinosuarios pueden atravesar este tipo de terreno.
	7. Borrar obstáculos. Seleccionar esta opción para borrar obstáculos del mapa. Los patches pasarán a ser terreno de tipo normal.
	8. Borrar dinosaurio. Seleccionar esta opción para borrar dinosaurios del mapa.

### Configurar dinosaurios

- _Crear dinosaurio aleatorio_ (botón). Crea un dinosaurio del tipo establecido en el selector "seleccionar-tipo-dinosaurio" en un patch aleatorio de terreno normal.

- _seleccionar-tipo-dinosaurio_ (selector). Establece el tipo de dinosaurio que se creará. Puede ser un T-Rex o un Velociraptor. Cada uno tiene asociada una velocidad.

### Configurar algoritmo

- _seleccionar-algoritmo_ (selector). Indica el algoritmo que se utilizará en la búsqueda de caminos, tanto de la persona a la salida, como de los dinosaurios a la persona. Dos opciones: A* o BFS.

- _seleccionar-heuristica_ (selector). Establece la heurística que se utilizará en el algoritmo A* para estimar el coste del camino que queda por recorrer desde la posición actual de la persona o el dinosaurio, hasta la posición final (salida o persona respectivamente).

- _aplicar-factor-terreno-a-heuristica?_ (interruptor). Indicar si se desea aplicar un factor adicional al cálculo de la heurística que dependerá del tipo de terreno. Si es barro, se multiplicará el resultado de la heurística por 2, y si es monte, se hará por 4. Al establecer esta opción se puede observar como las tortugas intentarán en la medida de lo posible no pasar por encima de terrenos con barro o montes.

### Ejecución

- _Escapar_ (botón): Este botón ejecutará el algoritmo seleccionado anteriormente para encontrar un camino entre la persona y la salida, y entre los dinosaurios y la persona. La búsqueda del primer caso solo se efectúa una vez, mientras que el segundo caso se ejecuta una vez por tick, es decir, continuamente.

- _Limpiar escenario_ (botón): Limpia por completo el escenario.

### Resultados

- _Longitud del camino_ (monitor): Muestra la longitud del camino entre la persona y la salida.

- _Tiempo de ejecución_ (monitor): Muestra el tiempo en segudos desde que comienza la ejecución del modelo hasta que la persona escapa del parque o es cazada.


## AUTOR

Álvaro Arcos García
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

airplane 2
true
0
Polygon -7500403 true true 150 26 135 30 120 60 120 90 18 105 15 135 120 150 120 165 135 210 135 225 150 285 165 225 165 210 180 165 180 150 285 135 282 105 180 90 180 60 165 30
Line -7500403 false 120 30 180 30
Polygon -7500403 true true 105 255 120 240 180 240 195 255 180 270 120 270

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

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

jpdoor
false
0
Polygon -6459832 true false 0 255 30 0 60 0 60 60 240 60 240 0 270 0 300 255 225 255 210 135 90 135 75 255 0 255
Rectangle -6459832 true false 105 150 105 165
Polygon -1184463 true false 120 75 120 105 105 105 105 90 90 90 90 120 135 120 135 45 120 45 120 75
Polygon -1184463 true false 165 120 165 45 210 45 210 90 180 90 180 120 165 120
Polygon -6459832 true false 180 60 195 60 195 75 180 75 180 60 225 90

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
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

tank
true
0
Rectangle -7500403 true true 144 0 159 105
Rectangle -6459832 true false 195 45 255 255
Rectangle -16777216 false false 195 45 255 255
Rectangle -6459832 true false 45 45 105 255
Rectangle -16777216 false false 45 45 105 255
Line -16777216 false 45 75 255 75
Line -16777216 false 45 105 255 105
Line -16777216 false 45 60 255 60
Line -16777216 false 45 240 255 240
Line -16777216 false 45 225 255 225
Line -16777216 false 45 195 255 195
Line -16777216 false 45 150 255 150
Polygon -7500403 true true 90 60 60 90 60 240 120 255 180 255 240 240 240 90 210 60
Rectangle -16777216 false false 135 105 165 120
Polygon -16777216 false false 135 120 105 135 101 181 120 225 149 234 180 225 199 182 195 135 165 120
Polygon -16777216 false false 240 90 210 60 211 246 240 240
Polygon -16777216 false false 60 90 90 60 89 246 60 240
Polygon -16777216 false false 89 247 116 254 183 255 211 246 211 237 89 236
Rectangle -16777216 false false 90 60 210 90
Rectangle -16777216 false false 143 0 158 105

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

trex
false
0
Polygon -7500403 true true 255 60 255 105 240 105 240 120 195 120 195 135 225 135 225 165 210 165 210 150 195 150 195 195 180 195 180 210 165 210 165 225 150 225 150 255 165 255 165 270 135 270 135 210 120 210 120 225 105 225 105 255 120 255 120 270 90 270 90 210 75 210 75 195 60 195 60 165 45 165 45 135 30 135 30 105 30 90 45 90 45 120 60 120 60 135 75 135 75 150 90 150 90 165 105 165 105 150 120 150 120 135 135 135 135 60 150 60 150 45 165 45 165 30 210 30 210 45 210 30 225 30 225 45 240 45 240 60 255 60
Polygon -1 true false 165 60 195 60 195 75 180 75 180 90 165 90 165 60

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

van side
false
0
Polygon -7500403 true true 26 147 18 125 36 61 161 61 177 67 195 90 242 97 262 110 273 129 260 149
Circle -16777216 true false 43 123 42
Circle -16777216 true false 194 124 42
Polygon -16777216 true false 45 68 37 95 183 96 169 69
Line -7500403 true 62 65 62 103
Line -7500403 true 115 68 120 100
Polygon -1 true false 271 127 258 126 257 114 261 109
Rectangle -16777216 true false 19 131 27 142

velociraptor
false
0
Polygon -7500403 true true 30 120 60 120 60 135 75 135 75 150 75 165 105 165 120 165 135 150 150 135 165 135 180 120 225 120 240 135 240 165 180 165 180 180 195 180 195 195 180 195 165 210 165 225 165 255 180 255 180 270 150 270 150 225 135 225 120 225 120 255 135 255 135 270 105 270 105 210 90 195 90 180 60 180 60 150 45 150 45 135 45 120
Polygon -1 true false 195 135 225 135 225 150 195 135 195 90

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
setup-corner
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
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
