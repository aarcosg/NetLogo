globals [
  mejor-recorrido          ;; mejor combinación de posiciones de reinas en el tablero (listado de nodos)
  coste-mejor-recorrido    ;; menor número de colisiones entre las reinas del tablero
  posiciones-reinas        ;; mejor combinación de posiciones de reinas en el tablero (listado de celdas)
]

breed [ nodos nodo ]
breed [ hormigas hormiga ]
breed [ reinas reina ]

links-own [
  coste
  feromona
]

hormigas-own [
  recorrido
  coste-recorrido
]
nodos-own [
  i
  j
]

;;;;;;;;;;;;;;;:::::;;;;;;;;
;;; Procedimientos Setup ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Genera un grid de nodos de dimensión num-reinas * num-reinas filas y num-reinas columnas -> N^2 x N.
;; Para el caso de las 8 reinas, el espacio de búsqueda es 64 filas x 8 columnas.
to setup
  clear-all

  set-patch-size 7
  resize-world 0 num-reinas * tam-arista * num-reinas + tam-arista 0 (num-reinas * num-reinas * tam-arista)  + tam-arista
  set-default-shape nodos "circle"
  ask patches [set pcolor white]

  crea-nodos
  crea-aristas
  crea-hormigas

  set mejor-recorrido camino-aleatorio
  set coste-mejor-recorrido calcular-fitness mejor-recorrido
  muestra-mejor-recorrido

  reset-ticks
end

;; Generar espacio de búsqueda = N^2 x N nodos. Para 8 reinas -> 64x8 nodos
;; Las etiquetas de los nodos muestran la celda del tablero de ajedrez, por ejemplo,
;; la etiqueta 1 se usa para mapear la celda [0,0], la etiqueta 2 mapea la celda [0,1]
;; y la etiqueta n^2 mapea la celda [n-1, n-1]
to crea-nodos
  let fila 0
  let columna 0
  while [columna < num-reinas][
    set fila 0
    while [fila <  (num-reinas * num-reinas)][
      ask patch (tam-arista + tam-arista * num-reinas * columna) (tam-arista + tam-arista * fila) [
        sprout-nodos 1[
          if not dibujar-nodos?
          [hide-turtle]
          set color orange
          set size 1
          set label-color black
          set i columna
          set j fila mod num-reinas
          set label fila
        ]
      ]
      set fila fila + 1
    ]
    set columna columna + 1
  ]
end

;; Crear N^2 x N^2 x N - 1 aristas. Para 8 reinas -> 64x64x7 aristas
;; Cada nodo en una columna está conectado a todos los nodos de la siguiente columna
;; mediante aristas dirigidas.
to crea-aristas
  ;; asignar el mismo valor de feromonas a todas las aristas
  let feromonas-inicio random-float 0.1
  ask nodos
  [
    create-links-to other nodos with [i = 1 + [i] of myself]
    [
      ;hide-link
      set color red + 4
      set feromona feromonas-inicio
    ]
  ]
  ;; Calcular colisiones entre pares de celdas
  ask links[
    set coste calcular-fitness (list end1 end2)
  ]
end

to crea-hormigas
  create-hormigas num-hormigas [
    set shape "ant"
    set size 2
    set color cyan
    set recorrido []
    set coste-recorrido 0
    ifelse dibujar-recorrido-hormigas?
    [pd]
    [hide-turtle]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Procedimiento Principal ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  ;no-display
  ask hormigas [
    ;watch-me
    set recorrido generar-recorrido
    set coste-recorrido calcular-fitness recorrido

    if coste-recorrido < coste-mejor-recorrido [
      set mejor-recorrido recorrido
      set coste-mejor-recorrido coste-recorrido
      muestra-mejor-recorrido
    ]
  ]

  actualiza-feromona
  tick
  dibuja-plots
  display

  ;; Terminar la ejecución si el coste del mejor recorrido es cero, es decir,
  ;; si no se produce ninguna colisión entre las reinas del tablero.
  if coste-mejor-recorrido = 0
  [
    ;; Se puede activar la opción de que se muestre el tablero con las reinas
    ;; cuando se encuentre una solución al problema
    if mostrar-tablero-solucion? [
      let pos-reinas []
      foreach mejor-recorrido[
        set pos-reinas lput [j] of ? pos-reinas
      ]
      dibuja-tablero
      coloca-reinas pos-reinas
    ]
    stop
  ]

end

;; Dibujar tablero de ajedrez
to dibuja-tablero
  resize-world 0 num-reinas - 1 0 num-reinas - 1
  set-patch-size 40
  ask patches [
    if-else ((pxcor - pycor) mod 2 = 0) [ set pcolor white ] [ set pcolor black ]
  ]
end

;; Colocar las reinas en el tablero
to coloca-reinas [pos-reinas]
  ask reinas [die]
  let col 0
  foreach pos-reinas [
    create-reinas 1 [
      setxy col ?
      set shape "chess queen"
      set color orange
      set size 0.7
    ]
    set col col + 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Procedimientos para encontrar recorridos ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Genera un camino aleatorio desde la columna 0 a la num-reinas - -1 que representa
;; en el espacio de búsqueda. Esto representa una combinación de posiciones de reinas
to-report camino-aleatorio
  let resp []
  let labels []
  let filas []
  let contador-columnas 0
  while [contador-columnas < num-reinas][
    ;; la hormiga tiene que elegir un nodo aleatorio por columna
    let nodo-aleatorio one-of nodos with [i =  contador-columnas
      ;; en el camino no puede haber dos nodos con la misma etiqueta (misma celda)
      and not member? [label] of self labels
      ;; en el camino no puede haber dos nodos en la misma fila (para evitar colisiones)
      and not member? [j] of self filas
      ]
    set resp lput nodo-aleatorio resp
    set labels lput [label] of nodo-aleatorio labels
    set filas lput [j] of nodo-aleatorio filas
    set contador-columnas contador-columnas + 1
  ]
  report resp
end

;; la hormiga realiza un recorrido desde la columna 0 a la columna num-reinas - 1
to-report generar-recorrido
  let num-columna 0
  let origen one-of nodos with [i = num-columna]
  let nuevo-recorrido (list origen)
  let labels (list [label] of origen)
  let filas (list [j] of origen)
  ;; la hormiga solo puede desplazarse a un nodo de la siguiente columna
  let resto-nodos [self] of nodos with [i = num-columna + 1
     ;; no puede haber dos nodos en el recorrido con la misma etiqueta
     and not member? label labels
     ;; ni tampoco dos nodos en una misma fila del tablero
     and not member? j filas
     ]
  let nodo-actual origen
  setxy [xcor] of nodo-actual [ycor] of nodo-actual

  ;; Se ejecuta el bucle hasta que la hormiga haya llegado a la última columna
  ;; El procesamiento es análogo a la selección del punto de partida (mismas restricciones)
  while [num-columna < num-reinas - 1][
    ;; Se calculan los costes de las aristas para determinar el número de colisiones
    ;; que se producirían si se añade cada uno de los nodos del listado resto-nodos
    ;; al recorrido.
    actualiza-costes-aristas nuevo-recorrido resto-nodos
    let siguiente-nodo elige-siguiente-nodo nodo-actual resto-nodos
    set nuevo-recorrido lput siguiente-nodo nuevo-recorrido
    set labels lput [label] of siguiente-nodo labels
    set filas lput [j] of siguiente-nodo filas
    set resto-nodos [self] of nodos with [i = num-columna + 2
       and not member? label labels
       and not member? j filas
       ]
    set nodo-actual siguiente-nodo
    move-to siguiente-nodo
    set num-columna num-columna + 1
  ]

  ;foreach nuevo-recorrido[ ask ?[show (word "[[Nuevo recorrido]] = " "i=" i " j=" j " label=" label )]]
  report nuevo-recorrido
end


to-report elige-siguiente-nodo [nodo-actual resto-nodos]
  let probabilidades calcula-probabilidades nodo-actual resto-nodos
  ;show (word "Probabilidades = " probabilidades)
  let rand-num random-float 1
  report last first filter [first ? >= rand-num] probabilidades
end

; Devuelve una lista de pares (p n), donde n es el nodo, y p la probabilidad de pasar a él desde el nodo actual
; las probabilidades van acumuladas, es decir, primero se normalizan para que la suma sea 1, después se ordenan
; de mayor a menor, y por último se realiza la suma acumulada (es decir, la función de densidad)
to-report calcula-probabilidades [nodo-actual resto-nodos]
  let pt map [([feromona] of ? ^ alpha) * ((1 / (1 + [coste] of ?)) ^ beta)] (map [arista nodo-actual ?] resto-nodos)
  ;show (word "pt=" pt)
  let denominador sum pt
  ;show (word "denominador=" denominador)
  set pt map [? / denominador] pt
  ;show (word "newpt=" pt)
  let probabilidades sort-by [first ?1 < first ?2] (map [(list ?1 ?2)] pt resto-nodos)
  let probabilidad-normalizada []
  let ac 0
  foreach probabilidades [
    set ac (ac + first ?)
    set probabilidad-normalizada lput (list ac last ?) probabilidad-normalizada
  ]
  report probabilidad-normalizada
end

to actualiza-feromona
  ;; Evapora la feromona del grafo
  ask links [
    set feromona (feromona * (1 - rho))
  ]

  ;; Añade feromona a los caminos encontrados por las hormigas
  ask hormigas [
    ;show (word "Coste recorrido= " coste-recorrido)
    let inc-feromona (1 / (1 + coste-recorrido))
    foreach aristas-recorrido recorrido [
      ask ? [
     ;   show (word "Feronomona antes= " feromona)
        set feromona (feromona + inc-feromona)
     ;   show (word "Feronomona despues= " feromona)
        set thickness feromona ]
    ]
  ]
end

;; Función que calcula el coste de las aristas que se tendrán en cuenta a la hora de elegir
;; el siguiente nodo del recorrido de la hormiga.
;; El coste viene dado por el número de colisiones que se producen entre los nodos del recorrido
;; actual que lleva la hormiga, y el siguiente nodo que se incluya en el camino (elegido de resto-nodos).
to actualiza-costes-aristas [recorrido-actual resto-nodos]
  let nodo-actual last recorrido-actual
  foreach resto-nodos [
    let recorrido-temporal lput ? recorrido-actual
    let fitness calcular-fitness recorrido-temporal
    ask arista nodo-actual ? [
      set coste fitness
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Procedimientos Plot/GUI ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to muestra-mejor-recorrido
  ask links [ hide-link ]
  foreach aristas-recorrido mejor-recorrido [
    ask ?
    [
      show-link
      ;set label coste
      set color green
      ;set label-color green
    ]
  ]

  set posiciones-reinas []
  foreach mejor-recorrido [
    ask ?[
      set posiciones-reinas lput (word "[" i "," j "]") posiciones-reinas
    ]
  ]

  ;show (word "Labels=" [label] of (turtle-set mejor-recorrido))
  ;foreach mejor-recorrido[ ask ?[show (word "i=" i " j=" j " label=" label )]]
end

to dibuja-plots
  set-current-plot "Coste Mejor Recorrido"
  plot coste-mejor-recorrido

  set-current-plot "Distribución Costes de Recorridos"
  set-plot-pen-interval 1
  set-plot-x-range 0 int (2 * (coste-mejor-recorrido + 1))
  histogram  [coste-recorrido] of hormigas
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Procedimientos auxiliares ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report aristas-recorrido [nodos-recorrido]
  report map [arista (item ? nodos-recorrido) (item (? + 1) nodos-recorrido)] (n-values (num-reinas - 1) [?])
end

to-report arista [n1 n2]
  report (link [who] of n1 [who] of n2)
end

to-report longitud-recorrido [nodos-recorrido]
  report reduce [?1 + ?2] map [[coste] of ?] (aristas-recorrido nodos-recorrido)
end

;; Calcular el número de colisiones entre reinas que se producen
;; en los nodos de un recorrido, siendo 0 el mejor fitness que se puede obtener y 28 el peor
to-report calcular-fitness [nodos-recorrido]
  let colisiones 0
  let x1 0
  while [x1 < (length nodos-recorrido) - 1][
    let y1 [j] of item x1 nodos-recorrido
    let x2 x1 + 1
    while [x2 < length nodos-recorrido][
      let y2 [j] of item x2 nodos-recorrido
      ifelse y2 = y1
      [
        set colisiones colisiones + 1
      ]
      [
        let magnitud-x abs (x2 - x1)
        let magnitud-y abs (y2 - y1)
        if magnitud-x = magnitud-y
        [
          set colisiones colisiones + 1
        ]
      ]
      set x2 x2 + 1
    ]
    set x1 x1 + 1
  ]
  report colisiones
end
@#$#@#$#@
GRAPHICS-WINDOW
210
60
682
553
-1
-1
7.0
1
10
1
1
1
0
0
0
1
0
65
0
65
1
1
1
ticks
30.0

BUTTON
10
10
200
43
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

BUTTON
105
160
197
193
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
690
185
832
230
Mejor número colisiones
coste-mejor-recorrido
3
1
11

PLOT
690
60
875
180
Coste Mejor Recorrido
Tiempo
Coste
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
880
60
1130
180
Distribución Costes de Recorridos
Coste
Nº Hormigas
0.0
50.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.1 1 -16777216 true "" ""

SLIDER
10
80
102
113
alpha
alpha
0
20
1.5
0.5
1
NIL
HORIZONTAL

SLIDER
105
80
197
113
beta
beta
0
20
1
0.5
1
NIL
HORIZONTAL

SLIDER
10
115
102
148
rho
rho
0
0.99
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
105
45
197
78
num-hormigas
num-hormigas
0
200
15
5
1
NIL
HORIZONTAL

SLIDER
10
45
102
78
num-reinas
num-reinas
4
20
8
1
1
NIL
HORIZONTAL

SLIDER
105
115
197
148
tam-arista
tam-arista
1
10
1
1
1
NIL
HORIZONTAL

BUTTON
10
160
100
193
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
210
10
1415
55
Combinación reinas
posiciones-reinas
17
1
11

SWITCH
10
285
195
318
mostrar-tablero-solucion?
mostrar-tablero-solucion?
0
1
-1000

SWITCH
10
245
195
278
dibujar-recorrido-hormigas?
dibujar-recorrido-hormigas?
0
1
-1000

SWITCH
10
205
195
238
dibujar-nodos?
dibujar-nodos?
0
1
-1000

@#$#@#$#@
# ALGORITMOS DE HORMIGAS
## EJERCICIO 1 - ACO PROBLEMA 8 REINAS

Este modelo está fuertemente basado en el artículo Solution of n-Queen Problem Using ACO disponible en http://www.iba.t.u-tokyo.ac.jp/iba/AI/khan.pdf

En el código se indican los conceptos más importantes para la resolución del problema.


##¿QUÉ ES?

Este modelo es una implementación del algoritmo AS (Ant System) aplicado a la resolución del Problema de las 8 Reinas.

##¿CÓMO FUNCIONA?

El algoritmo AS se puede usar para encontrar el camino más corto en un grafo por medio del mismo mecanismo descentralizado que usan las hormigas para recolectar comida. En el modelo, cada agente (hormiga)construye un camino en el grafo decidiendo en cada nodo qué nodo visitará a continuación de acuerdo a una probabilidad asociada a cada arista. La probabilidad de que una hormiga escoja un nodo específico en un momento viene determinada por la cantidad de feromona y por el coste de la arista que une dicho nodo con el nodo en el que la hormiga esté actualmente.

En el modelo se pueden ajustar los parámetros del algoritmo (alpha, beta y rho)para modificar el comportamiento del algoritmo. Los valores alpha y beta se usan para determinar la probabilidad de transición de la que se ha hablado antes, afectando la influencia relativa entre la feromona de cada arista y el coste que tiene. El valor de rho está asociado a la tasa de evaporación de feromona que permite al algoritmo "olvidar" aquellos tramos que no son muy visitados porque no han intervenido en recorridos buenos.

### ESPACIO DE BÚSQUEDA
El espacio de búsqueda está formado por N^2 filas x N columnas que se representa en forma de grid de nodos.

Las etiquetas de los nodos representan la celda del tablero de ajedrez, por ejemplo,
la etiqueta 1 se usa para mapear la celda [0,0], la etiqueta 2 mapea la celda [0,1]
y la etiqueta n^2 mapea la celda [n-1, n-1].

### RESTRICCIONES
Las siguientes restricciones se han añadido al algoritmo básico de ACO:
- Una hormiga solo puede moverse de izquierda a derecha.
- Una vez se haya seleccionado un nodo en una determinada columna i, la hormiga solo se puede mover a un nodo de la columna i + 1.
- El recorrido termina cuando la hormiga llega a la última columna.
- Una hormiga solo puede visitar n nodos (8 en el caso del problema de las 8 reinas).
- En un recorrido no puede haber dos nodos con la misma etiqueta.
- En un recorrido no puede haber dos nodos que representen una misma fila en el tablero.

### INICIALIZACIÓN Y ECUACIONES
Inicialmente a todas las aristas se les asigna la misma cantidad de feromonas. El valor de las feromonas se va modificando dependiendo del valor de fitness de la solución encontrada por la hormiga.

- Valor de fitness: El valor de fitness viene dado por el número de colisiones que se producen entre las reinas colocadas en el tablero. El mejor fitness de una solución en este problema es 0.

- Valor heurística: La función de probabilidad de elegir el siguiente nodo en el recorrido, es la misma que en el ACO básico, pero en este caso se utiliza el número de colisiones que se producen si se selecciona un determinado nodo como siguiente nodo del recorrido, en lugar de la distancia entre dos nodos.


##¿CÓMO SE USA?

Selecciona el número de nodos, el número de hormigas que recorrerán el grafo, y los parámetros que se usarán para la ejecución del algoritmo. Pulsa SETUP para crear los componentes que se usarán en la ejecución del algoritmo. GO para ejecutarlo, y RESET para mantener el mismo grafo y poder modificar el resto de parámetros (lo que permite hacer comparaciones entre los parámetros sobre el mismo grupo de datos).

ALPHA controla la tendencia de las hormigas para explotar caminos con altas cantidades de feromona. BETA controla cómo de "tacañas" son las hormigas, es decir, si tienen tendencia alta a buscar aristas de bajo coste (aunque a veces no sea bueno).

TAM-ARISTA simplemente se utiliza para indicar el tamaño que tendrán las aristas en el espacio de búsqueda representado en la ventana de VIEW. No interviene de ninguna forma en la ejecución del problema.

DIBUJAR-NODOS? permite indicar si se desean mostrar los nodos del espacio de búsqueda. Tampoco influye en la ejecución del problema.

DIBUJAR-RECORRIDO-HORMIGA? igualmente permite seleccionar si se desean mostrar los caminos que recorren las hormigas en cada iteración. Tampoco influye en la simulación del problema.

MOSTRAR-TABLERO-SOLUCIÓN? indica si se mostrará el tablero de ajedrez con las reinas cuando se encuentre una solución en la ventana VIEW. El espacio de búsqueda se elimina de la representación gráfica cuando se activa esta opción y se encuentra una solución al problema.


## COSAS A TENER EN CUENTA

En el modelo se muestran dos plots para visualizar la ejecución del algoritmo. Por una parte, en uno se muestra el coste del mejor recorrido encontrado en cada paso, mientras que en el segundo se muestra cómo se distribuyen las hormigas en el espacio de soluciones (un histograma de número de hormigas respecto del coste de sus caminos)

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

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

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

chess queen
false
0
Circle -7500403 true true 140 11 20
Circle -16777216 false false 139 11 20
Circle -7500403 true true 120 22 60
Circle -16777216 false false 119 20 60
Rectangle -7500403 true true 90 255 210 300
Line -16777216 false 75 255 225 255
Rectangle -16777216 false false 90 255 210 300
Polygon -7500403 true true 105 255 120 90 180 90 195 255
Polygon -16777216 false false 105 255 120 90 180 90 195 255
Rectangle -7500403 true true 105 105 195 75
Rectangle -16777216 false false 105 75 195 105
Polygon -7500403 true true 120 75 105 45 195 45 180 75
Polygon -16777216 false false 120 75 105 45 195 45 180 75
Circle -7500403 true true 180 35 20
Circle -16777216 false false 180 35 20
Circle -7500403 true true 140 35 20
Circle -16777216 false false 140 35 20
Circle -7500403 true true 100 35 20
Circle -16777216 false false 99 35 20
Line -16777216 false 105 90 195 90

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
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

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
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>best-tour-cost</metric>
  </experiment>
</experiments>
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
1
@#$#@#$#@
