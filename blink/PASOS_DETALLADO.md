# Flujo abierto de FPGA en la Tang Nano 9K

Tutorial de como cargar un simple archivo **verilog** en la FPGA Tang Nano 9K usando herramientas open source:
- Yosys
- nextpnr-himbaechel
- gowin_pack (Apicula)
- openFPGALoader

Antes de empezar, instala el entorno siguiendo [INSTALACION.md](INSTALACION.md).

## Contenido

1. Resumen del flujo
2. Plataforma y versiones
3. Diseño de partida
4. Preparar el entorno
5. Síntesis con Yosys
6. Place and route con nextpnr
7. Empaquetado con gowin_pack
8. Carga con openFPGALoader

## 1. Resumen del flujo

![Pasos del flujo](imgs/flujo_nano.png)

| Etapa | Herramienta | Entrada | Salida |
|---|---|---|---|
| Síntesis | Yosys | `top.v` | `top.json` |
| Place and route | nextpnr-himbaechel | `top.json`, `top.cst` | `pnr.json` |
| Empaquetado | gowin_pack | `pnr.json` | `top.fs` |
| Carga | openFPGALoader | `top.fs` | SRAM o flash |

## 2. Plataforma y versiones

| Elemento | Valor |
|---|---|
| Placa | Sipeed Tang Nano 9K |
| FPGA | Gowin GW1NR-9C, paquete QN88P, referencia `GW1NR-LV9QN88PC6/I5` |
| Reloj | 27 MHz, pin 52 |
| Sistema | Ubuntu en iMac, kernel 6.8 |
| Yosys | 0.71+101 |
| nextpnr | 0.11.1 (himbaechel) |
| openFPGALoader | v1.2.0 |
| Suite | OSS CAD Suite en `~/oss-cad/oss-cad-suite` |

La placa fue reconocida con `openFPGALoader --detect`, idcode `0x100481b`, GW1N(R)-9C.

## 3. Diseño de partida

### `blink/top.v`

```verilog
module top (
    input sys_clk,          // clk input
    input sys_rst_n,        // reset input
    output reg [5:0] led    // 6 LEDS pin
);

reg [23:0] counter;

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        counter <= 24'd0;
    else if (counter < 24'd1349_9999)       // 0.5s delay
        counter <= counter + 1'b1;
    else
        counter <= 24'd0;
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        led <= 6'b111110;
    else if (counter == 24'd1349_9999)       // 0.5s delay
        led[5:0] <= {led[4:0],led[5]};
    else
        led <= led;
end

endmodule
```


### `blink/top.cst`

```
IO_LOC  "sys_clk" 52;
IO_PORT "sys_clk" IO_TYPE=LVCMOS33 PULL_MODE=UP;

IO_LOC  "sys_rst_n" 4;
IO_PORT "sys_rst_n" IO_TYPE=LVCMOS18 PULL_MODE=UP;

IO_LOC  "led[0]" 10;
IO_PORT "led[0]" IO_TYPE=LVCMOS18 PULL_MODE=NONE;
IO_LOC  "led[1]" 11;
IO_PORT "led[1]" IO_TYPE=LVCMOS18 PULL_MODE=NONE;
IO_LOC  "led[2]" 13;
IO_PORT "led[2]" IO_TYPE=LVCMOS18 PULL_MODE=NONE;
IO_LOC  "led[3]" 14;
IO_PORT "led[3]" IO_TYPE=LVCMOS18 PULL_MODE=NONE;
IO_LOC  "led[4]" 15;
IO_PORT "led[4]" IO_TYPE=LVCMOS18 PULL_MODE=NONE;
IO_LOC  "led[5]" 16;
IO_PORT "led[5]" IO_TYPE=LVCMOS18 PULL_MODE=NONE;
```

Cada puerto lleva dos líneas. `IO_LOC` indica el pin físico. `IO_PORT` indica el estándar de voltaje y la resistencia interna. 

**Los nombres entre comillas deben coincidir con los puertos del módulo.**

Los pines salen del archivo `examples/tangnano9k.cst` del repositorio de Apicula

## 4. Preparar el entorno

```bash
source ~/oss-cad/oss-cad-suite/environment
cd ~/Escritorio/tesla/Yosys_fpga/blink
yosys
```

El prefijo `(OSS CAD Suite)` en el prompt indica que el entorno está activo.

![Entorno cargado y Yosys iniciado](imgs/02_entorno_source_y_yosys.png)

Yosys toma el directorio actual como base para leer archivos. Si se abre desde otra carpeta, `read_verilog top.v` falla con `File 'top.v' not found`. Esto ocurrió al abrirlo desde `/home/tesla`.

![Yosys abierto desde el home](imgs/01_yosys_inicio_desde_home.png)

Además, el comando `!cd` dentro de Yosys no cambia de directorio, porque cada comando con `!` corre en un subshell que termina al acabar. Hay que salir y abrir Yosys en la carpeta correcta.

![Yosys abierto dentro de blink](imgs/03_yosys_dentro_de_blink.png)

## 5. Síntesis con Yosys

Se ejecuta etapa por etapa para observar qué hace cada una.

```
read_verilog top.v
hierarchy -check -top top
proc
opt
synth_gowin -top top -json top.json
stat
```

### 5.1 `read_verilog` y `hierarchy`

`read_verilog` convierte el Verilog en un árbol interno (AST) y luego en la representación RTLIL. `hierarchy -check -top top` resuelve módulos e instancias, fija `top` como raíz y falla si hay referencias sin resolver.

En la salida, `Top module: \top` y `Removed 0 unused modules` confirman que el diseño tiene un solo módulo y que `top` es la raíz.

![read_verilog y hierarchy](imgs/04_read_verilog_hierarchy.png)

### 5.2 `proc`

Traduce los bloques `always`, que son procesos, en celdas de lógica. Se divide en subpasos.

| Subpaso | Función |
|---|---|
| `PROC_CLEAN`, `PROC_RMDEAD`, `PROC_PRUNE` | Limpian ramas vacías, muertas y asignaciones redundantes. |
| `PROC_INIT` | Extrae valores iniciales. |
| `PROC_ARST` | Detecta resets asíncronos. |
| `PROC_MUX` | Convierte árboles de decisión en multiplexores. |
| `PROC_DFF` | Crea los flip-flops. |

![proc, inicio](imgs/05_proc_inicio.png)

`PROC_ARST` encontró el reset asíncrono `\sys_rst_n` en los dos procesos, el de las líneas 9 y 18 de `top.v`.

![proc, reset asíncrono](imgs/06_proc_rmdead_prune_arst.png)

`PROC_MUX` creó decodificadores para `led[5:0]` y `counter[23:0]`. `PROC_DFF` creó una celda `$adff`, un flip-flop con reset asíncrono, para cada registro.

![proc, multiplexores y flip-flops](imgs/07_proc_mux_dff.png)

### 5.3 `opt`

Optimiza el diseño en pasadas que se repiten hasta que no queda nada por mejorar.

![opt, fusión de celdas](imgs/08_opt_inicio_merge.png)

`OPT_MERGE` fusionó celdas idénticas y eliminó 2. Más abajo, `OPT_DFF` agregó una señal de habilitación (`EN`) al flip-flop de `led`, porque `led` solo cambia cuando el contador llega al tope.

![opt, habilitación del registro led](imgs/09_opt_muxtree_reduce_dff.png)

`OPT_CLEAN` eliminó 3 celdas y 11 cables sin uso, y se repitieron las pasadas.

![opt, limpieza y repetición](imgs/10_opt_clean_rerun.png)

La etapa termina con el mensaje `Finished fast OPT passes. (There is nothing left to do.)`. Enseguida se lanza `synth_gowin`.

![opt terminado, inicio de synth_gowin](imgs/11_opt_fin_y_synth_gowin.png)

### 5.4 `synth_gowin`

Es el flujo completo de síntesis hacia celdas de la familia Gowin. Carga primero la librería de simulación de celdas, `share/yosys/gowin/cells_sim.v`, y luego repite jerarquía, `proc` y chequeos antes de mapear a celdas físicas.

![synth_gowin, jerarquía y proc](imgs/12_synth_gowin_hierarchy_proc.png)

![synth_gowin, chequeo](imgs/13_synth_gowin_proc_check.png)

El resultado queda en `top.json`.

### 5.5 `stat`

Imprime el conteo de recursos.

![stat](imgs/14_stat_celdas.png)

| Celda | Cantidad | Nota |
|---|---|---|
| `ALU` | 48 | Aritmética, usada por el incremento y la comparación. |
| `DFFC` | 24 | Flip-flops con clear. |
| `DFFCE` | 1 | Flip-flop con clear y habilitación. |
| `DFFPE` | 5 | Flip-flops con preset y habilitación. |
| `IBUF` | 2 | Buffers de entrada, `sys_clk` y `sys_rst_n`. |
| `LUT1`, `LUT2`, `LUT4` | 3, 24, 7 | Tablas de búsqueda. |
| `GND` | 1 | Constante. |
| Total | 124 celdas | 3 puertos, 8 bits de puerto. |

### 5.6 Grafo del diseño (opcional)

```
show -format svg -viewer none -prefix top_grafo
```

Escribe `top_grafo.svg` sin abrir ventana. Necesita Graphviz; si no está, usa `-format dot`.

### 5.7 Síntesis en una sola línea

Una vez entendidas las etapas, todo lo anterior se resume en un comando desde la terminal normal.

```bash
yosys -p "read_verilog top.v; synth_gowin -top top -json top.json"
```


## 6. Place and route con nextpnr

```bash
nextpnr-himbaechel --json top.json --write pnr.json \
  --device GW1NR-LV9QN88PC6/I5 \
  --vopt family=GW1N-9C \
  --vopt cst=top.cst \
  --freq 27
```

Parámetros.

| Parámetro | Función |
|---|---|
| `--json` | Netlist de entrada de Yosys. |
| `--write` | Archivo de salida con la colocación y el ruteo. |
| `--device` | Referencia exacta del chip. |
| `--vopt family=GW1N-9C` | Familia del dispositivo, opción propia del backend. |
| `--vopt cst=top.cst` | Archivo de pines. |
| `--freq 27` | Frecuencia objetivo del reloj, en MHz. |

![nextpnr](imgs/15_nextpnr_inicio.png)

En la captura el primer intento falló porque se escribió `nextpnr` y no `nextpnr-himbaechel` (`no se encontró la orden`). El segundo usó el nombre correcto, y nextpnr eligió la microarquitectura `gowin`.

Los mensajes `Info: Cell O_psram_ck[0] not found` y similares son de nivel informativo, no errores. Se refieren a pines de la PSRAM que este diseño no usa.


## 7. Empaquetado con gowin_pack

```bash
gowin_pack -d GW1N-9C -o top.fs pnr.json
```

Genera el bitstream `top.fs`.

![gowin_pack](imgs/16_gowin_pack.png)


## 8. Carga con openFPGALoader

A SRAM, volátil, se pierde al quitar la alimentación.

```bash
openFPGALoader -b tangnano9k top.fs
```

A flash, persistente.

```bash
openFPGALoader -b tangnano9k -f top.fs
```

Secuencia observada con `-f`. Se analiza el archivo, se borran SRAM y flash, y se escribe la flash con barra de progreso.

![Escritura de flash en progreso](imgs/17_openfpgaloader_escribiendo_flash.png)

Al terminar, el cargador verifica con un CRC.

![CRC correcto](imgs/18_openfpgaloader_crc_success.png)



## Fuentes


- Archivo de pines del ejemplo de Tang Nano 9K, https://raw.githubusercontent.com/YosysHQ/apicula/master/examples/tangnano9k.cst
- Yosys, https://yosyshq.readthedocs.io/projects/yosys/en/latest/
- Project Apicula, https://github.com/YosysHQ/apicula
- openFPGALoader, https://trabucayre.github.io/openFPGALoader/
- Wiki de la placa, https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html
