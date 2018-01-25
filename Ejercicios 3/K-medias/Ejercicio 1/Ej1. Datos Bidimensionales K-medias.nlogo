breed [lirios lirio]
breed [clusters cluster]

lirios-own [
  clase
  tipo
]
clusters-own [
  movido?
  tipo
]

patches-own [
  potencial
]

; TSet almacena los vectores de entrenamiento
globals [
  TSet
]

to setup
  ca
  leer-datos
  normalizar-datos
  ifelse Atributo1 = Atributo2
  [user-message( "Seleccione dos atributos distintos" )]
  [setup-lirios]
  reset-ticks
end

to setup-lirios
  let attr1 atributo-seleccionado Atributo1
  let attr2 atributo-seleccionado Atributo2
  ask patches [set pcolor grey]
  foreach TSet[
    create-lirios 1 [
      set tipo last ?
      setxy item attr1 ? item attr2 ?
      set color violet
      set shape "flower"
      set size 1
    ]
  ]
end

; Crea los clusters iniciales
to setup-clusters [m]
  cd
  ask clusters [die]
  create-clusters m [
    move-to one-of lirios
    set tipo [tipo] of one-of lirios-here
    set shape "flower"
    set size 2
    set movido? true
    set color -3 + 5 * (who - (count lirios)) ]
end

to K-medias
  ifelse any? clusters with [movido?]
  [
    ask lirios [
      set clase min-one-of clusters [distance myself]
      set tipo [tipo] of clase
      set color [color] of clase ]
    ask clusters [
      let cc-t lirios with [clase = myself]
      let cc count cc-t
      ifelse cc > 0
      [
        let x (sum [xcor] of cc-t) / cc
        let y (sum [ycor] of cc-t) / cc
        set movido? (distancexy x y > .01)
        setxy x y ]
      [
        setxy random-pxcor random-pycor
        set movido? true
      ]
    ]
    ask clusters [
      if any? other clusters with [distance myself < Tolerancia]
      [
        ask other clusters with [distance myself < Tolerancia] [
          face myself
          bk tolerancia
          ]
        set movido? true ]
    ]
  ]
  [
    stop
  ]
  tick
end

to representa-areas
  cd
  if potencial? [calculo-potencial]
  ask patches [
    let c [color] of min-one-of clusters [distance myself] + 2
    let p ifelse-value potencial? [potencial][0]
    set pcolor c - 4 * p ]
end

to calculo-potencial
  ask patches [set potencial sum [distance myself] of clusters]
  let m max [potencial] of patches
  ask patches [
    set potencial potencial / m
    ;set pcolor scale-color black potencial 1 0
    ]
end

to-report peso
  report sqrt sum [(distance clase) ^ 2] of lirios
end

to experimento
  clear-plot
  no-display
  set-current-plot "Peso"
  foreach (n-values Num-clusters-experimento [? + 1])
  [
    let p []
    repeat 50 [
      setup-clusters ?
      while [any? clusters with [movido?]]
      [ k-medias ]
      set p lput peso p
    ]
    plotxy ? ? * (mean p)
  ]
  display

end

to leer-datos
  file-close-all
  ;; Cargar fichero de texto del dataset
  let f "Ej1. Iris dataset.txt"
  if (f = false) [stop]
  set TSet []
  file-open f
  while [not file-at-end?]
  [
    let linea read-from-string (word "[" file-read-line "]")
    set TSet lput linea Tset
  ]
  file-close-all
end

to-report atributo-seleccionado [attr]
  let num-col 0
  if attr = "Anchura sépalo" [set num-col 1]
  if attr = "Longitud pétalo" [set num-col 2]
  if attr = "Anchura pétalo" [set num-col 3]
  report num-col
end

to normalizar-datos
  let i 0
  while [i < 4][
    let valores []
    foreach TSet[
      set valores lput item i ? valores
    ]
    let media mean valores
    let sd standard-deviation valores
    let j 0
    foreach TSet[
      let valor item i ?
      set ? replace-item i ? ((valor - media) / sd)
      set TSet replace-item j TSet ?
      set j j + 1
    ]
    set i i + 1
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
270
10
720
481
5
5
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
-5
5
-5
5
1
1
1
ticks
30.0

BUTTON
10
245
169
278
NIL
K-medias\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
150
112
183
Num-Clusters
Num-Clusters
1
100
3
1
1
NIL
HORIZONTAL

BUTTON
10
85
260
118
Cargar datos
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
112
150
188
216
Crea Clusters
setup-clusters Num-Clusters
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
10
183
113
216
Tolerancia
Tolerancia
0
50
0
.1
1
NIL
HORIZONTAL

SLIDER
740
130
900
163
Num-clusters-experimento
Num-clusters-experimento
0
100
15
1
1
NIL
HORIZONTAL

BUTTON
10
278
65
311
Areas
representa-areas
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
10
10
160
31
Datos a clasificar:
17
0.0
1

TEXTBOX
10
125
160
146
Nº Clasificadores:
17
0.0
1

TEXTBOX
10
220
160
241
Algoritmo:
17
0.0
1

SWITCH
65
278
169
311
Potencial?
Potencial?
0
1
-1000

PLOT
740
10
900
130
Peso
Nº Clusters
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

BUTTON
740
165
899
198
NIL
experimento
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
10
35
135
80
Atributo1
Atributo1
"Longitud sépalo" "Anchura sépalo" "Longitud pétalo" "Anchura pétalo"
0

CHOOSER
135
35
260
80
Atributo2
Atributo2
"Longitud sépalo" "Anchura sépalo" "Longitud pétalo" "Anchura pétalo"
3

PLOT
740
210
1150
400
Número lirios por tipo
NIL
# lirios
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Iris-virginica" 1.0 0 -13840069 true "" "plot count lirios with [tipo = \"Iris-virginica\"]"
"Iris-versicolor" 1.0 0 -1184463 true "" "plot count lirios with [tipo = \"Iris-versicolor\"]"
"Iris-setosa" 1.0 0 -2674135 true "" "plot count lirios with [tipo = \"Iris-setosa\"]"

@#$#@#$#@
# K-MEDIAS
## EJERCICIO 1

Busca un conjunto de datos bidimensionales en el que puedas aplicar el algoritmo de K-medias visto en clase.

## INFORMACIÓN SOBRE EL DATASET
El conjunto de datos seleccionados es una famosa base de datos que contiene información sobre distintos tres clases de lirios que se pueden encontrar en la naturaleza y sus propiedades.

Contiene 3 clases de 50 instancias cada una donde cada clase se refiere a un tipo de planta de lirio.

Más información disponible en: http://archive.ics.uci.edu/ml/datasets/Iris

## ATRIBUTOS

	1. Longitud sépalo en cm
	2. Anchura sépalo en cm
	3. Longitud pétalo en cm
	4. Anchura pétalo en cm

	Clases:
		- Lirio Setosa
		- Lirio Versicolour
		- Lirio Virginica

## CÓMO FUNCIONA
Como cada instancia tiene 4 atributos y necesitamos datos bidimensionales, se han añadido dos selectores a la interfaz gráfica que permiten elegir los dos atributos que se utilizarán en la aplicación del algoritmo de K-medias.

Por lo tanto para ejecutar el modelo hay que cargar los datos del dataset mediante el botón CARGAR DATOS, seguidamente seleccionar el NÚMERO DE CLUSTERS, la TOLERANCIA del algoritmo y pulsar en CREAR CLUSTERS para generar clusters aleatorios. Por último, pulsar sobre el botón K-MEDIAS para ejecutar el algoritmo de clasificación.

## ARTÍCULOS RELACIONADOS CON EL DATASET

Fisher,R.A. "The use of multiple measurements in taxonomic problems" Annual Eugenics, 7, Part II, 179-188 (1936); also in "Contributions to Mathematical Statistics" (John Wiley, NY, 1950).

Duda,R.O., & Hart,P.E. (1973) Pattern Classification and Scene Analysis. (Q327.D83) John Wiley & Sons. ISBN 0-471-22361-1. See page 218.

Dasarathy, B.V. (1980) "Nosing Around the Neighborhood: A New System Structure and Classification Rule for Recognition in Partially Exposed Environments". IEEE Transactions on Pattern Analysis and Machine Intelligence, Vol. PAMI-2, No. 1, 67-71.

Gates, G.W. (1972) "The Reduced Nearest Neighbor Rule". IEEE Transactions on Information Theory, May 1972, 431-433.


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
Circle -2674135 true false 30 30 240

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

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
