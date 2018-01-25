breed[tanques tanque]
breed[disparos disparo]

tanques-own[pos-tanque]

disparos-own[

  pos-tanque ; posición del tanque que dispara: izq o der
  velocidad ; velocidad del disparo
  angulo ; ángulo de disparo
  max-altura ; máxima altura que alcanza el proyectil
  rango-total ; rango de disparo total del proyectil
  tiempo-total ; tiempo en alcanzar objetivo

  px1 py1 px2 py2 a ; variables que intervienen en la ecuación del movimiento de proyectiles
  da-en-pared? ; indica si el disparo da en la pared
  gastado? ; indica si el disparo ha sido gastado

  genoma ; genoma del disparo usado para el algoritmo genético
  fitness ; fitness del disparo usado en ambos algoritmos

  v ; vector de velocidad instantánea de la partícula
  personal-mejor-val   ; mejor valor que ha encontrado
  personal-mejor-velocidad     ; mejor valor de velocidad que ha encontrado
  personal-mejor-angulo     ; mejor valor de ángulo que ha encontrado
]

patches-own[pared]

globals[
  mutaciones-disparos ; lista de mutaciones de los disparos

  disparo-ganador-izq ; disparo ganador del tanque izquierdo
  disparo-ganador-der ; disparo ganador del tanque derecho

  borde-pared-superior ; patch del borde de la pared superior
  borde-pared-inferior ; patch del borde de la pared inferior

  global-mejor-val    ; mejor valor encontrado por el PS
  global-mejor-velocidad      ; coordenada x del mejor valor encontrado por el PS
  global-mejor-angulo      ; coordenada y del mejor valor encontrado por el PS

  tanque-ganador

]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SETUP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  ca
  set-default-shape tanques "tank"
  set-default-shape disparos "circle"


  ;; dibujar mundo
  ask patches with [pycor > 0] [ set pcolor 95]  ;; cielo
  ask patches with [pycor < 0 ] [set pcolor 53] ;; suelo
  ask patches with [pycor < pared-inferior and pycor > -50 and pxcor = 400 ] [set pcolor 10 set pared "inferior"] ;; pared inferior
  ask patches with [pycor > pared-superior and pycor <= max-pycor and pxcor = 400 ] [set pcolor 10 set pared "superior"] ;; pared superior

  set borde-pared-inferior one-of patches with [pared = "inferior"] with-max [pycor]
  if borde-pared-inferior = nobody [set borde-pared-inferior patch 400 0]
  set borde-pared-superior one-of patches with [pared = "superior"] with-min [pycor]
  if borde-pared-superior = nobody [set borde-pared-superior patch 400 450]

  ;; mutaciones de los disparos
  set mutaciones-disparos (list 2  1)

  ;; crear tanque izquierdo
  create-tanques 1[
    set size 50
    set color yellow
    setxy tank1x 0
    set pos-tanque "izq"
  ]

  ;; crear tanque derecho
  create-tanques 1[
    set size 50
    set color orange
    setxy tank2x 0
    set pos-tanque "der"
  ]

  ;; crear disparos y torreta del tanque izquierdo (GA)
  ask one-of tanques with [pos-tanque = "izq"][

    hatch-disparos Num-disparos[
      set size 2
      set color random-float 140
      set gastado? false
      set da-en-pared? false
      set velocidad 1 + random 150
      set angulo 1 + random 89
      set genoma (list velocidad angulo)
      ;; calcular fitness inicial del disparo
      calcular-fitness item 0 genoma item 1 genoma
    ]

    hatch 1[
      set shape "barrel"
      set size 40
      set heading 180 - 70
      setxy xcor + 7 15
    ]
  ]

  ;; crear disparos y torreta del tanque derecho (PSO)
  ask one-of tanques with [pos-tanque = "der"][
    hatch-disparos Num-disparos[
      set size 2
      set color random-float 140
      set gastado? false
      set da-en-pared? false
      set velocidad 1 + random 150
      set angulo 1 + random 89

      ;; proporcionar a las partículas velocidades iniciales (vx y vy) con una distribución normal
      set v (list (random-normal 0 1) (random-normal 0 1))

      ;: calcular valor inicial de la partícula
      calcular-fitness velocidad angulo

      ;; el punto de partida es la mejor localización actual de la partícula
      set personal-mejor-val fitness
      set personal-mejor-velocidad velocidad
      set personal-mejor-angulo angulo
    ]

    hatch 1[
      set shape "barrel"
      set size 40
      set heading 70
      setxy xcor - 7 15
    ]
  ]

  actualizar-visualizacion "izq"
  actualizar-visualizacion "der"

reset-ticks

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  ;; parar si se alcanza el número máximo de iteraciones definido en la interfaz gráfica
  if ticks > max-iteraciones [
    disparar-ganador disparo-ganador-izq
    disparar-ganador disparo-ganador-der
    stop
  ]

  ;; en caso de que los dos tanques hayan alcanzado sus objetivos, gana el que haya disparado más cerca
  if [fitness] of disparo-ganador-izq <= 5 and global-mejor-val <= 5[
    ifelse [fitness] of disparo-ganador-izq <= global-mejor-val [
      ;; gana izquierda (GA)
      watch disparo-ganador-izq
      disparar-ganador disparo-ganador-izq
      stop
    ]
    [
      ;;gana derecha (PSO)
      watch disparo-ganador-der
      disparar-ganador disparo-ganador-der
      stop
    ]
  ]

  if [fitness] of disparo-ganador-izq <= 5
  [
    watch disparo-ganador-izq
    disparar-ganador disparo-ganador-izq
    stop
  ]
  if global-mejor-val <= 5
  [
    watch disparo-ganador-der
    disparar-ganador disparo-ganador-der
    stop
  ]

  if mostrar-disparos? [
    disparar-ganador disparo-ganador-izq
    disparar-ganador disparo-ganador-der
  ]

  ;; ejecutar GA
  go-ga
  ;; ejecutar PSO
  go-pso

  tick

end

;; Función utilizada únicamente al lanzar experimento. Se diferencia de la anterior en que no para la ejecución del modelo.
to-report go-experimento

  let continuar? true

  if ticks > max-iteraciones [
    set tanque-ganador "ninguno"
    set continuar? false
  ]

  if [fitness] of disparo-ganador-izq <= 5 and global-mejor-val <= 5[
    ifelse [fitness] of disparo-ganador-izq <= global-mejor-val [
      ;; gana izquierda
      watch disparo-ganador-izq
      disparar-ganador disparo-ganador-izq
      set tanque-ganador "ga"
      set continuar? false
    ]
    [
      ;;gana derecha
      watch disparo-ganador-der
      disparar-ganador disparo-ganador-der
      set tanque-ganador "pso"
      set continuar? false
    ]
  ]

  if [fitness] of disparo-ganador-izq <= 5
  [
    watch disparo-ganador-izq
    disparar-ganador disparo-ganador-izq
    set tanque-ganador "ga"
    set continuar? false
  ]
  if global-mejor-val <= 5
  [
    watch disparo-ganador-der
    disparar-ganador disparo-ganador-der
    set tanque-ganador "pso"
    set continuar? false
  ]

  if mostrar-disparos? [
    disparar-ganador disparo-ganador-izq
    disparar-ganador disparo-ganador-der
  ]

  go-ga
  go-pso

  tick
  report continuar?

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MOVIMIENTO PROYECTIL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Dispara el proyectil ganador al tanque opuesto
to disparar-ganador [disparo-ganador]
  ask disparo-ganador[
    pd
    while [ycor >= 0 and xcor < max-pxcor and not da-en-pared?]
      [
        if((xcor = 400 and ycor <= pared-inferior) or (xcor = 400 and ycor >= pared-superior) )[
          set da-en-pared? true
        ]
        mueve-proyectil
        setxy xcor ycor
      ]
    set gastado? true
  ]
end

;; Calcula ecuación de la trayectoria del proyectil
to calcula-trayectoria-disparo
  set max-altura velocidad ^ 2 * (.5 - .5 * cos(2 * angulo)) / 19.6
  set rango-total velocidad ^ 2 * sin(2 * angulo) / 9.8
  set tiempo-total (2 * velocidad * sin(angulo)) / 9.8
  set px1 xcor
  set py1 ycor
  ifelse pos-tanque = "izq"
    [set px2 rango-total / 2 + px1]
    [set px2 px1 - (rango-total / 2)]
  set py2 max-altura
  set a (py1 - py2) / ((px1 - px2) ^ 2)
end

;; Calcula la altura que tiene el proyectil en la posición de las paredes
to-report calcula-altura-proyectil-en-pared
  report a * (400 - px2) ^ 2 + py2
end

;; Mueve el proyectil por el mundo
to mueve-proyectil
  ifelse pos-tanque = "izq"
  [set xcor xcor + 1]
  [set xcor xcor - 1]
  set ycor a * (xcor - px2) ^ 2 + py2
  blanco-acertado?
end

;; Determinar si el blanco (tanque contrario) ha sido acertado con el disparo
to blanco-acertado?
  ifelse pos-tanque = "izq"
  [
    let tanque-opuesto one-of tanques with [pos-tanque = "der"]
    if ((xcor - [xcor] of tanque-opuesto) > -5 and (xcor - [xcor] of tanque-opuesto) < 5) and (ycor < 2)[
      ask tanque-opuesto [set shape "tankhit"]
    ]
  ]
  [
    let tanque-opuesto one-of tanques with [pos-tanque = "izq"]
    if ((xcor - [xcor] of tanque-opuesto) < 5 and (xcor - [xcor] of tanque-opuesto) > -5) and (ycor < 2)[
      ask tanque-opuesto [set shape "tankhit"]
    ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go-ga
  crear-siguiente-generacion-disparos "izq"
  actualizar-visualizacion "izq"
end

;; Función de crossover del GA
to crear-siguiente-generacion-disparos [pos]
  ; Hacemos una copia de las tortugas que hay en este momento.
  let generacion-anterior disparos with [pos-tanque = pos]

  ; Algunas de las soluciones actuales se conseguirá por medio del cruzamiento,
  ; Se divide entre 2 porque en cada paso del bucle se generan 2 nuevas soluciones.
  let numero-cruzamientos  (floor (Num-disparos * razon-cruzamiento / 100 / 2))

  repeat numero-cruzamientos
  [
    ; Se ha usado una selección por torneo, con un tamaño de 3 elementos.
    ; Es decir, se toman aleatoriamente 3 soluciones de la generación previa
    ; y nos quedamos con el mejor de esos 3 para la reproducción.

    let padre1 min-one-of (n-of 3 generacion-anterior) [fitness]
    let padre2 min-one-of (n-of 3 generacion-anterior) [fitness]

    let genes-hijo cruzamiento ([genoma] of padre1) ([genoma] of padre2)

    ; crea 2 hijos con sus informaciones genéticas
    ask padre1 [ hatch 1 [ set genoma item 0 genes-hijo ] ]
    ask padre2 [ hatch 1 [ set genoma item 1 genes-hijo ] ]
  ]

  ; el resto de la población se crea por clonación directa
  ; de algunos miembros seleccionados de la generación anterior
  repeat (Num-disparos - numero-cruzamientos * 2)
  [
    ask min-one-of (n-of 3 generacion-anterior) [fitness]
      [ hatch 1 ]
  ]

  ; Eliminamos toda la generación anterior
  ask generacion-anterior [ die ]


  ; y sobre el resto de tortugas (generación recién generada)...
  ask disparos with [pos-tanque = pos]
  [
    ; realizamos la mutación (es un proceso probabilístico)
    mutar-disparo
    ; y actualizamos su valor de fitness
    calcular-fitness item 0 genoma item 1 genoma
  ]

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

;; Mutar los valores de velocidad y ángulo del disparo
to mutar-disparo   ;; procedimiento de tortuga
  let i 0
  let temp 0
  while [i < length genoma][
    if random-float 100.0 < razon-mutacion
    [
      ifelse ((random 2) = 0 )
      [set temp item i genoma + item i mutaciones-disparos ]
      [set temp item i genoma - item i mutaciones-disparos ]
      if (temp <= 0) [set temp item i mutaciones-disparos ]
      set genoma replace-item i genoma temp
      set i i + 1
    ]
  ]
  if item 0 genoma > 150 [set genoma replace-item 0 genoma 150]
  set velocidad item 0 genoma
  if item 1 genoma > 89 [set genoma replace-item 1 genoma 89]
  set angulo item 1 genoma
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FUNCIONES COMUNES ALGORITMOS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Calcula el valor de fitness de un disparo. Para calcular este valor se distinguen tres zonas: el disparo no llega a la pared, el disparo golpea la pared, el disparo pasa entre las paredes.
;; Si el disparo sale del mundo o no llega a la pared, su valor de fitness es máximo (8000).
;; Si el disparo se choca en la pared, se divide el valor máximo entre 2 y se le suma la distancia al borde de la pared en la que haya chocado el proyectil.
;; Si el disparo sobrepasa la pared, se calcula la distancia del proyectil al objetivo (tanque lado opuesto).
;; El objetivo será minimizar el valor de fitness.
to calcular-fitness  [vel ang]     ;; procedimiento de tortuga
  set velocidad vel
  set angulo ang
  calcula-trayectoria-disparo
  ;; Distancia máxima
  let distancia 8000
  if max-altura <= max-pycor and ((pos-tanque = "der" and xcor - rango-total > min-pxcor) or (pos-tanque = "izq" and xcor + rango-total < max-pxcor)) [
    let altura-en-pared calcula-altura-proyectil-en-pared
    let llega-a-pared? false
    let golpea-pared? altura-en-pared <= pared-inferior or altura-en-pared >= pared-superior
    if altura-en-pared > 0 [set llega-a-pared? true]
    if llega-a-pared? and golpea-pared? [
      if altura-en-pared <= pared-inferior
      [
        ask borde-pared-inferior[
          set distancia distancia / 2 + distancexy 400 altura-en-pared
        ]
      ]
      if altura-en-pared >= pared-superior
      [
        ask borde-pared-superior[
          set distancia distancia / 2 + distancexy 400 altura-en-pared
        ]
      ]
    ]

    if llega-a-pared? and not golpea-pared? [
      ifelse pos-tanque = "izq"
      [
        ask one-of tanques with [pos-tanque = "der"][
          set distancia distancexy ([xcor] of myself + [rango-total] of myself) 0
        ]
      ]
      [
        ask one-of tanques with [pos-tanque = "izq"][
          set distancia distancexy ([xcor] of myself - [rango-total] of myself) 0
        ]
      ]
    ]
  ]

  set fitness distancia
end

;; Actualizar los disparos ganadores
to actualizar-visualizacion [pos]
  ifelse pos = "izq"
  [
    set disparo-ganador-izq min-one-of disparos with [pos-tanque = pos] [fitness]
  ]
  [
    set disparo-ganador-der min-one-of disparos with [pos-tanque = pos] [personal-mejor-val]
    set global-mejor-val [personal-mejor-val] of disparo-ganador-der
    set global-mejor-velocidad [personal-mejor-velocidad] of disparo-ganador-der
    set global-mejor-angulo [personal-mejor-angulo] of disparo-ganador-der
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PSO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Procdimiento principal del agoritmo de optimización PSO
to go-pso

    ; Calculamos el valor asociado a cada partícula
    ask disparos with [pos-tanque = "der"][

      calcular-fitness velocidad angulo
      let val fitness


      ; actualizar el "mejor valor personal" para cada partícula,
      ; si han encontrado un valor mejor que el que tenían almacenado
      if val < personal-mejor-val
      [
        set personal-mejor-val val
        set personal-mejor-velocidad velocidad
        set personal-mejor-angulo angulo
      ]

      if personal-mejor-val < global-mejor-val
      [
        set global-mejor-val personal-mejor-val
        set global-mejor-velocidad personal-mejor-velocidad
        set global-mejor-angulo personal-mejor-angulo
        set disparo-ganador-der self
      ]
    ]


  ; Se actualiza la posición/velocidad de cada partícula
  ask disparos with [pos-tanque = "der"]
  [
    ;; Actualizar velocidad
    set v *v inercia-particula v

    let diff-personal -v (list personal-mejor-velocidad personal-mejor-angulo) (list velocidad angulo)
    let diff-global -v (list global-mejor-velocidad global-mejor-angulo) (list velocidad angulo)
    set v +v v (+v (*v ((1 - inercia-particula) * atraccion-a-mejor-personal * (random-float 1.0)) diff-personal)
       (*v ((1 - inercia-particula) * atraccion-al-global-mejor * (random-float 1.0)) diff-global))

      if (norma v) ^ 2 > lim-vel-particulas ^ 2
      [ set v *v (lim-vel-particulas / norma v) v ]

      ;; Actualizar posición
      let nueva-posicion +v v (list velocidad angulo)
      if any? disparos with [pos-tanque = "der"
        and velocidad = first v
        and angulo = last v]
      [
        set v *v -1 v
        set nueva-posicion +v v (list velocidad angulo)
      ]
      set velocidad first nueva-posicion
      set angulo last nueva-posicion
  ]

  actualizar-visualizacion "der"
end

; Conjunto de funciones auxiliares (las vectoriales, permiten trabajar con más de 2 variables)

; Producto por escalar: k * (v1,v2,...,vn) = (k*v1, k*v2, ..., k*vn)
to-report *v [lambda v1]
  report map [lambda * ?] v1
end

; Suma de vetores: (u1, u2, ..., un) + (v1, v2, ..., vn) = (u1+v1, u2+v2, ..., un+vn)
to-report +v [v1 v2]
  report (map [?1 + ?2] v1 v2)
end

; Función Signo
to-report sg [x]
  report ifelse-value (x >= 0) [1][-1]
end

; Norma de un vector: Sqrt (v1^2 + v2^2 +...+ vn^2)
to-report norma [v1]
  report sqrt sum map [? * ?] v1
end

to-report -v [v1 v2]
  report (map [?1 - ?2] v1 v2)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; EXPERIMENTO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to experimento
  let num-experimento 0
  let i 0
  set num-disparos 5
  while [num-experimento < 25][
    set i 0
    while [i < 5][
      setup
      while [go-experimento][]
      graba-resultado-experimento num-experimento
      set i i + 1
    ]
    set num-disparos num-disparos + 5
    set num-experimento num-experimento + 1
  ]
end


to graba-resultado-experimento [num-experimento]
  file-open "resultados.txt"
  ;; num-experimento ; num-disparos ; num-iteraciones ; ganador ; ...
  ;; ... mejor-fitness-ga ; mejor-velocidad-ga ; mejor-angulo-ga ; ...
  ;; ... mejor-fitness-pso ; mejor-velocidad-pso ; mejor-angulo-pso
  file-print (word num-experimento ";" num-disparos ";" ticks ";" tanque-ganador ";"
    [fitness] of disparo-ganador-izq ";" [velocidad] of disparo-ganador-izq ";" [angulo] of disparo-ganador-izq ";"
    global-mejor-val ";" global-mejor-velocidad ";" global-mejor-angulo)

  file-close-all
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1021
542
-1
-1
1.0
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
800
-50
450
1
1
1
ticks
30.0

SLIDER
240
545
490
578
tank1x
tank1x
0
200
149
1
1
NIL
HORIZONTAL

SLIDER
745
545
995
578
tank2x
tank2x
max-pxcor - 200
max-pxcor
685
1
1
NIL
HORIZONTAL

BUTTON
10
430
105
463
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

MONITOR
222
44
358
89
Máxima altura
[max-altura] of disparo-ganador-izq
2
1
11

MONITOR
223
98
357
143
Rango total
[rango-total] of disparo-ganador-izq
2
1
11

MONITOR
223
153
359
198
Tiempo total
[tiempo-total] of disparo-ganador-izq
2
1
11

TEXTBOX
245
510
320
528
Tanque GA
15
9.9
1

TEXTBOX
917
507
1002
525
Tanque PSO
15
9.9
1

MONITOR
877
44
1009
89
Máxima altura
[max-altura] of disparo-ganador-der
2
1
11

MONITOR
878
97
1008
142
Rango total
[rango-total] of disparo-ganador-der
2
1
11

MONITOR
879
150
1011
195
Tiempo total
[tiempo-total] of disparo-ganador-der
2
1
11

SLIDER
10
35
195
68
num-disparos
num-disparos
0
1000
30
10
1
NIL
HORIZONTAL

BUTTON
100
430
195
463
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

SLIDER
10
210
195
243
razon-mutacion
razon-mutacion
0
10
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
10
175
195
208
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
510
10
682
43
pared-superior
pared-superior
max-pycor - (max-pycor - pared-inferior - 50)
max-pycor
358
1
1
NIL
HORIZONTAL

SLIDER
520
510
692
543
pared-inferior
pared-inferior
0
(pared-superior - 50)
308
1
1
NIL
HORIZONTAL

MONITOR
225
205
360
250
Mejor distancia objetivo
[fitness] of disparo-ganador-izq
17
1
11

MONITOR
877
205
1012
250
Mejor distancia objetivo
global-mejor-val
17
1
11

SLIDER
10
275
195
308
inercia-particula
inercia-particula
0
1
0.41
0.01
1
NIL
HORIZONTAL

SLIDER
10
310
195
343
lim-vel-particulas
lim-vel-particulas
1
20
3
1
1
NIL
HORIZONTAL

SLIDER
10
345
195
378
atraccion-a-mejor-personal
atraccion-a-mejor-personal
0
2
0.4
0.1
1
NIL
HORIZONTAL

SLIDER
10
380
195
413
atraccion-al-global-mejor
atraccion-al-global-mejor
0
2
0.8
0.1
1
NIL
HORIZONTAL

SLIDER
10
70
195
103
max-iteraciones
max-iteraciones
0
2000
500
5
1
NIL
HORIZONTAL

SWITCH
10
105
195
138
mostrar-disparos?
mostrar-disparos?
1
1
-1000

BUTTON
30
500
177
533
Ejecutar experimento
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

TEXTBOX
40
150
170
170
Algoritmo Genético
15
0.0
1

TEXTBOX
55
255
150
273
Algoritmo PSO
15
0.0
1

TEXTBOX
35
10
185
30
Configuración general
15
0.0
1

TEXTBOX
55
475
160
493
--------------------
15
0.0
1

@#$#@#$#@
# GUERRA MUNDIAL DE OPTIMIZACIÓN

## QUÉ ES

Modelo que simula una batalla entre dos tanques, separados ambos por una pared central. El objetivo de cada uno de los tanques es destruir al opuesto intentando que los disparos sobrepasen la pared central.

El tanque de la izquierda utiliza un algoritmo genético para optimizar la función de la trayectoría de sus disparos. En el lado opuesto, el tanque derecho utiliza un algoritmo PSO para la optimización de sus proyectiles.

El objetivo del modelo es observar cuál gana más veces siendo el número de población inicial (número de disparos) de ambos algoritmos el mismo.

## CÓMO FUNCIONA

Los tanques tienen que optimizar los parámetros de **velocidad** y **ángulo** que intervienen en la función de movimiento de proyectiles (movimiento parabólico) para que sus disparos destruyan el tanque contrario. La función del movimiento parabólico es la siguiente:

![Movimiento parabólico](http://recursostic.educacion.es/descartes/web/materiales_didacticos/comp_movimientos/images/Image5.gif)

El rango o alcance total viene determinado por:

![Movimiento parabólico - Rango total](http://recursostic.educacion.es/descartes/web/materiales_didacticos/comp_movimientos/images/Image1879.gif)

La altura máxima del disparo se puede obtener mediante la siguiente función:

![Movimiento parabólico - Rango total](http://recursostic.educacion.es/descartes/web/materiales_didacticos/comp_movimientos/images/Image1880.gif)

El tanque de la izquierda optimizará la velocidad y el ángulo de sus disparos utilizando un algoritmo genético que se puede configurar mediante los distintos deslizadores de la interfaz gráfica.

Por otro lado, el tanque derecho optimizará los parámetros de velocidad y ángulo utilizando un algoritmo de optimización por enjambre de partículas (PSO).

Ambos algoritmos utilizan la misma función de fitness. El objetivo es minimizar la distancia que hay entre el tanque oponente y el proyectil disparado. Para calcular el valor de fitness de un disparo se han distinguido tres casos:

1. El disparo se queda entre el tanque y la pared.
2. El disparo golpea la pared y no sigue su trayectoria.
3. El disparo pasa entre las paredes y podría alcanzar al tanque objetivo.

Los valores de fitness que se pueden tomar son los siguientes:

1. Si el disparo sale del mundo o no llega a la pared, su valor de fitness es máximo (8000).
2. Si el disparo golpea la pared, se divide el valor máximo entre 2 y se le suma la distancia al borde de la pared en la que haya chocado el proyectil.
3. Si el disparo sobrepasa la pared, se calcula la distancia del proyectil al objetivo (tanque lado opuesto).

Con esta casuística, los disparos que sobrepasen la pared y no se salgan del mundo serán los que tengan mejores valores de fitness.


## CÓMO SE USA

El slider MAX-ITERACIONES sirve para controlar el número máximo de iteraciones que realizarán los algoritmos.

El slider NUM-DISPAROS controla la población inicial de ambos algoritmos.

El switch MOSTRAR-DISPAROS? muestra los mejores disparos de ambos tanques en cada paso iteración de los algoritmos.

El slider TANK1X controla la posición del tanque de la izquierda.

El slider TANK2X controla la posición del tanque de la derecha.

El slider PARED-INFERIOR controla la posición de la pared inferior.

El slider PARED-SUPERIOR controla la posición de la pared superior.

Pulsa SETUP para dibujar el mundo y crear la población de disparos.

Pulsa GO para aplicar los algoritmos hasta que uno de los tanques alcance al contrario.

Pulsa EJECUTAR EXPERIMENTO para ejecutar distintas configuraciones del modelo automáticamente y generar un archivo de texto con los resultados obtenidos.


### CONFIGURACIÓN ALGORITMO GENÉTICO

La RAZON-CRUZAMIENTO controla el porcentaje de individuos de la nueva generación que serán creados por medio de reproducción sexual (usando 2 padres) y el porcentaje que lo hará por medio de reproducción asexual (clonación directa).

La RAZON-MUTACION controla el porcentaje de cambio por mutación. Esta cantidad se aplica a cada posición de cada cadena de los nuevos individuos.

### CONFIGURACIÓN PSO

El slider ATRACCION-A-MEJOR-PERSONAL determina la fuerza de atracción de cada partícula al punto que ella ha encontrado como el mejor de su historia, mientras que el slider ATRACCION-AL-GLOBAL-MEJOR determina la fuerza de atracción de cada partícula a la mejor localización descubierta por cualquier miembro del enjambre.

El slider INERCIA-PARTICULA controla la inercia que tiene cada partícula a seguir moviéndose en la dirección que va (normalmente, opuesta a las fuerzas de atracción causadas por las mejores localizaciones).

El slider LIMITE-VELOCIDAD-PARTICULA controla la máxima velocidad a la que puede moverse una partícula (e cualquiera de las direcciones).

## RESULTADOS EXPERIMENTO
Los datos del resultado se pueden consultar tanto en el archivo _resultados.txt_ como en el Excel adjunto al proyecto.

Se han efectuado 25 experimentos en los que se ha ido variando la población inicial de los algoritmos. Cada uno de estos experimentos, se ha ejecutado 5 veces (para evitar empates) y en ellos se determina qué algoritmo es el que gana.

Los resultados obtenidos son los siguientes:

- En 10 ocasiones ninguno de los tanques fue capaz de destruir al oponente. En 9 de ellas la población inicial era menor o igual a 15, por lo que la población inicial es un factor decisivo en este tipo de algoritmos.
- El algoritmo genético ganó 55 veces.
- El algoritmo PSO ganó 60 veces.

Como conclusión, ambos algoritmos han obtenido un número de victorias similar, por lo que se podría utilizar cualquiera de ellos indistíntamente en la resolución de problemas de optimización análogos al presentado en este modelo.


## REFERENCIAS
- http://ccl.northwestern.edu/netlogo/models/community/physics-projectile-motion
- http://recursostic.educacion.es/descartes/web/materiales_didacticos/comp_movimientos/parabolico.htm


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

barrel
true
0
Rectangle -16777216 true false 105 135 195 165

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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
false
0
Rectangle -7500403 true true 45 105 255 195
Rectangle -7500403 true true 105 60 195 105
Rectangle -7500403 true true 30 105 45 150
Rectangle -7500403 true true 15 105 30 150
Rectangle -7500403 true true 255 105 270 150
Rectangle -7500403 true true 270 105 285 150
Rectangle -7500403 true true 30 150 45 165
Rectangle -7500403 true true 30 165 45 180
Rectangle -7500403 true true 15 150 30 165
Rectangle -7500403 true true 0 135 15 150
Rectangle -7500403 true true 0 120 15 135
Rectangle -7500403 true true 285 120 300 135
Rectangle -7500403 true true 285 135 300 150
Rectangle -7500403 true true 270 150 285 165
Rectangle -7500403 true true 255 165 270 180
Rectangle -7500403 true true 255 150 270 165
Circle -16777216 true false 45 150 30
Circle -16777216 true false 90 150 30
Circle -16777216 true false 135 150 30
Circle -16777216 true false 180 150 30
Circle -16777216 true false 225 150 30
Circle -16777216 true false 15 120 30
Circle -16777216 true false 255 120 30

tankhit
false
0
Rectangle -7500403 true true 45 105 255 195
Rectangle -7500403 true true 105 60 195 105
Rectangle -7500403 true true 30 105 45 150
Rectangle -7500403 true true 15 105 30 150
Rectangle -7500403 true true 255 105 270 150
Rectangle -7500403 true true 270 105 285 150
Rectangle -7500403 true true 30 150 45 165
Rectangle -7500403 true true 30 165 45 180
Rectangle -7500403 true true 15 150 30 165
Rectangle -7500403 true true 0 135 15 150
Rectangle -7500403 true true 0 120 15 135
Rectangle -7500403 true true 285 120 300 135
Rectangle -7500403 true true 285 135 300 150
Rectangle -7500403 true true 270 150 285 165
Rectangle -7500403 true true 255 165 270 180
Rectangle -7500403 true true 255 150 270 165
Circle -16777216 true false 45 150 30
Circle -16777216 true false 90 150 30
Circle -16777216 true false 135 150 30
Circle -16777216 true false 180 150 30
Circle -16777216 true false 225 150 30
Circle -16777216 true false 15 120 30
Circle -16777216 true false 255 120 30
Rectangle -1184463 true false 45 45 240 195
Rectangle -2674135 true false 30 45 60 105
Rectangle -2674135 true false 165 15 195 75
Rectangle -2674135 true false 225 30 255 120
Rectangle -2674135 true false 135 135 165 195
Rectangle -2674135 true false 60 120 105 195
Rectangle -955883 true false 210 165 255 195
Rectangle -955883 true false 120 120 150 135
Rectangle -955883 true false 30 30 45 60
Rectangle -955883 true false 165 0 180 30
Rectangle -955883 true false 240 15 255 45
Rectangle -955883 true false 75 90 90 135
Rectangle -955883 true false 240 75 270 105
Rectangle -2674135 true false 90 15 120 75
Rectangle -955883 true false 105 0 120 30

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

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
