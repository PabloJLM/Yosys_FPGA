# Blink en Tang Nano 9K con flujo open source resumen xd
desde `blink/`. Instalación del entorno en [INSTALACION.md](../INSTALACION.md).

## Resumen del flujo

![Pasos del flujo](../imgs/flujo_nano.png)


## 1. Entorno

```bash
source ~/oss-cad/oss-cad-suite/environment
cd ~/Escritorio/tesla/Yosys_fpga/blink
yosys
```

Yosys debe abrirse dentro de `blink/`, si no, no encuentra `top.v`.

![Entorno cargado](../imgs/02_entorno_source_y_yosys.png)

![Yosys dentro de blink](../imgs/03_yosys_dentro_de_blink.png)

## 2. Síntesis con Yosys

Dentro del shell de Yosys, un comando a la vez.

```
read_verilog top.v
hierarchy -check -top top
proc
opt
synth_gowin -top top -json top.json
stat
```

![read_verilog y hierarchy](../imgs/04_read_verilog_hierarchy.png)

![proc](../imgs/05_proc_inicio.png)

![opt](../imgs/08_opt_inicio_merge.png)

![synth_gowin](../imgs/11_opt_fin_y_synth_gowin.png)

![stat](../imgs/14_stat_celdas.png)

## 3. Place and route

Necesitas `top.cst` con los pines. Luego, en la terminal normal.

```bash
nextpnr-himbaechel --json top.json --write pnr.json \
  --device GW1NR-LV9QN88PC6/I5 \
  --vopt family=GW1N-9C \
  --vopt cst=top.cst \
  --freq 27
```

![nextpnr](../imgs/15_nextpnr_inicio.png)

Resultado obtenido, frecuencia máxima de 142,82 MHz.

## 4. Empaquetado

```bash
gowin_pack -d GW1N-9C -o top.fs pnr.json
```

Los avisos de Numpy, Msgspec y fastcrc son inofensivos.

![gowin_pack](../imgs/16_gowin_pack.png)

## 5. Carga

A SRAM, volátil.

```bash
openFPGALoader -b tangnano9k top.fs
```

A flash, persistente.

```bash
openFPGALoader -b tangnano9k -f top.fs
```

![Escribiendo flash](../imgs/17_openfpgaloader_escribiendo_flash.png)

![CRC correcto](../imgs/18_openfpgaloader_crc_success.png)
