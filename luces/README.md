# Luces, demo con varios archivos Verilog

Seis LEDs con cuatro patrones. El botón S2 cambia de patrón y S1 es reset.

| Modo | Patrón |
|---|---|
| 0 | Corrimiento circular |
| 1 | Ida y vuelta, un LED rebota de un extremo al otro |
| 2 | Contador binario |
| 3 | Parpadeo de todos |

Requisitos en [../INSTALACION.md](../INSTALACION.md). El flujo base está explicado en [../blink/PASOS_DETALLADO.md](../blink/PASOS_DETALLADO.md); aquí solo va lo que cambia al tener varios módulos.

## Módulos

```
top.v            une todo, guarda el modo e invierte los LEDs (la placa enciende con 0)
├── tick_gen.v   pulso de un ciclo cada PERIODO ciclos (8 pasos por segundo)
├── debounce.v   sincroniza y filtra el botón S2, da un pulso por pulsación
└── patrones.v   calcula el patrón de LEDs según el modo, avanza con cada tick
```

| Archivo | Entradas | Salidas |
|---|---|---|
| `tick_gen.v` | `clk`, `rst_n` | `tick` |
| `debounce.v` | `clk`, `rst_n`, `btn_n` | `pulso` |
| `patrones.v` | `clk`, `rst_n`, `tick`, `modo` | `leds[5:0]` |
| `top.v` | `sys_clk`, `sys_rst_n`, `btn_n` | `led[5:0]` |

Pines en `top.cst`: los de `blink` más `btn_n` en el pin 3 (botón S2). Cómo armar un `.cst` en [../CST.md](../CST.md).

## Síntesis paso a paso

Desde `luces/`, en el shell de Yosys.

```
read_verilog top.v tick_gen.v debounce.v patrones.v
hierarchy -check -top top
proc
opt
synth_gowin -top top -json top.json
stat
```

`read_verilog` acepta varios archivos en el mismo comando. El orden no importa, `hierarchy` es el que resuelve qué módulo usa a cuál.

Salida de `hierarchy`:

```
Top module:  \top
Used module:     \patrones
Used module:     \debounce
Used module:     \tick_gen
Parameter \PERIODO = 3375000
```

Como `top` instancia `tick_gen` con otro `PERIODO` (27 000 000 / 8), Yosys crea una copia del módulo con ese valor fijo, llamada `$paramod\tick_gen\PERIODO=...`.

Si falta un archivo en `read_verilog`, `hierarchy -check` falla con `Module ... is not part of the design`.

### Aplanado

`synth_gowin` aplana el diseño por defecto, es decir, mete todos los submódulos dentro de `top` antes de optimizar. Para ver los recursos por módulo, sintetiza sin aplanar.

```
synth_gowin -top top -noflatten
stat
```

| Módulo | Celdas sin aplanar |
|---|---|
| `tick_gen` | 100 |
| `debounce` | 117 |
| `patrones` | 130 |
| `top` | 20 |
| Total | 367 |
| Total aplanado | 264 |

Al aplanar, Yosys puede optimizar a través de los límites de los módulos, por eso el diseño final queda más chico.

## Flujo completo con make

Explicación del Makefile en [../MAKE.md](../MAKE.md).

```bash
make          # síntesis, place and route y empaquetado, genera top.fs
make cargar   # a SRAM, volátil
make flash    # a flash, persistente
make clean
```

Resultado obtenido: frecuencia máxima de 125,5 MHz, de sobra para los 27 MHz del reloj.

## Para agregar un módulo

1. Crea el `.v` con su `module`.
2. Instáncialo en `top.v`.
3. Agrégalo a `FUENTES` en el `Makefile` y a `read_verilog` si sintetizas a mano.
