# Flujo abierto FPGA a mano, Tang Nano 9K

Placa Tang Nano 9K, chip GW1NR-9C, paquete QN88P, reloj de 27 MHz.

## 0. Entorno

```bash
source ~/oss-cad/oss-cad-suite/environment
cd ~/Escritorio/tesla/Yosys_fpga
```

Verificación rápida.

```bash
yosys -V
nextpnr-himbaechel --version
gowin_pack -h
openFPGALoader --Version
openFPGALoader --detect
```

## 1. Síntesis con Yosys, etapa por etapa

Archivo de entrada, `top.v`, con el módulo `top`, entrada `clk` y salida `led`.

Entra al shell interactivo.

```bash
yosys
```

Dentro de Yosys, un comando a la vez.

```
read_verilog top.v
hierarchy -check -top top
proc
opt
synth_gowin -top top -json top.json
stat
show -format svg -viewer none -prefix top_grafo
```

Qué hace cada uno.

| Comando | Qué hace |
|---|---|
| `read_verilog` | Lee el Verilog y lo convierte en un AST interno. |
| `hierarchy -check -top top` | Resuelve módulos e instancias, fija `top` como raíz y falla si falta algo. |
| `proc` | Traduce los bloques `always` a celdas lógicas, flip-flops y multiplexores. |
| `opt` | Limpia, elimina lógica muerta y simplifica constantes. |
| `synth_gowin` | Corre todo el flujo de síntesis hacia celdas Gowin (LUT4, DFF, ALU) y escribe `top.json`. |
| `stat` | Imprime cuántas celdas de cada tipo usa el diseño. |
| `show` | Genera el grafo del diseño. Con `-viewer none` solo escribe el archivo, sin abrir ventana. |

Nota. `show` necesita `dot` de Graphviz. Si no está en el entorno, usa `-format dot`.

Alternativa en una sola línea, sin interactivo.

```bash
yosys -p "read_verilog top.v; synth_gowin -top top -json top.json"
```

Ver las etapas con `help <comando>` dentro de Yosys.

## 2. Place and route con nextpnr

Primero el archivo de pines, `top.cst`. Confirma los pines en la wiki de Sipeed antes de usarlo.

```
IO_LOC "clk" 52;
IO_PORT "clk" IO_TYPE=LVCMOS33 PULL_MODE=UP;
IO_LOC "led" 10;
IO_PORT "led" IO_TYPE=LVCMOS18 PULL_MODE=UP DRIVE=8;
```

Luego.

```bash
nextpnr-himbaechel --json top.json --write pnr.json \
  --device GW1NR-LV9QN88PC6/I5 \
  --vopt family=GW1N-9C \
  --vopt cst=top.cst
```

Revisa al final del log que la frecuencia máxima sea mayor a 27 MHz. Para que nextpnr use ese objetivo, agrega `--freq 27`.

## 3. Empaquetado con gowin_pack

```bash
gowin_pack -d GW1N-9C -o top.fs pnr.json
```

Los avisos de Numpy y Msgspec son inofensivos.

## 4. Carga con openFPGALoader

A SRAM, volátil, se pierde al quitar la alimentación.

```bash
openFPGALoader -b tangnano9k top.fs
```

A flash, persistente.

```bash
openFPGALoader -b tangnano9k -f top.fs
```

## 5. Makefile

Pendiente, se hace al final, cuando los pasos 1 a 4 funcionen a mano.

## Fuentes

- Yosys, comandos y `synth_gowin`, https://yosyshq.readthedocs.io/projects/yosys/en/latest/
- Project Apicula, uso de nextpnr-himbaechel y gowin_pack, https://github.com/YosysHQ/apicula
- Ejemplos de Apicula para Tang Nano 9K, https://github.com/YosysHQ/apicula/tree/master/examples
- openFPGALoader, https://trabucayre.github.io/openFPGALoader/
- Placa Tang Nano 9K, pines y esquemático, https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html
