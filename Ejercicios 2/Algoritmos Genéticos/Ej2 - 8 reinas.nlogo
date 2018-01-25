breed [cromosomas cromosoma]
breed [reinas reina]

;; Cada solución potencial está representada por una tortuga

cromosomas-own [
  genes           ;; Listado de 8 números (columnas - i). Cada número representa la fila que ocupa la reina
                       ;; en la i-ésima columna.
  fitness
  ;fitness-ratio
]

globals [
  ganador         ;; tortuga que actualmente tiene la mejor soluci�n
  ;fitness-total
]

to setup
  ca
  reset-ticks
  dibuja-tablero
  create-cromosomas poblacion [
    generar-genes
    calcular-fitness
    hide-turtle  ;; No se usa la representación de las tortugas, así que las ocultamos
  ]
  ;calcular-fitness-ratio
  actualizar-visualizacion
  dibujar
  reset-ticks
end

to go
  ;; Si el valor de fitness del ganador es 28 significará que no se produce
  ;; ninguna colisión entre las reinas del tablero y por lo tanto se ha encontrado
  ;; una posible solución al problema de las 8 reinas.
  if [fitness] of ganador = 28
    [
      show (word "Ganador:" ganador " Fitness:" [fitness] of ganador)
      stop
    ]
  crear-siguiente-generacion
  actualizar-visualizacion
  tick
  dibujar
end

to actualizar-visualizacion
  ask reinas [die]
  set ganador max-one-of cromosomas [fitness]
  let i 0
  foreach [genes] of ganador [
    create-reinas 1 [
      setxy i ?
      set shape "chess queen"
      set color orange
      set size 0.7
    ]
    set i (i + 1)
  ]
 ; show (word "Ganador:" ganador " Fitness:" [fitness] of ganador)

end

;; Dibujar tablero de ajedrez
to dibuja-tablero
  resize-world 0 num-reinas - 1 0 num-reinas - 1
  ask patches [
    if-else ((pxcor - pycor) mod 2 = 0) [ set pcolor white ] [ set pcolor black ]
  ]
end

;; Generar genes aleatorios que cumplen la restricción de que dos reinas
;; no pueden estar en la misma fila
to generar-genes ;; proceso de tortugas
  let posiciones-reinas n-values num-reinas [?]
  set genes shuffle posiciones-reinas
end

;to calcular-fitness-ratio
  ;ask cromosomas [set fitness-ratio fitness / fitness-total * 100]
;end

;; Cada solución tiene su valor de fitness calculado.
;; Valores más altos representan mejor adaptados.
;; Por tanto, cuanto mayor es su fitness, mayor es la probabilidad
;; de que será seleccionada para reproducirse y crear una nueva
;; generación de posibles soluciones.
to calcular-fitness       ;; procedimiento de tortuga

  let colisiones 0
  let i 0
  while [i < (length genes) - 1][
    let x i
    let y item i genes
    let j i + 1
    while [j < length genes][
      ifelse (item j genes) = y
      [set colisiones colisiones + 1]
      [
        let magnitud-x abs (j - x)
        let magnitud-y abs ((item j genes) - y)
        if magnitud-x = magnitud-y
        [set colisiones colisiones + 1]
      ]
      set j j + 1
    ]
    set i i + 1
  ]
  ;; Fitness tendrá se encuentra en el rango [0,28] de tal modo que 0 indica que
  ;; las reinas de han colocado de la peor forma posible y se producen 28 colisiones. Si el fitness
  ;; es 0, significa que no se produce ninguna colisión entre las reinas del tablero.
  ;; Por lo tanto estamos ante un problema de maximización.
  set fitness 28 - colisiones
  ;set fitness-total fitness-total + fitness

end


;; Este procedimiento hace el trabajo principal del algoritmo genético.
;; Se parte de la generación anterior de soluciones.
;; Se seleccionan las soluciones que tienen buen fitness para reproducirse
;; por medio del cruzamiento (recombinación sexual), y para ser clonadas
;; (reproducción asexual) en la siguiente generación.
;; Hay tambión una opción de mutación en cada individuo.
;; Tras generar completamente la nueva generación, la generación previa muere.
to crear-siguiente-generacion
  ; Hacemos una copia de las tortugas que hay en este momento.
  let generacion-anterior cromosomas with [true]

  ; Algunas de las soluciones actuales se conseguirá por medio del cruzamiento,
  ; Se divide entre 2 porque en cada paso del bucle se generan 2 nuevas soluciones.
  let numero-cruzamientos  (floor (poblacion * razon-cruzamiento / 100 / 2))

  repeat numero-cruzamientos
  [
    ; Se ha usado una selección por torneo, con un tamaño de 3 elementos.
    ; Es decir, se toman aleatoriamente 3 soluciones de la generación previa
    ; y nos quedamos con el mejor de esos 3 para la reproducción.

    let padre1 max-one-of (n-of 3 generacion-anterior) [fitness]
    let padre2 max-one-of (n-of 3 generacion-anterior) [fitness]

    let genes-hijo cruzamiento ([genes] of padre1) ([genes] of padre2)

    ; crea 2 hijos con sus informaciones genéticas
    ask padre1 [ hatch 1 [ set genes item 0 genes-hijo ] ]
    ask padre2 [ hatch 1 [ set genes item 1 genes-hijo ] ]
  ]

  ; el resto de la población se crea por clonación directa
  ; de algunos miembros seleccionados de la generaci�n anterior
  repeat (poblacion - numero-cruzamientos * 2)
  [
    ask max-one-of (n-of 3 generacion-anterior) [fitness]
      [ hatch 1 ]
  ]

  ; Eliminamos toda la generación anterior
  ask generacion-anterior [ die ]

 ; set fitness-total 0
  ; y sobre el resto de tortugas (generaci�n reci�n generada)...
  ask cromosomas
  [
    ; realizamos la mutación (es un proceso probabilístico)
    mutar
    ; y actualizamos su valor de fitness
    calcular-fitness
  ]
  ;calcular-fitness-ratio
end

;; ===== Cruzamientos y Mutaciones

;; La siguiente funci�n realiza un cruzamiento (en un punto) de dos
;; listas de genes: a,b. Estos es, selecciona aleatoriamente un punto en
;; ambas listas: a1|a2, b1|b2, donde long(ai)=long(bi)
;; y devuelve: a1|b2, b1|a2
to-report cruzamiento [genes1 genes2]
  let punto-corte random (length genes1 - 1) + 1
  report list (sentence (sublist genes1 0 punto-corte)
                        (sublist genes2 punto-corte length genes2))
              (sentence (sublist genes2 0 punto-corte)
                        (sublist genes1 punto-corte length genes1))
end

;; El siguiente procedimiento provoca la mutación aleatoria de los genes de una
;; solución. La probabilidad de modificar cada bit se controla por medio del
;; slider RAZON-MUTACION.
;;;;;;;;;;;;;;;;;;;;;;;;;
;; Para el problema de las 8 reinas, la mutación consiste en intercambiar dos genes del cromosoma, es decir,
;; intercambiar la posición de dos reinas. De este modo se siguen cumpliendo las restricciones
;; de que no puede haber dos reinas en una misma fila ni tampoco en una misma columna.
to mutar   ;; procedimiento de tortuga
  let i1 0
  while [i1 < length genes][
    if random-float 100.0 < razon-mutacion
    [
      let i2 random length genes
      while [i1 = i2][
        set i2 random length genes
      ]
      let temp item i1 genes
      set genes replace-item i1 genes item i2 genes
      set genes replace-item i2 genes temp
      ]
    set i1 i1 + 1
    ]
end

;; ===== Medidas de diversidad

;; La medida de diversidad que se proporciona es la media de las distancias de
;; Hamming entre todos los pares de soluciones.
to-report diversidad
  let distancias []
  ask cromosomas [
    let genes1 genes
    ask cromosomas with [self > myself] [
      set distancias fput (distancia-hamming genes genes1) distancias
    ]
  ]
  ; Necesitamos conocer la mayor posible distancia de Hamming entre pares de
  ; genes de este tama�o. La siguiente f�rmula se intepreta de la siguient forma:
  ; Imaginemos una poblaci�n de N tortugas, con N par, y cada tortuga tiene un
  ; �nico bit (0 o 1). La mayor diversidad se tiene si la mitad de la poblaci�n
  ; tiene 0, y la otra mitad tiene 1 (se puede calcular por c�lculo diferencial).
  ; En este caso, hay (N / 2) * (N / 2) pares de genes que difieren.
  ; Se puede probar que esta f�rmula (tomando parte entera) tambi�n vale cuando
  ; N es impar.
  let max-posibles-distancias floor (count cromosomas * count cromosomas / 4)

  ; A partir del valor anterior podemos normalizar la medida de diversidad para que
  ; tome un valor entre 0 (poblaci�n completamente homog�nea) y 1 (heterogeneidad
  ; m�xima)
  report (sum distancias) / max-posibles-distancias
end

;; La distancia de Hamming entre dos sucesiones de genes es la fracci�n de
;; posiciones en las que difieren. Se usa MAP para comparar las sucesiones,
;; posteriormente REMOVE para quitar los resultados de igualdad, y LENGTH
;; para contar los que quedan (las diferencias).
to-report distancia-hamming [genes1 genes2]
  report (length remove true (map [?1 = ?2] genes1 genes2)) / num-reinas
end

;; ====== Plotting

to dibujar
  let lista-fitness [fitness] of cromosomas
  let mejor-fitness max lista-fitness
  let media-fitness mean lista-fitness
  let peor-fitness min lista-fitness
  set-current-plot "Fitness"
  set-current-plot-pen "media"
  plot media-fitness
  set-current-plot-pen "mejor"
  plot mejor-fitness
  set-current-plot-pen "peor"
  plot peor-fitness
  if plot-diversidad?
  [
    set-current-plot "Diversidad"
    set-current-plot-pen "diversidad"
    plot diversidad
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
305
10
635
361
-1
-1
40.0
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
7
0
7
1
1
1
ticks
30.0

BUTTON
150
50
235
83
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
62
10
235
43
NIL
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
62
90
234
123
poblacion
poblacion
5
200
200
5
1
NIL
HORIZONTAL

PLOT
10
297
293
417
Fitness
gen #
fitness
0.0
20.0
0.0
28.0
true
true
"" ""
PENS
"mejor" 1.0 0 -2674135 true "" ""
"media" 1.0 0 -10899396 true "" ""
"peor" 1.0 0 -13345367 true "" ""

BUTTON
62
50
147
83
Un paso
go
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
62
170
234
203
razon-mutacion
razon-mutacion
0
10
0.5
0.1
1
NIL
HORIZONTAL

PLOT
11
421
293
541
Diversidad
gen #
diversidad
0.0
20.0
0.0
1.0
true
false
"" ""
PENS
"diversidad" 1.0 0 -8630108 true "" ""

SWITCH
62
212
234
245
plot-diversidad?
plot-diversidad?
0
1
-1000

SLIDER
62
130
234
163
razon-cruzamiento
razon-cruzamiento
0
100
80
1
1
NIL
HORIZONTAL

SLIDER
60
250
235
283
num-reinas
num-reinas
4
20
8
1
1
NIL
HORIZONTAL

@#$#@#$#@
# ALGORITMOS GENÉTICOS
## EJERCICIO 2 - PROBLEMA 8 REINAS

Resuelve el problema de las 8 reinas con un Algoritmo Genético.

El juego de las ocho reinas consiste en colocar sobre un tablero de ajedrez ocho reinas sin que estas se amenacen entre ellas. Este problema se puede extender a N reinas, de tal modo que hay que colocar en un tablero de dimensión NxN,  N reinas sin que se amenacen entre ellas.

## CÓMO FUNCIONA

Para resolver el problema de las 8 reinas con Algoritmo Genético se han seguido los siguientes pasos:

1. Se crea una población inicial de cromosomas/soluciones. Cada cromosoma está formado por una cadena de 8 números (8 posibles columnas del tablero de ajedrez). Cada número representa la fila que ocupa la reina en la i-ésima columna. Por ejemplo, la cadena [2,5,3,4,7,6,0,1] indica que en la columna 0 hay una reina en la fila 2, en la columna 1 hay otra reina en la fila 5, y así sucesivamente. Al crear soluciones de esta forma se cumple que las reinas no estarán en la misma columna ni tampoco en la misma fila, por lo que únicamente se podrían producir ataques diagonales.
2. Se evalúa la función de fitness para cada cromosoma/solución. Para este problema el valor de fitness se encuentra en el rango [0,28], siendo 0 la peor solución posible y 28 la mejor solución (no se ataca ninguna reina). En este modelo el objetivo es maximizar este valor de fitness.
3. Se genera una nueva generación de soluciones a partir de la anterior donde aquellas soluciones con un mayor valor de fitness tienen más probabilidad de ser escogidas como padres de la nueva generación de cromosomas/soluciones.
	3.1. La estrategia de selección usada en el ejercicio es el de torneo de tamaño 3, lo que significa que se toman aleatoriamente 3 soluciones de la generación anterior, y de entre ellos se toma el que tenga mejor fitness para ser uno de los padres de la siguiente generación.
	3.2. Se toman uno o dos padres para crear un hijo nuevo. Con un padre, el hijo es un clon exacto de su padre. Con dos padres, se produce una recombinación de su información genética para obtener dos hijos.
	3.3. También hay una probabilidad de mutación en cada una de las soluciones, de forma que se puede intercambiar la posición de dos reinas en dos columnas.
4. Los pasos 2 y 3 anteriores se repiten hasta que se encuentra una solución que satisface el problema.

## CÓMO SE USA

Pulsa SETUP para crear una población aleatoria inicial de soluciones.

Pulsa UN PASO para obtener una nueva generación a partir de la generación actual.

Pulsa GO para aplicar el algoritmo genético hasta que se encuentre una solución.

En la ventana VIEW se muestra la mejor solución de cada generación (posiciones de las reinas en el tablero de ajedrez).

### PARÁMETROS

El slider POBLACION controla el número de soluciones que están presentes en cada generación.

La RAZON-CRUZAMIENTO controla el porcentaje de individuos de la nueva generaci�n que serán creados por medio de reproducción sexual (usando 2 padres) y el porcentaje que lo hará por medio de reproducción asexual (clonación directa).

La RAZON-MUTACION controla el porcentaje de cambio por mutación. Esta cantidad se aplica a cada posición de cada cadena de los nuevos individuos.

El slider NUM-REINAS controla el número de reinas que se colocarán en el tablero. Este parámetro también se usará para definir las dimensiones del mismo (NUM-REINAS x NUM-REINAS)

El switch PLOT-DIVERSIDAD? controla si la cantidad de diversidad en la población de soluciones debe ser calculada y representada en cada generación. Es un proceso que requiere mucho cálculo, por lo que al desactivarlo se incrementa considerablemente la velocidad del modelo.

El plot "Fitness" se usa para mostrar el mejor, medio y peor fitness de los individuos de cada generación.


## RECURSOS CONSULTADOS
http://www.cs.bc.edu/~alvarez/ML/GA/nQueensGA.html
http://www.cse.ust.hk/~derekhh/comp221/Genetic_Algorithms.pdf
http://genetic-algorithms-explained.appspot.com/#solution

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
need-to-manually-make-preview-for-this-model
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
1
@#$#@#$#@
