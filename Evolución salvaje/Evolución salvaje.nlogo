;;-------;;
;; Razas ;;
;;-------;;


breed [gacelas gacela]
breed [leones leon]
breed [humanos humano]

;;--------------------;;
;; Variables globales ;;
;;--------------------;;

globals[
  mutaciones-gacelas
  mutaciones-leones
  mutaciones-humanos

  inanicion-leones
  inanicion-gacelas
  inanicion-humanos

  gacelas-cazadas
  humanos-cazados
  leones-cazados

  combates-ganados-gacelas
  combates-ganados-leones
  combates-ganados-humanos

  max-ganados-gacelas
  max-ganados-leones
  max-ganados-humanos
]

;;---------------------------;;
;; Propiedades comúnes razas ;;
;;---------------------------;;

turtles-own [
  Sexo                      ;; macho o hembra
  Edad                      ;; la edad no interviene en la longevidad de los individuos
  Energia-nacimiento
  Energia
  Energia-por-comer
  Energia-arranque
  Velocidad
  Aceleracion
  Angulo-Giro
  Campo-vision
  Distancia-vision
  Aguante
  Inteligencia
  Genoma
  Combates-ganados          ;; número de combates ganados
  Puede-reproducirse?       ;; indica si puede reproducirse o no
]

;;---------------------------------;;
;; Propiedades específicas gacelas ;;
;;---------------------------------;;

gacelas-own [
  Angulo-evitar
  Angulo-escape
  Rango-seguridad
  Agilidad
  Destreza
]

;;--------------------------------;;
;; Propiedades específicas leones ;;
;;--------------------------------;;

leones-own [
  Sigilo
  Destreza
]

;;---------------------------------;;
;; Propiedades específicas humanos ;;
;;---------------------------------;;

humanos-own[
  Distancia-ataque
  Punteria
  Arma
]

;;----------------------------;;
;; Propiedades extras patches ;;
;;----------------------------;;

patches-own [temporizador]

;;-------;;
;; Setup ;;
;;-------;;

to setup
  ca
  ;; Listado de mutaciones por raza
  set mutaciones-gacelas (list 0.1  0.05 5 0.5 0.1  0.05 0.1 1   1   1 0.2 0.1 0.2)
  set mutaciones-leones  (list 0.05 0.1  5 0.5 0.05 0.1  0.2 0.2 0.5)
  set mutaciones-humanos (list 0.02 0.02 5 0.5 0.2  1    0.5 0.2 0.5 0.1)

  ;; Crear terreno
  ask patches [
    set pcolor one-of [green brown]
    ifelse pcolor = green
      [ set temporizador tiempo-crec-vegetacion ]
      [ set temporizador random tiempo-crec-vegetacion ]
  ]

  ;; Crear gacelas
  repeat poblacion-gacelas [crear-gacela]
  ;; Crear leones
  repeat poblacion-leones [crear-leon]
  ;; Crear humanos
  repeat poblacion-humanos [crear-humano]

  reset-ticks
end

;;----;;
;; Go ;;
;;----;;

to go
  ;; Para la ejecución cuando no quede ninguna raza viva
  if not any? turtles [ stop ]

  ;; Ejecutar acciones de las gacelas
  ask gacelas [
    mover-gacela
    alimentar-gacela
    set Edad Edad + 1
    morir
    reproducir-gacela
  ]
  ask gacelas [set Puede-reproducirse? true]

  ;; Ejecutar acciones de los leones
  ask leones [
    mover-leon
    set Edad Edad + 1
    morir
    reproducir-leon
  ]
  ask leones [set Puede-reproducirse? true]

  ;; Ejecutar acciones de los humanos
  ask humanos [
    mover-humano
    ;; Si la energía es baja existe la probabilidad de alimentar al humano con vegetación
    if (Energia < Energia-nacimiento / 2  and random-float 100 < 50)
    [alimentar-humano-vegetacion]
    set Edad Edad + 1
    morir
    reproducir-humano
  ]
  ask humanos [set Puede-reproducirse? true]

  ;; Hacer crecer la vegetación del entorno
  crecer-vegetacion

  tick

end

;;--------------;;
;; Crear gacela ;;
;;--------------;;

to crear-gacela
  create-gacelas 1 [
    setxy random-xcor random-ycor
    set shape "gacela"
    set color orange
    set size 2
    set Sexo one-of ["hembra" "macho"]
    set Edad random 3
    set Puede-reproducirse? true
    set Energia-por-comer gacela-energia-por-comer
    set Energia-arranque 0.2
    set Energia-nacimiento random (2 * Energia-por-comer)
    set Energia Energia-nacimiento
    set Velocidad random-float 1.5
    set Aceleracion 1 + random-float 1
    set Campo-vision random-float 130
    set Distancia-vision 2 + random-float 10
    set Rango-seguridad random-float 2
    set Angulo-giro random-float 30
    set Angulo-evitar random-float 30
    set Angulo-escape random-float 30
    set Aguante 1 + random-float 1
    set Inteligencia 1 + random-float 1
    set Agilidad 1 + random-float 5
    set Destreza 1 + random-float 5
    set Genoma (list Velocidad Aceleracion Campo-vision Distancia-vision Aguante Inteligencia
      Rango-seguridad Angulo-giro Angulo-evitar Angulo-escape Agilidad Energia-por-comer Destreza)

  ]
end

;;------------;;
;; Crear león ;;
;;------------;;

to crear-leon
  create-leones 1 [
    setxy random-xcor random-ycor
    set shape "leon"
    set color brown + 2
    set size 2
    set Sexo one-of ["hembra" "macho"]
    set Edad random 3
    set Puede-reproducirse? true
    set Energia-por-comer leon-energia-por-comer
    set Energia-arranque 0.2
    set Energia-nacimiento random (2 * Energia-por-comer)
    set Energia Energia-nacimiento
    set Velocidad random-float 1
    set Aceleracion 1 + random-float 1.5
    set Angulo-giro random-float 30
    set Campo-vision random-float 180
    set Distancia-vision 2 + random-float 20
    set Aguante 1 + random-float 1
    set Inteligencia 1 + random-float 2
    set Sigilo 1 + random-float 5
    set Destreza 1 + random-float 5
    set Genoma (list Velocidad Aceleracion Campo-vision Distancia-vision Aguante Inteligencia ;; genes comunes
      Sigilo Destreza Energia-por-comer) ;; genes propios
  ]
end

;;--------------;;
;; Crear humano ;;
;;--------------;;

to crear-humano
  create-humanos 1 [
    setxy random-xcor random-ycor
    set shape "person"
    set color blue
    set size 2
    set Sexo one-of ["hembra" "macho"]
    set Edad random 3
    set Puede-reproducirse? true
    set Energia-por-comer humano-energia-por-comer
    set Energia-arranque 0.2
    set Energia-nacimiento random (2 * Energia-por-comer)
    set Energia Energia-nacimiento
    set Velocidad random-float 0.5
    set Aceleracion 1 + random-float 0.5
    set Angulo-giro random-float 180
    set Campo-vision random-float 180
    set Distancia-vision 2 + random-float 20
    set Aguante 1 + random-float 1
    set Inteligencia 1 + random-float 5
    set Distancia-ataque 1 + random-float 2
    set Punteria 1 + random-float 5
    set Arma 1 + random-float 5
    set Genoma (list Velocidad Aceleracion Campo-vision Distancia-vision Aguante Inteligencia ;; genes comunes
      Distancia-ataque Punteria Arma Energia-por-comer) ;; genes propios
  ]
end

;;-------;;
;; Mover ;;
;;-------;;

;; Procedimiento de gacelas, leones y humanos que determina el movimiento aleatorio cuando no hay
;; predadores/presas en las cercanías.
to mover
  rt random Angulo-giro
  lt random Angulo-giro
  ;; Permite a gacelas, leones y humanos realizar arranques de velocidad
  ifelse random 10 = 0
    [
      fd Aceleracion
      set Energia Energia - Aceleracion * Energia-Arranque
    ]
    [
      fd Velocidad
      set Energia Energia - Velocidad * Energia-Arranque
    ]
end

;;--------------;;
;; Mover gacela ;;
;;--------------;;

;; Procedimiento para gobernar las gacelas y la pérdida de energía
to mover-gacela
  set Energia Energia - 1
  ;; Buscar predadores cercanos
  let peligros-leones leones in-cone Distancia-vision Campo-vision
  let peligros-humanos humanos in-cone Distancia-vision Campo-vision
  let peligros turtle-set (list peligros-leones peligros-humanos)
  ifelse (any? peligros)
    [ ;; Si hay predadores cerca, huir en otra dirección
      evita (min-one-of peligros [distance myself]) Angulo-Escape
      fd Velocidad
      set Energia Energia - Aceleracion * Energia-Arranque
    ]
    ;; Sino, mover la manada
    [ mover-manada-gacelas ]
end

;;-------------------------;;
;; Mover manada de gacelas ;;
;;-------------------------;;

;; Procedimiento que gobierna el comportamiento de la manada de gacelas
to mover-manada-gacelas
  ;; manada-gacelas son las gacelas que puede ver
  let manada-gacelas gacelas in-cone Distancia-vision Campo-vision with [(self != myself) ]
  ifelse any? manada-gacelas
    [let mas-cercano min-one-of manada-gacelas [distance myself]
      ifelse distance mas-cercano  < Rango-seguridad
      ;; Si el más cercano está demasiado cerca, lo evita
        [ evita mas-cercano Angulo-evitar ]
      ;; Si no está tan cerca, se gira a cada uno de los compañeros, por turno, un ángulo que
      ;; decrece exponencialmente con la distancia, para que afecten más los más cercanos.
      ;; Posteriormente, se intentan alinear con ellos de nuevo.
        [ foreach sort manada-gacelas [
          let angulo-giro-ajustado Angulo-giro * exp( ((distance mas-cercano) - (distance ?) ) )
          aproxima ? angulo-giro-ajustado
          alinea ? angulo-giro-ajustado ]
        ]
      mover
    ]
    [mover]
end

;;------------------;;
;; Alimentar gacela ;;
;;------------------;;

to alimentar-gacela
  ;; La gacela se come la vegetación del patch y lo pone marrón
  if pcolor = green[
    set pcolor brown
    set Energia Energia + Energia-por-comer
  ]
end

;;-------------------;;
;; Reproducir gacela ;;
;;-------------------;;

to reproducir-gacela
  ;; Si la gacela cumple la probabilidad, puede reproducirse en la generación actual y tiene energía suficiente...
  if random-float 100 < %reproduccion-gacelas and Puede-reproducirse? and Energia > 2 * Energia-nacimiento
  [
    ;; Marcarla como primer padre
    let padre1 self
    let padre2 nobody
    ;; Buscar segundo padre. Tiene que ser del sexo opuesto y no haberse reproducido en la generación actual
    ;; La selección se realiza por torneo de 3 y valor a maximizar (fitness) es Combates-ganados / Edad + 1
    let #gacelas-sexo-opuesto count gacelas with [Sexo != [Sexo] of padre1 and Puede-reproducirse? ]
    ifelse #gacelas-sexo-opuesto >= 3
      [
        set padre2 max-one-of (n-of 3 gacelas with [Sexo != [Sexo] of padre1 and Puede-reproducirse?]) [Combates-ganados / (Edad + 1)]
      ]
      [
        if #gacelas-sexo-opuesto > 0 [
          set padre2 max-one-of (n-of #gacelas-sexo-opuesto gacelas with [Sexo != [Sexo] of padre1 and Puede-reproducirse?]) [Combates-ganados / (Edad + 1)]
        ]
      ]

    ;; Si ha encontrado alguien con quien aparearse
    if padre2 != nobody[

      ;; Cruzar los genes de los dos padres (cross over)
      let genes-hijo cruzamiento ([Genoma] of padre1) ([Genoma] of padre2)

      ;; Quitar energía a los padres y comunicarles que no se pueden reproducir mas veces en la generación actual
      set Energia Energia - Energia-nacimiento
      set Puede-reproducirse? false
      ask padre2 [
        ifelse Energia > 2 * Energia-nacimiento
        [set Energia Energia - Energia-nacimiento]
        [set Energia Energia / 2]
        set Puede-reproducirse? false
      ]
      ;; Crear hijo con los uno de los dos genomas generados anteriormente
      ;; Se intenta que haya el mismo número de individuos de cada sexo
      hatch 1 [
        rt random-float 360
        set Energia Energia-nacimiento
        set Edad 0
        set Combates-ganados 0
        set Puede-reproducirse? true
        set Genoma item one-of [0 1] genes-hijo
        set Sexo ifelse-value (count gacelas with [Sexo = "hembra"] >= count gacelas with [Sexo = "macho"])["macho"]["hembra"]
        if random-float 100 < %mutacion-gacelas [mutar-gacela]
        fd Velocidad
      ]
    ]
  ]
end

;;--------------;;
;; Mutar gacela ;;
;;--------------;;

;; Modifica los genes aplicando la mutación y cuidando los límites de cada parámetro.
to mutar-gacela
  let i 0
  let temp 0
  while [i < ( length Genoma ) ][
    ifelse ((random 2) = 0 )
      [set temp item i Genoma + item i mutaciones-gacelas ]
      [set temp item i Genoma - item i mutaciones-gacelas ]
    if (temp <= 0) [set temp item i mutaciones-gacelas ]
    set Genoma replace-item i Genoma temp
    set i i + 1
  ]
  set Velocidad item 0 Genoma
  set Aceleracion  item 1 Genoma
  if item 2 Genoma > 360 [set Genoma replace-item 2 Genoma 360]
  set Campo-vision  item 2 Genoma
  set Distancia-vision item 3 Genoma
  if item 4 Genoma > 75 [set Genoma replace-item 4 Genoma 75]
  set Aguante item 4 Genoma
  set Inteligencia item 5 Genoma
  if item 6 Genoma > Distancia-vision [set Genoma replace-item 6 Genoma Distancia-vision]
  set Rango-seguridad  item 6 Genoma
  set Angulo-giro  item 7 Genoma
  set Angulo-evitar  item 8 Genoma
  set Angulo-escape  item 9 Genoma
  set Agilidad item 10 Genoma
  set Energia-por-comer item 11 Genoma
  set Destreza item 12 Genoma
  ;; Hay una pequeña probabilidad de que cambie de sexo
  if random-float 100 < 5 [set Sexo ifelse-value (Sexo = "hembra") ["macho"]["hembra"]]
end

;;------------;;
;; Mover león ;;
;;------------;;

;; Procedimiento para gobernar los leones y la pérdida de energía
to mover-leon
  set Energia Energia - 1
  let presas-gacelas gacelas in-cone Distancia-vision Campo-vision
  let presas-humanos humanos in-cone Distancia-vision Campo-vision
  ;; Primero intenta cazar gacelas
  ifelse  (any? presas-gacelas)
    [
      let objetivos presas-gacelas in-radius 2
      ifelse any? objetivos
        [
          let objetivo one-of objetivos
          cazar-gacela objetivo
          mover
        ]
        [
          ;; Si no hay gacelas cerca, se dirige a ellas
          aproxima min-one-of presas-gacelas [distance myself] Angulo-giro
          fd Velocidad
          set Energia Energia - Velocidad * Energia-arranque
        ]
    ]
    [
      ;; Si no hay gacelas a su vista, intenta cazar humanos
      ifelse  (any? presas-humanos)
      [
        let objetivos presas-humanos in-radius 2
        ifelse any? objetivos
        [
          let objetivo one-of objetivos
          cazar-humano objetivo
          mover
        ]
        [
          ;; Si no hay humanos cerca, se dirige a ellos
          aproxima min-one-of presas-humanos [distance myself] Angulo-giro
          fd Velocidad
          set Energia Energia - Velocidad * Energia-arranque]
      ]
      [mover]
    ]

end

;;--------------;;
;; Cazar gacela ;;
;;--------------;;

;; Procedimiento que ejecuta el combate entre predador y presa y actúa en consecuencia con el resultado obtenido
;; El predador puede ser un león o un humano y la presa una gacela
to cazar-gacela [objetivo]
  ;; Ejecutar el combate
  let resultado combate self objetivo
  ;; Si gana el león o el humano -> cazar a la gacela
  ifelse resultado = 1
  [
    ask objetivo [
      if Combates-ganados > max-ganados-gacelas [set max-ganados-gacelas Combates-ganados]
      die ;; Matar a la gacela
    ]
    set Energia Energia + Energia-por-comer
    set Combates-ganados Combates-ganados + 1
    set gacelas-cazadas gacelas-cazadas + 1
    if is-leon? self [set combates-ganados-leones combates-ganados-leones + 1]
    if is-humano? self [set combates-ganados-humanos combates-ganados-humanos + 1]
  ]
  [
    ;; Pierde el león o el humano -> la gacela escapa
    ask objetivo [
      set Combates-ganados Combates-ganados + 1
      set combates-ganados-gacelas combates-ganados-gacelas + 1
    ]
  ]

end

;;--------------;;
;; Cazar humano ;;
;;--------------;;

;; Procedimiento que ejecuta el combate entre predador y presa y actúa en consecuencia con el resultado obtenido
;; El predador puede ser un león y las presa un humano
to cazar-humano [objetivo]
  let resultado combate self objetivo
  ;; Gana el león -> cazar al humano
  ifelse resultado = 1
  [
    ask objetivo [
      if Combates-ganados > max-ganados-humanos [set max-ganados-humanos Combates-ganados]
      die]
    set Energia Energia + Energia-por-comer
    set Combates-ganados Combates-ganados + 1
    set humanos-cazados humanos-cazados + 1
    set combates-ganados-leones combates-ganados-leones + 1
  ]
  [
    ;; Pierde el león -> el humano caza al león y se alimenta de él
    set leones-cazados leones-cazados + 1
    set combates-ganados-humanos combates-ganados-humanos + 1
    ask objetivo [
      set Energia Energia + Energia-por-comer
      set Combates-ganados Combates-ganados + 1
    ]
    if Combates-ganados > max-ganados-leones [set max-ganados-leones Combates-ganados]
    die ;; Matar al leon
  ]
end

;;-----------------;;
;; Reproducir león ;;
;;-----------------;;

;; Procedimiento análogo a reproducir-gacela (ver comentarios en dicho procedimiento)
to reproducir-leon
  if random-float 100 < %reproduccion-leones and Puede-reproducirse? and Energia > 2 * Energia-nacimiento
  [
    let padre1 self
    let padre2 nobody
    let #leones-sexo-opuesto count leones with [Sexo != [Sexo] of padre1 and Puede-reproducirse? ]
    ifelse #leones-sexo-opuesto >= 3
      [
        set padre2 max-one-of (n-of 3 leones with [Sexo != [Sexo] of padre1 and Puede-reproducirse?]) [Combates-ganados / (Edad + 1)]
      ]
      [
        if #leones-sexo-opuesto > 0[
          set padre2 max-one-of (n-of #leones-sexo-opuesto leones with [Sexo != [Sexo] of padre1 and Puede-reproducirse?]) [Combates-ganados / (Edad + 1)]
        ]
      ]

    if padre2 != nobody[

      let genes-hijo cruzamiento ([Genoma] of padre1) ([Genoma] of padre2)
      set Energia Energia - Energia-nacimiento
      set Puede-reproducirse? false
      ask padre2 [
        ifelse Energia > 2 * Energia-nacimiento
        [set Energia Energia - Energia-nacimiento]
        [set Energia Energia / 2]
        set Puede-reproducirse? false
      ]

      hatch 1 [
        rt random-float 360
        set Energia Energia-nacimiento
        set Edad 0
        set Combates-ganados 0
        set Puede-reproducirse? true
        set Genoma item one-of [0 1] genes-hijo
        set Sexo ifelse-value (count leones with [Sexo = "hembra"] >= count leones with [Sexo = "macho"])["macho"]["hembra"]
        if random-float 100 < %mutacion-leones [mutar-leon]
        fd Velocidad
      ]
    ]
  ]
end

;;------------;;
;; Mutar león ;;
;;------------;;

;; Modifica los genes aplicando la mutación y cuidando los límites de cada parámetro.
to mutar-leon
  let i 0
  let temp 0
  while [i < ( length Genoma ) ][
    ifelse ((random 2) = 0 )
      [set temp item i Genoma + item i mutaciones-leones ]
      [set temp item i Genoma - item i mutaciones-leones ]
    if (temp <= 0) [set temp item i mutaciones-leones ]
    set Genoma replace-item i Genoma temp
    set i i + 1
  ]
  set Velocidad item 0 Genoma
  set Aceleracion  item 1 Genoma
  if item 2 Genoma > 360 [set Genoma replace-item 2 Genoma 360]
  set Campo-vision  item 2 Genoma
  set Distancia-vision item 3 Genoma
  if item 4 Genoma > 75 [set Genoma replace-item 4 Genoma 75]
  set Aguante item 4 Genoma
  set Inteligencia item 5 Genoma
  set Sigilo item 6 Genoma
  set Destreza item 7 Genoma
  set Energia-por-comer item 8 Genoma
  if random-float 100 < 5 [set Sexo ifelse-value (Sexo = "hembra") ["macho"]["hembra"]]
end


;;--------------;;
;; Mover humano ;;
;;--------------;;

;; Procedimiento para gobernar los humanos y la pérdida de energía
to mover-humano
  set Energia Energia - 1
  ;; Buscar gacelas cercanas
  let presas gacelas in-cone Distancia-vision Campo-vision
  ifelse  (any? presas)
    [ let objetivos presas in-radius Distancia-ataque  ;; Utilizar Distancia-ataque como radio de búsqueda de presas
      ifelse any? objetivos
        [
          ;; Si hay algún objetivo, intentar cazarlo
          let objetivo one-of objetivos
          cazar-gacela objetivo
          mover
        ]
        [
          ;; Si no hay gacelas cerca, se dirige a ellas
          aproxima min-one-of presas [distance myself] Angulo-giro
          fd Velocidad
          set Energia Energia - Velocidad * Energia-arranque
        ]
    ]
    [
      mover
    ]
end

;;---------------------------------;;
;; Alimentar humano con vegetación ;;
;;---------------------------------;;

;; Procedimiento que permite al humano alimentarse de vegetación
to alimentar-humano-vegetacion
  if pcolor = green [
    set pcolor brown
    ;; La energía ganada es la mitad de lo que ganaría con una gacela o un león
    set Energia Energia + Energia-por-comer / 2
  ]
end

;;-------------------;;
;; Reproducir humano ;;
;;-------------------;;

;; Procedimiento análogo a reproducir-gacela (ver comentarios en dicho procedimiento)
to reproducir-humano
  if random-float 100 < %reproduccion-humanos and Puede-reproducirse? and Energia > 2 * Energia-nacimiento
  [

    let padre1 self
    let padre2 nobody
    let #humanos-sexo-opuesto count humanos with [Sexo != [Sexo] of padre1 and Puede-reproducirse? ]
    ifelse #humanos-sexo-opuesto >= 3
      [
        set padre2 max-one-of (n-of 3 humanos with [Sexo != [Sexo] of padre1 and Puede-reproducirse?]) [Combates-ganados / (Edad + 1)]
      ]
      [
        if #humanos-sexo-opuesto > 0[
          set padre2 max-one-of (n-of #humanos-sexo-opuesto humanos with [Sexo != [Sexo] of padre1 and Puede-reproducirse?]) [Combates-ganados / (Edad + 1)]
        ]
      ]

    if padre2 != nobody[

      let genes-hijo cruzamiento ([Genoma] of padre1) ([Genoma] of padre2)
      set Energia Energia - Energia-nacimiento
      set Puede-reproducirse? false
      ask padre2 [
        ifelse Energia > 2 * Energia-nacimiento
        [set Energia Energia - Energia-nacimiento]
        [set Energia Energia / 2]
        set Puede-reproducirse? false
      ]

      hatch 1 [
        rt random-float 360
        set Energia Energia-nacimiento
        set Edad 0
        set Combates-ganados 0
        set Puede-reproducirse? true
        set Genoma item one-of [0 1] genes-hijo
        set Sexo ifelse-value (count humanos with [Sexo = "hembra"] >= count humanos with [Sexo = "macho"])["macho"]["hembra"]
        if random-float 100 < %mutacion-humanos [mutar-humano]
        fd Velocidad
      ]
    ]
  ]
end

;;--------------;;
;; Mutar humano ;;
;;--------------;;

;; Modifica los genes aplicando la mutación y cuidando los límites de cada parámetro.
to mutar-humano
  let i 0
  let temp 0
  while [i < ( length Genoma ) ][
    ifelse ((random 2) = 0 )
      [set temp item i Genoma + item i mutaciones-humanos ]
      [set temp item i Genoma - item i mutaciones-humanos ]
    if (temp <= 0) [set temp item i mutaciones-humanos ]
    set Genoma replace-item i Genoma temp
    set i i + 1
  ]
  set Velocidad item 0 Genoma
  set Aceleracion  item 1 Genoma
  if item 2 Genoma > 360 [set Genoma replace-item 2 Genoma 360]
  set Campo-vision  item 2 Genoma
  set Distancia-vision item 3 Genoma
  if item 4 Genoma > 75 [set Genoma replace-item 4 Genoma 75]
  set Aguante item 4 Genoma
  set Inteligencia item 5 Genoma
  set Distancia-ataque item 6 Genoma
  set Punteria item 7 Genoma
  set Arma item 8 Genoma
  set Energia-por-comer item 9 Genoma
  if random-float 100 < 5 [set Sexo ifelse-value (Sexo = "hembra") ["macho"]["hembra"]]
end

;;-------;;
;; Morir ;;
;;-------;;

;; Procedimiento que mata a todos los individuos que tengan enería negativa
to morir
  if Energia < 0 [
    if is-leon? self [
      set inanicion-leones inanicion-leones + 1
      if Combates-ganados > max-ganados-leones [set max-ganados-leones Combates-ganados]
    ]
    if is-gacela? self [
      if Combates-ganados > max-ganados-gacelas [set max-ganados-gacelas Combates-ganados]
      set inanicion-gacelas inanicion-gacelas + 1
    ]
    if is-humano? self [
      if Combates-ganados > max-ganados-humanos [set max-ganados-humanos Combates-ganados]
      set inanicion-humanos inanicion-humanos + 1
    ]
    die
  ]
end

;;----------;;
;; Aproxima ;;
;;----------;;

;; Procedimiento de gacelas, leones y humanos para girar en dirección al objetivo con un ángulo máximo de giro.
to aproxima [objetivo angulo-maximo]
  let angulo subtract-headings towards objetivo heading
  ifelse abs (angulo) > angulo-maximo
  [
    ifelse angulo > 0
      [rt angulo-maximo ]
      [lt angulo-maximo]
  ]
  [rt angulo]
end

;;--------;;
;; Alinea ;;
;;--------;;

;; Procedimiento para girar en la dirección a la que apunta el objetivo, con un ángulo máximo de giro.
to alinea [objetivo angulo-maximo]
  let angulo subtract-headings [heading] of objetivo heading
  ifelse abs (angulo) > angulo-maximo
    [
      ifelse angulo > 0
        [rt angulo-maximo ]
        [lt angulo-maximo]
    ]
    [rt angulo]
end

;;-------;;
;; Evita ;;
;;-------;;

;; Procedimiento de gacelas para girar alejándose del objetivo, con ángulo máximo de giro.
to evita [objetivo angulo-maximo]
  if (not member? objetivo gacelas-here)[
    let angulo subtract-headings ((towards objetivo) + 180) heading
    ifelse abs(angulo) > Angulo-Giro
      [
        ifelse angulo > 0
          [rt angulo-maximo ]
          [lt angulo-maximo]
      ]
      [rt angulo]
  ]
end

;;---------;;
;; Combate ;;
;;---------;;

;; Función que devuelve el resultado de un combate. Si gana el luchador1, el resultado es 1, en caso contrario, si gana
;; el luchador2, el resultado es -1
;; El primer parámetro debe ser el predador y el segundo la presa
to-report combate [luchador1 luchador2]
  let resultado 0

  ;; León VS gacela
  if is-leon? luchador1 and is-gacela? luchador2[
    let leon luchador1
    let gacela luchador2
    let poder-gacela [Aguante] of gacela * 1 + [Agilidad] of gacela  * 1 + [Destreza] of gacela  * 1 + [Inteligencia] of gacela * 1
    set poder-gacela poder-gacela
    let poder-leon [Aguante] of leon * 1 + [Sigilo] of leon * 1 + [Destreza] of leon * 1 + [Inteligencia] of leon * 1
    set poder-leon poder-leon
    set resultado ifelse-value (poder-leon * (random-float 1 + 1) >= poder-gacela * (random-float 1 + 1)) [1][-1]
  ]

  ;; León VS humano
  if is-leon? luchador1 and is-humano? luchador2[
    let leon luchador1
    let humano luchador2
    let poder-humano [Aguante] of humano * 1 + [Punteria] of humano * 1 + [Arma] of humano * 1 + [Inteligencia] of humano * 1
    set poder-humano poder-humano
    let poder-leon [Aguante] of leon * 1 + [Sigilo] of leon * 1 + [Destreza] of leon * 1 + [Inteligencia] of leon * 1
    set poder-leon poder-leon
    set resultado ifelse-value (poder-leon * (random-float 1 + 1) >= poder-humano * (random-float 1 + 1)) [1][-1]
  ]

  ;; Humano VS gacela
  if is-humano? luchador1 and is-gacela? luchador2[
    let humano luchador1
    let gacela luchador2
    let poder-humano [Aguante] of humano * 1 + [Punteria] of humano * 1 + [Arma] of humano * 1 + [Inteligencia] of humano * 1
    set poder-humano poder-humano
    let poder-gacela [Aguante] of gacela * 1 + [Agilidad] of gacela  * 1 + [Destreza] of gacela  * 1 + [Inteligencia] of gacela * 1
    set poder-gacela poder-gacela
    set resultado ifelse-value (poder-humano * (random-float 1 + 1) >= poder-gacela * (random-float 1 + 1)) [1][-1]
  ]
  report resultado
end

;;-------------;;
;; Cruzamiento ;;
;;-------------;;

;; La siguiente función realiza un cruzamiento (en un punto) de dos
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

;;----------------------;;
;; Crecer la vegetación ;;
;;----------------------;;

;; Procedimiento que hace crecer la vegetación del entorno
to crecer-vegetacion
  ask patches [
    ;; Si el patch es marrón y el temporizador llega a 0, hacer crecer la vegetación en él
    if pcolor = brown [
      ifelse temporizador <= 0
      [ set pcolor green
        set temporizador tiempo-crec-vegetacion ]
      [ set temporizador temporizador - 1 ]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
330
10
799
500
25
25
9.0
1
14
1
1
1
0
1
1
1
-25
25
-25
25
1
1
1
ticks
30.0

SLIDER
5
70
160
103
poblacion-gacelas
poblacion-gacelas
0
100
50
1
1
NIL
HORIZONTAL

SLIDER
165
70
320
103
gacela-energia-por-comer
gacela-energia-por-comer
0.0
50.0
5
1.0
1
NIL
HORIZONTAL

SLIDER
5
105
160
138
%reproduccion-gacelas
%reproduccion-gacelas
0
20.0
5
1.0
1
%
HORIZONTAL

SLIDER
5
165
160
198
poblacion-leones
poblacion-leones
0
100
25
1
1
NIL
HORIZONTAL

SLIDER
165
165
320
198
leon-energia-por-comer
leon-energia-por-comer
0.0
100.0
40
1.0
1
NIL
HORIZONTAL

SLIDER
5
200
160
233
%reproduccion-leones
%reproduccion-leones
0.0
20.0
5
1.0
1
%
HORIZONTAL

SLIDER
65
10
320
43
tiempo-crec-vegetacion
tiempo-crec-vegetacion
0
100
25
1
1
NIL
HORIZONTAL

BUTTON
5
370
160
403
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
163
370
318
403
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

PLOT
810
10
1130
215
Población
tiempo
poblacion
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"gacelas" 1.0 0 -13345367 true "" "plot count gacelas"
"leones" 1.0 0 -2674135 true "" "plot count leones"
"humanos" 1.0 0 -10899396 true "" "plot count humanos"
"vegatacion" 1.0 0 -11221820 true "" "plot (count patches with [pcolor = green]) / 4"

MONITOR
810
215
890
260
gacelas
count gacelas
3
1
11

MONITOR
890
215
970
260
leones
count leones
3
1
11

MONITOR
1050
215
1130
260
vegetacion / 4
count patches with [pcolor = green] / 4
0
1
11

TEXTBOX
8
50
148
69
Configuración gacelas
13
105.0
0

MONITOR
1140
160
1295
205
Comb. gan. mejor gacela viva
max [Combates-ganados] of gacelas
17
1
11

MONITOR
1295
160
1450
205
Comb. gan. mejor león vivo
max [Combates-ganados] of leones
17
1
11

SLIDER
165
105
320
138
%mutacion-gacelas
%mutacion-gacelas
0
10
1
0.1
1
%
HORIZONTAL

SLIDER
165
200
320
233
%mutacion-leones
%mutacion-leones
0
10
1
0.1
1
%
HORIZONTAL

PLOT
1140
10
1610
160
Combates ganados
tiempo
total
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"gacelas" 1.0 0 -13345367 true "" "plot combates-ganados-gacelas"
"leones" 1.0 0 -2674135 true "" "plot combates-ganados-leones"
"humanos" 1.0 0 -10899396 true "" "plot combates-ganados-humanos"

PLOT
1140
210
1610
360
Mejor individuo raza en la historia
tiempo
ganados / edad
0.0
0.0
0.0
0.0
true
true
"" ""
PENS
"gacelas" 1.0 0 -13345367 true "" "plot max-ganados-gacelas"
"leones" 1.0 0 -2674135 true "" "plot max-ganados-leones"
"humanos" 1.0 0 -10899396 true "" "plot max-ganados-humanos"

PLOT
1140
365
1610
530
Muertes
tiempo
# muertes
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Inanicion leones" 1.0 0 -1184463 true "" "plot inanicion-leones"
"Inanicion gacelas" 1.0 0 -955883 true "" "plot inanicion-gacelas"
"Inanicion humanos" 1.0 0 -5298144 true "" "plot inanicion-humanos"
"Gacelas cazadas" 1.0 0 -16777216 true "" "plot gacelas-cazadas / 4"
"Leones cazados" 1.0 0 -7500403 true "" "plot leones-cazados"
"Humanos cazados" 1.0 0 -4539718 true "" "plot humanos-cazados"

SLIDER
5
265
160
298
poblacion-humanos
poblacion-humanos
0
100
25
1
1
NIL
HORIZONTAL

SLIDER
165
265
320
298
humano-energia-por-comer
humano-energia-por-comer
1
100
15
1
1
NIL
HORIZONTAL

SLIDER
5
305
160
338
%reproduccion-humanos
%reproduccion-humanos
0
20
5
1
1
%
HORIZONTAL

SLIDER
165
305
320
338
%mutacion-humanos
%mutacion-humanos
0
10
1
0.1
1
%
HORIZONTAL

MONITOR
970
215
1050
260
humanos
count humanos
17
1
11

MONITOR
1450
160
1610
205
Comb. gan. mejor humano vivo
max [Combates-ganados] of humanos
17
1
11

TEXTBOX
10
145
160
163
Configuración leones
13
15.0
1

TEXTBOX
10
245
160
263
Configuración humanos
13
55.0
1

TEXTBOX
10
10
55
28
Entorno
13
0.0
1

TEXTBOX
110
345
220
365
============
13
0.0
1

PLOT
810
270
1130
470
Energía media razas
tiempo
energía
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"gacelas" 1.0 0 -13345367 true "" "if count gacelas > 0 [plot mean [Energia] of gacelas ]"
"leones" 1.0 0 -2674135 true "" "if count leones > 0 [plot mean [Energia] of leones]"
"humanos" 1.0 0 -10899396 true "" "if count humanos > 0 [plot mean [Energia] of humanos]"

@#$#@#$#@
# Wild Evolution

## QUÉ ES ESTO

Modelo de predador-presa, simulado con tres razas: gacelas, leones y humanos, que ilustra la evolución de las especies en un entorno salvaje. Cada raza está programada con características comunes y específicas, que determinan su comportamiento.

Las gacelas se alimentan de la vegetación del entorno, los leones cazan gacelas y humanos, y por último, los humanos, cazan gacelas, aunque también se pueden alimentar de la vegetación y de los leones bajo ciertas circunstancias.

Todos ellos se reproducen sexualmente y van evolucionando tanto por mutación como por intercambio de genes del genoma de los individuos, dos de los fundamentos principales de los algoritmos genéticos.

## CÓMO FUNCIONA

Los parámetros que gobiernan los comportamientos de las tres razas se almacenan en un genoma en cada individuo. Inicialmente, el valor del genoma se genera aleatoriamente y a medida que pasa el tiempo, los valores de cada gen van cambiando debido a la reproducción sexual y a la mutación, citada en el apartado anterior. Los individuos se reproducen y mutan únicamente cuando tienen suficiente energía acumulada, y además, bajo una determinada probabilidad establecida.

Los genes que intervienen en el genoma común a las razas son: velocidad, aceleración, campo de visión, distancia de visión, aguante, inteligencia y energía obtenida por comer.

Los específicos de las gacelas son: ángulo de evasión, ángulo de escape, rango de seguridad, agilidad y destreza.

Los específicos de los leones son: sigilo y destreza.

Los específicos de los humanos son: distancia de ataque, puntería y arma.

Es muy importante destacar que el comportamiento de la simulación depende de muchos factores y no siempre es el mismo. Las especies no tienen por qué evolucionar siempre en la misma dirección. Sin embargo, se ha intentado en la medida de lo posible que el entorno sea estable con la configuración que viene por defecto en la interfaz gráfica, y no se extinga ninguna especie durante un tiempo. Se puede leer más información sobre este aspecto en el apartado "Experimentación".

### ALIMENTACIÓN

#### GACELAS

Como se introdujo anteriormente, las gacelas ganan energía y se alimentan de la vegetación que crece en el entorno.

#### LEONES

Los leones prefieren perseguir y cazar a las gacelas que se encuentren dentro de su rango de visión, aunque si no hay ninguna cerca, intentarán dar caza a los humanos.

Para que un león cace a una gacela tiene que ganar un combate previo que depende de las características de raza de cada individuo. Si el león gana el combate, la gacela muera y el león se alimenta de ella, ganando energía. En el caso de que no gane el combate, la gacela escapará sana y salva.

Si el león se enfrenta a un humano se librará también un combate entre ellos, cuyo resultado depende nuevamente en gran medida de los atributos de los individuos participantes. Si el león gana se alimenta del humano y gana energía. En el caso contrario, si el león pierde la batalla, el humano se dará un festín con su cadáver y aumentará su energía.

#### HUMANOS

Los humanos tienen tres fuentes de alimentación:

1. La principal fuente son las gacelas. El humano intentará siempre dar caza a las gacelas del entorno y pelear con ellas para alimentarse si gana. Para suplir la falta de velocidad y aceleración con otras especies, el humano tiene el atributo "distancia de ataque" que le permite cazar desde mayores distancias.
2. Cuando un humano está muy débil, existe la posibilidad de que se alimente de vegetación del paisaje, aunque la energía que gana es la mitad de la que ganaría al comerse una gacela. Por lo tanto, es una estrategia para poder sobrevivir un poco de más tiempo hasta que consiga cazar algún animal.
3. Cuando el humano es atacado por un león se defiende, y si gana, se alimentará de este. El humano no comenzará nunca una batalla contra un león, solo lo hará para defenderse.


### REPRODUCCIÓN (CROSS OVER) Y MUTACIÓN
La reproducción de las especies se efectúa del siguiente modo:

Si un individuo es elegido para reproducirse (tiene suficiente energía y ha pasado el filtro de probabilidad) pasa a ser el primer padre.

El segundo padre se elige mediante una selección por torneo de tamaño 3 entre aquellos individuos de la misma raza y sexo opuesto al del primer padre, que aún no se hayan reproducido en esta generación, y que además, tengan la mejor proporción de combates ganados por año vivido (valor de fitness).

Una vez elegidos los dos padres, se produce una recombinación de la información genética de ambos que crea dos nuevos genomas. A diferencia de otros algoritmos genéticos, en este modelo no nacen dos hijos, sino únicamente uno, y su genoma se elige aleatoriamente entre los dos generados por los padres.

Al nacer el nuevo individuo, existe una probabilidad de que mute alterando parte de sus genes.

En resumen, el objetivo es intentar conseguir que los individuos que van naciendo ganen más combates contra otras razas que sus antepasados, con el fin de sobrevivir más tiempo en un entorno hostil.

### COMBATE

En los combates intervienen algunas características específicas de cada especie:

1. Gacelas: aguante, agilidad, destreza e inteligencia.
2. Leones: aguante, sigilo, destreza e inteligencia.
3. Humanos: aguante, puntería, arma e inteligencia.

En la puntuación final que tiene cada individuo que participa en la batalla, interviene un pequeño factor aleatorio.

## CÓMO SE USA
Utilizar los elementos de la interfaz gráfica que se describen a continuación para configurar la simulación, luego pulsar en "Setup", y por último en "Go" para ejecutarlo.

En la interfaz de usuario se encuentran los siguientes elementos:

### CONFIGURAR ENTORNO

- _tiempo-crec-vegetacion_ (deslizador): Establece el tiempo que tarda la vegetación en crecer en un patch.

### CONFIGURAR GACELAS

- _poblacion-gacelas_ (deslizador): Establece la población inicial de gacelas que habrá en el entorno.

- _gacela-energia-por-comer_ (deslizador): Establece la energía que ganan las gacelas al alimentarse.

- _%reproduccion-gacelas_ (deslizador): Establece la probabilidad de reproducción de las gacelas.

- _%mutacion-gacelas_ (deslizador): Establece la probabilidad de mutación de las gacelas.

### CONFIGURAR LEONES

- _poblacion-leones_ (deslizador): Establece la población inicial de leones que habrá en el entorno.

- _leon-energia-por-comer_ (deslizador): Establece la energía que ganan los leones al alimentarse.

- _%reproduccion-leones_ (deslizador): Establece la probabilidad de reproducción de los leones.

- _%mutacion-leones_ (deslizador): Establece la probabilidad de mutación de los leones.

### CONFIGURAR HUMANOS

- _poblacion-humanos_ (deslizador): Establece la población inicial de humanos que habrá en el entorno.

- _humano-energia-por-comer_ (deslizador): Establece la energía que ganan los humanos al alimentarse.

- _%reproduccion-humanos_ (deslizador): Establece la probabilidad de reproducción de los humanos.

- _%mutacion-humanos_ (deslizador): Establece la probabilidad de mutación de los humanos.


### GRÁFICAS Y MONITORES

- _Gráfica "Población"_: Muestra la evolución de la población de cada raza y de la vegetación en el tiempo. Además, se han incorporado varios monitores en la parte inferior de la gráfica para ver los valores de forma rápida.

- _Gráfica "Energía media razas"_: Muestra la evolución de la media de energía que tienen los individuos de cada raza en el tiempo.

- _Gráfica "Combates ganados"_: Muestra la evolución del número total de combates ganados en cada raza en el tiempo. Además, se han incorporado varios monitores en la parte inferior de la gráfica que muestran, para cada raza, el número de combates ganados del mejor individuo que sigue vivo en la actual generación.

- _Gráfica "Mejor individuo raza en la historia"_: Muestra los combates ganados de los mejores individuos que han vivido de cada raza durante la historia.

- _Gráfica "Muertes"_: Muestra la evolución de todos los tipos de muertes (inanición o cazado) que se pueden dar en la simulación a lo largo del tiempo.


## DESARROLLANDO EL MODELO

En este apartado se pretenden describir brevemente los pasos que se han seguido para desarrollar el modelo y los problemas encontrados durante el camino.

1. Se estudiaron dos modelos predador-presa existentes en la biblioteca de Netlogo, en concreto, "Sharks and Minnows" y "Wolf Sheep Predation", para tomar ideas de ambos.

2. Se desarrolló un modelo con una única especie y muy pocas características, las gacelas, para comprobar que podían sobrevivir sin ningún tipo de inconvenientes.

3. Se introdujo la raza de leones, más atributos en las especies y la funcionalidad de combatir. Para las características específicas se consultaron varias fuentes en internet para ver el comportamiento de leones y gacelas en la realidad, e intentar ajustar los parámetros para simularlo.

4. Se añadió la reproducción sexual y la mutación a las dos razas, y se ajustaron parámetros para que ambas vivieran en un entorno estable y ninguna se extinguiera con el paso del tiempo.

5. Se metieron los humanos en el juego, lo que produjo bastantes desajustes al tener que convivir las tres razas al mismo tiempo. Durante esta fase se añadieron distintas estrategias como por ejemplo la capacidad de los humanos para alimentarse de vegetación o la posibilidad de cazar a distancia.

6. Se intentó ajustar la función que determina el vencedor de un combate sin mucho éxito. Para ello, se probó añadir distintos pesos a los parámetros que intervienen en el cálculo de la puntuación, por ejemplo que la inteligencia en los humanos tenga más importancia que el aguante, o que el sigilo de los leones tenga mucha más importancia que el aguante o la inteligencia. El resultado no fue el esperado y no se lograba el equilibrio por lo que finalmente al cálculo es una simple suma de variables. También se probó con distintas formas de que la energía que tiene el individuo sea un factor decisivo a la hora de combatir, aplicando un porcentaje de aguante al mismo tiempo. El resultado tampoco fue el esperado en este caso, quizás debido a que la función de normalización no era la mejor.

En todas las fases se realizaron bastantes pruebas de simulación para ver que el objetivo era el deseado.

## EXPERIMENTACIÓN Y CONCLUSIONES

Los resultados de la simulación de este modelo dependen de muchos factores por ello es recomendable experimentar tanto con distintos parámetros iniciales de configuración, como con distintos valores en los listados de mutaciones de las razas.

El modelo viene por defecto configurado para que la probabilidad de que las tres razas sobrevivan durante un tiempo y ninguna se extinga sea considerable. En ocasiones esto no ocurre y mueren todos los leones o todos los humanos, debido a que pierden muchos combates, a la falta de energía, etc. En la medida de lo posible, Se ha intentado que el número de gacelas siempre sea alto con el fin de alimentar a las otras dos razas.

Destacar que cuando hay solamente dos razas compitiendo en el entorno, siendo una de ellas las gacelas, la simulación se vuelve muy estable. Por ejemplo, si lanzamos una simulación con leones y gacelas, las gacelas se reproducen rápidamente gracias a la cantidad de vegetación que hay en el paisaje. Esto provoca que haya mucha más gacelas que leones y estos no tengan problemas para alimentarse, de tal modo que empiezan a cazar y a reproducirse rápidamente. Llega un punto en el que los leones no pueden aguantar ese ritmo y empiezan a morir. Al mismo tiempo, la vegetación vuelve a regenerarse y las gacelas vuelven a crecer en número. Este ciclo de vida que depende de gacelas, leones y vegetación se puede observar claramente en la gráfica de "Población".

Otro de los experimentos realizados ha sido cambiar el listado de mutaciones inicial. Por ejemplo, para que los humanos acaben con todos los leones y todas las gacelas, se le puede aumentar el gen séptimo, distancia de ataque, que como se citó anteriormente permite en cierta medida suplir la falta de velocidad y aceleración, en comparación con gacelas y leones. Aumentando este gen, los humanos empezarán a cazar gacelas desde posiciones lejanas sin apenas necesitar moverse, por lo que el gasto de energía será muy bajo, se reproducirán rápidamente y los leones no podrán, ni cazar gacelas, ni hacerles frente.

La evolución de las especies, utilizando como valor de fitness la proporción entre el número de combates ganados y la edad de vida, se puede observar en la gráfica "Mejor individuo raza en la historia". Al principio, todas las razas mejoran sus individuos rápidamente hasta llegar un punto en el que hacen falta muchas generaciones para obtener mejores resultados de combates ganados. Probablamente, si las razas al reproducirse generarán dos hijos en lugar de uno, este proceso sería más rápido, aunque por otro lado, puede afectar negativamente a la estabilización del sistema.


## REFERENCIAS

http://ccl.northwestern.edu/netlogo/models/WolfSheepPredation
http://www.cs.us.es/~fsancho/?e=65
https://github.com/fsancho/IA/blob/master/Computacion%20Evolutiva/Tiburones%20y%20pececillos%20evolutivos.nlogo
https://github.com/fsancho/IA/blob/master/Computacion%20Evolutiva/Algoritmo%20Genetico.nlogo
http://www.naturalhighsafaris.com/faqs/article/how-lions-hunt
http://www.botanical-online.com/animales/leon.htm
http://www.botanical-online.com/animales/gacela.htm


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

gacela
false
0
Polygon -7500403 true true 75 225 97 249 112 252 122 252 114 242 102 241 89 224 94 181 64 113 46 119 31 150 32 164 61 204 57 242 85 266 91 271 101 271 96 257 89 257 70 242
Polygon -7500403 true true 216 73 219 56 229 42 237 66 226 71
Polygon -7500403 true true 181 106 213 69 226 62 257 70 260 89 285 110 272 124 234 116 218 134 209 150 204 163 192 178 169 185 154 189 129 189 89 180 69 166 63 113 124 110 160 111 170 104
Polygon -6459832 true false 252 143 242 141
Polygon -6459832 true false 254 136 232 137
Line -16777216 false 75 224 89 179
Line -16777216 false 80 159 89 179
Polygon -6459832 true false 262 138 234 149
Polygon -7500403 true true 171 181 178 263 187 277 197 273 202 267 187 260 186 236 194 167
Polygon -7500403 true true 187 163 195 240 214 260 222 256 222 248 212 245 205 230 205 155
Polygon -7500403 true true 223 75 226 58 245 44 244 68 233 73
Line -16777216 false 89 181 112 185
Line -16777216 false 31 150 47 118
Polygon -16777216 true false 235 90 250 91 255 99 248 98 244 92
Line -16777216 false 236 112 246 119
Polygon -16777216 true false 278 119 282 116 274 113
Line -16777216 false 189 201 203 161
Line -16777216 false 90 262 94 272
Line -16777216 false 110 246 119 252
Line -16777216 false 190 266 194 274
Line -16777216 false 218 251 219 257
Polygon -16777216 true false 230 67 228 54 222 62 224 72
Line -16777216 false 246 67 234 64
Line -16777216 false 229 45 235 68
Polygon -7500403 true true 60 120 30 150 30 195
Polygon -6459832 true false 255 75 240 60 210 45 210 30 210 45 210 15 225 45 255 60
Polygon -6459832 true false 240 75 225 60 195 45 195 30 195 45 195 15 210 45 240 60

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

leon
false
0
Circle -1184463 true false 204 114 42
Circle -1184463 true false 204 39 42
Polygon -7500403 true true 75 225 97 249 112 252 122 252 114 242 102 241 89 224 94 181 64 113 46 119 31 150 32 164 61 204 57 242 85 266 91 271 101 271 96 257 89 257 70 242
Polygon -7500403 true true 216 73 219 56 229 42 237 66 226 71
Polygon -7500403 true true 181 106 213 69 226 62 257 70 260 89 270 105 255 120 234 116 218 134 209 150 204 163 192 178 169 185 154 189 129 189 89 180 69 166 63 113 124 110 160 111 170 104
Polygon -6459832 true false 252 143 242 141
Polygon -6459832 true false 254 136 232 137
Line -16777216 false 75 224 89 179
Line -16777216 false 80 159 89 179
Polygon -6459832 true false 262 138 234 149
Polygon -7500403 true true 50 121 45 120 30 135 15 165 15 180 15 195 0 225 23 201 28 184 30 165 28 153 48 145
Polygon -7500403 true true 171 181 178 263 187 277 197 273 202 267 187 260 186 236 194 167
Polygon -7500403 true true 187 163 195 240 214 260 222 256 222 248 212 245 205 230 205 155
Polygon -7500403 true true 223 75 226 58 245 44 244 68 233 73
Line -16777216 false 89 181 112 185
Line -16777216 false 31 150 47 118
Polygon -16777216 true false 235 90 250 91 255 99 248 98 244 92
Line -16777216 false 236 112 246 119
Polygon -16777216 true false 263 119 267 116 255 105
Line -16777216 false 189 201 203 161
Line -16777216 false 90 262 94 272
Line -16777216 false 110 246 119 252
Line -16777216 false 190 266 194 274
Line -16777216 false 218 251 219 257
Polygon -16777216 true false 230 67 228 54 222 62 224 72
Line -16777216 false 246 67 234 64
Line -16777216 false 229 45 235 68
Line -16777216 false 30 150 30 165
Circle -1184463 true false 159 84 42
Circle -1184463 true false 174 69 42
Circle -1184463 true false 174 99 42
Circle -1184463 true false 159 114 42
Circle -1184463 true false 174 129 42
Circle -1184463 true false 189 54 42
Circle -1184463 true false 189 129 42
Circle -1184463 true false 174 54 42

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
setup
set grass? true
repeat 75 [ go ]
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
