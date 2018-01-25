;; Cada solución potencial está representada por una tortuga

turtles-own [
  bits           ;; lista de 0's y 1's
  fitness
]

globals [
  ganador         ;; tortuga que actualmente tiene la mejor solución
  cadena-salida
]

to setup
  ca
  reset-ticks
  create-turtles poblacion [
    set bits n-values 10 [one-of [0 1]] ;; Listas de 10 bits. El bit representa si la carta i-ésima va en el mazo de sumas o en el de multiplicaciones. Cartas de 1 a 10
    calcular-fitness
    hide-turtle  ;; No se usa la representaci�n de las tortugas, as� que las ocultamos
  ]
  actualizar-visualizacion
  dibujar
  reset-ticks
end

to go
  ;; Una solución al problema se encuentra cuando el valor de fitness vale 0
  if [fitness] of ganador = 0
    [ stop ]
  crear-siguiente-generacion
  actualizar-visualizacion
  tick
  dibujar
end

to actualizar-visualizacion
  set ganador min-one-of turtles [fitness]
  let lista-suma []
  let lista-mult []
  let i 0
  while [i < length [bits] of ganador][
    ifelse item i [bits] of ganador = 0
    [set lista-suma lput (i + 1) lista-suma]
    [set lista-mult lput (i + 1) lista-mult]
    set i i + 1
  ]
  let suma ifelse-value empty? lista-suma [0] [reduce + lista-suma]
  let mult ifelse-value empty? lista-mult [0] [reduce * lista-mult]
  set cadena-salida (word lista-suma "=[" suma "] ------ " lista-mult "=[" mult"]")
end

;; ===== Generar Soluciones

;; Cada soluci�n tiene su valor de fitness calculado.
;; Valores m�s altos representan mejor adaptados.
;; Por tanto, cuanto mayor es su fitness, mayor es la probabilidad
;;   de que ser� seleccionada para reproducirse y crear una nueva
;;   generaci�n de posibles soluciones.
;;;;;;;
to calcular-fitness       ;; procedimiento de tortuga
  ;; Crear dos listados que representan a los dos mazos
  let lista-suma []
  let lista-mult []
  ;; Recorrer los genes del cromosoma, en otras palabras, los bits de la solución.
  let i 0
  while [i < length bits][
    ;; Si el bit es 0, se coloca la carta en el mazo de sumas. Si es 1, se coloca
    ;; en el mazo de multiplicaciones
    ifelse item i bits = 0
    [set lista-suma lput (i + 1) lista-suma]
    [set lista-mult lput (i + 1) lista-mult]
    set i i + 1
  ]
  ;; Se calcula el valor absoluto de la diferencia entre la suma de las cartas del mazo de sumas
  ;; y 36, y por otro lado, la multiplicación de las cartas del mazo de multiplicaciones y 360
  let dif-suma abs ifelse-value empty? lista-suma [36] [(reduce + lista-suma) - 36]
  let dif-mult abs ifelse-value empty? lista-mult [360] [(reduce * lista-mult) - 360]
  ;; El valor de fitness viene determinado por la suma de los dos valores absolutos de las
  ;; diferencias.
  set fitness dif-suma + dif-mult
end

;; Este procedimiento hace el trabajo principal del algoritmo gen�tico.
;; Se parte de la generaci�n anterior de soluciones.
;; Se seleccionan las soluciones que tienen buen fitness para reproducirse
;; por medio del cruzamiento (recombinaci�n sexual), y para ser clonadas
;; (reproducci�n asexual) en la siguiente generaci�n.
;; Hay tambi�n una opci�n de mutaci�n en cada individuo.
;; Tras generar completamente la nueva generaci�n, la generaci�n previa muere.
to crear-siguiente-generacion
  ; Hacemos una copia de las tortugas que hay en este momento.
  let generacion-anterior turtles with [true]

  ; Algunas de las soluciones actuales se conseguir� por medio del cruzamiento,
  ; Se divide entre 2 porque en cada paso del bucle se generan 2 nuevas soluciones.
  let numero-cruzamientos  (floor (poblacion * razon-cruzamiento / 100 / 2))

  repeat numero-cruzamientos
  [
    ; Se ha usado una selecci�n por torneo, con un tama�o de 3 elementos.
    ; Es decir, se toman aleatoriamente 3 soluciones de la generaci�n previa
    ; y nos quedamos con el mejor de esos 3 para la reproducci�n.

    let padre1 min-one-of (n-of 3 generacion-anterior) [fitness]
    let padre2 min-one-of (n-of 3 generacion-anterior) [fitness]

    let bits-hijo cruzamiento ([bits] of padre1) ([bits] of padre2)

    ; crea 2 hijos con sus informaciones gen�ticas
    ask padre1 [ hatch 1 [ set bits item 0 bits-hijo ] ]
    ask padre2 [ hatch 1 [ set bits item 1 bits-hijo ] ]
  ]

  ; el resto de la poblaci�n se crea por clonaci�n directa
  ; de algunos miembros seleccionados de la generaci�n anterior
  repeat (poblacion - numero-cruzamientos * 2)
  [
    ask min-one-of (n-of 3 generacion-anterior) [fitness]
      [ hatch 1 ]
  ]

  ; Eliminamos toda la generaci�n anterior
  ask generacion-anterior [ die ]

  ; y sobre el resto de tortugas (generaci�n reci�n generada)...
  ask turtles
  [
    ; realizamos la mutaci�n (es un proceso probabil�stico)
    mutar
    ; y actualizamos su valor de fitness
    calcular-fitness
  ]
end

;; ===== Cruzamientos y Mutaciones

;; La siguiente funci�n realiza un cruzamiento (en un punto) de dos
;; listas de bits: a,b. Estos es, selecciona aleatoriamente un punto en
;; ambas listas: a1|a2, b1|b2, donde long(ai)=long(bi)
;; y devuelve: a1|b2, b1|a2
to-report cruzamiento [bits1 bits2]
  let punto-corte 1 + random (length bits1 - 1)
  report list (sentence (sublist bits1 0 punto-corte)
                        (sublist bits2 punto-corte length bits2))
              (sentence (sublist bits2 0 punto-corte)
                        (sublist bits1 punto-corte length bits1))
end

;; El siguiente procedimiento povoca la mutaci�n aleatoria de los bits de una
;; soluci�n. La probabilidad de modificar cada bit se controla por medio del
;; slider RAZON-MUTACION.
;; Para este problema, la mutación consiste en intercambiar dos cartas de un mazo a otro.
to mutar   ;; procedimiento de tortuga
  let i1 0
  while [i1 < length bits][
    if random-float 100.0 < razon-mutacion
    [
      let i2 random length bits
      while [i1 = i2][
        set i2 random length bits
      ]
      let temp item i1 bits
      set bits replace-item i1 bits item i2 bits
      set bits replace-item i2 bits temp
    ]
    set i1 i1 + 1
  ]
end

;; ===== Medidas de diversidad

;; La medida de diversidad que se proporciona es la media de las distancias de
;; Hamming entre todos los pares de soluciones.
to-report diversidad
  let distancias []
  ask turtles [
    let bits1 bits
    ask turtles with [self > myself] [
      set distancias fput (distancia-hamming bits bits1) distancias
    ]
  ]
  ; Necesitamos conocer la mayor posible distancia de Hamming entre pares de
  ; bits de este tama�o. La siguiente f�rmula se intepreta de la siguient forma:
  ; Imaginemos una poblaci�n de N tortugas, con N par, y cada tortuga tiene un
  ; �nico bit (0 o 1). La mayor diversidad se tiene si la mitad de la poblaci�n
  ; tiene 0, y la otra mitad tiene 1 (se puede calcular por c�lculo diferencial).
  ; En este caso, hay (N / 2) * (N / 2) pares de bits que difieren.
  ; Se puede probar que esta f�rmula (tomando parte entera) tambi�n vale cuando
  ; N es impar.
  let max-posibles-distancias floor (count turtles * count turtles / 4)

  ; A partir del valor anterior podemos normalizar la medida de diversidad para que
  ; tome un valor entre 0 (poblaci�n completamente homog�nea) y 1 (heterogeneidad
  ; m�xima)
  report (sum distancias) / max-posibles-distancias
end

;; La distancia de Hamming entre dos sucesiones de bits es la fracci�n de
;; posiciones en las que difieren. Se usa MAP para comparar las sucesiones,
;; posteriormente REMOVE para quitar los resultados de igualdad, y LENGTH
;; para contar los que quedan (las diferencias).
to-report distancia-hamming [bits1 bits2]
  report (length remove true (map [?1 = ?2] bits1 bits2)) / 10
end

;; ====== Plotting

to dibujar
  let lista-fitness [fitness] of turtles
  let mejor-fitness min lista-fitness
  let media-fitness mean lista-fitness
  let peor-fitness max lista-fitness
  set-current-plot "Fitness"
  set-current-plot-pen "mejor"
  plot mejor-fitness

  ;; dibujar el peor/media fitness únicamente cuando sea menor de 500
  ;; para que el resto de valores de la gráfica se aprecien adecuadamente
  if peor-fitness <= 500 and media-fitness <= 500[
    set-current-plot-pen "media"
    plot media-fitness
    set-current-plot-pen "peor"
    plot peor-fitness
  ]
  if plot-diversidad?
  [
    set-current-plot "Diversidad"
    set-current-plot-pen "diversidad"
    plot diversidad
  ]
end


; Copyright 2008 Uri Wilensky. All rights reserved.
; The full copyright notice is in the Information tab.
@#$#@#$#@
GRAPHICS-WINDOW
532
68
777
253
10
10
7.333333333333333
1
10
1
1
1
0
1
1
1
-10
10
-10
10
1
1
1
ticks
30.0

BUTTON
100
50
185
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
12
10
185
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
12
90
184
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
197
66
523
298
Fitness
gen #
fitness
0.0
20.0
0.0
100.0
true
true
"" ""
PENS
"mejor" 1.0 0 -2674135 true "" ""
"media" 1.0 0 -10899396 true "" ""
"peor" 1.0 0 -13345367 true "" ""

BUTTON
12
50
97
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
12
170
184
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
197
305
524
425
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
12
212
184
245
plot-diversidad?
plot-diversidad?
0
1
-1000

SLIDER
12
130
184
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

MONITOR
197
10
696
55
Ganador
cadena-salida
17
1
11

@#$#@#$#@
# ALGORITMOS GENÉTICOS
## EJERCICIO 3 - PROBLEMA CARTAS

Resuelve el siguiente problema: Tienes 10 cartas numeradas del 1 al 10. Has de dividirlas en 2 montones de forma que las cartas de uno de los montones sume el número más próximo posible a 36 y el producto de las cartas del otro montón sea lo más cercano posible a 360.

## CÓMO FUNCIONA

Para resolver el problema de las cartas con Algoritmo Genético se han seguido los siguientes pasos:

1. Se crea una población inicial de cromosomas/soluciones. Cada cromosoma está formado por una cadena de tamaño 10, rellenada aleatoriamente con "1"s y "0"s. Un 0 en la posición i-ésima significa que la carta de valor i se meterá en el mazo de sumas. Un 1 en la posición i-ésima significa que la carta de valor i se meterá en el mazo de las multiplicaciones. Por ejemplo, dada la solución [0 0 0 0 0 1 1 1 1 1], el mazo de sumas lo compondrán las cartas [1 2 3 4 5] y el de multiplicaciones será [6 7 8 9 10].
2. Se evalúa la función de fitness para cada cromosoma/solución de la siguiente forma:
	2.1. Sumar las cartas del mazo de sumas. Obtener el valor absoluto de la resta entre el valor obtenido y 36, es decir, |Resultado_suma - 36|.
	2.2. Multiplicar las cartas del mazo de multiplicaciones. Obtener el valor absoluto de la resta entre el valor obtenido y 360, es decir, |Resultado_multiplicación - 360|.
	2.3. Sumar los dos valores absolutos calculados. Una solución al problema se encontrará cuando esta suma sea 0, es decir, el problema se encargará de minimizar el valor de fitness.
3. Se genera una nueva generación de soluciones a partir de la anterior donde aquellas soluciones con un menor valor de fitness tienen más probabilidad de ser escogidas como padres de la nueva generación de cromosomas/soluciones.
	3.1. La estrategia de selección usada en el ejercicio es el de torneo de tamaño 3, lo que significa que se toman aleatoriamente 3 soluciones de la generación anterior, y de entre ellos se toma el que tenga mejor fitness para ser uno de los padres de la siguiente generación.
	3.2. Se toman uno o dos padres para crear un hijo nuevo. Con un padre, el hijo es un clon exacto de su padre. Con dos padres, se produce una recombinación de su información genética para obtener dos hijos.
	3.3. También hay una probabilidad de mutación en cada una de las soluciones, de forma que se pueden intercambiar dos cartas entre mazos.
4. Los pasos 2 y 3 anteriores se repiten hasta que se encuentra una solución que satisface el problema.

## CÓMO SE USA

Pulsa SETUP para crear una población aleatoria inicial de soluciones.

Pulsa UN PASO para obtener una nueva generación a partir de la generación actual.

Pulsa GO para aplicar el algoritmo genético hasta que se encuentre una solución.

En el monitor GANADOR se muestra la mejor solución de cada generación (combinación de cartas en el mazo de suma y combinación de cartas en el mazo de multiplicaciones).

### PARÁMETROS

El slider POBLACION controla el número de soluciones que están presentes en cada generación.

La RAZON-CRUZAMIENTO controla el porcentaje de individuos de la nueva generaci�n que serán creados por medio de reproducción sexual (usando 2 padres) y el porcentaje que lo hará por medio de reproducción asexual (clonación directa).

La RAZON-MUTACION controla el porcentaje de cambio por mutación. Esta cantidad se aplica a cada posición de cada cadena de los nuevos individuos.

El switch PLOT-DIVERSIDAD? controla si la cantidad de diversidad en la población de soluciones debe ser calculada y representada en cada generación. Es un proceso que requiere mucho cálculo, por lo que al desactivarlo se incrementa considerablemente la velocidad del modelo.

El plot "Fitness" se usa para mostrar el mejor, medio y peor fitness de los individuos de cada generación. Los valores medio y peor solo se representan cuando son menores que 500.

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
0
@#$#@#$#@
