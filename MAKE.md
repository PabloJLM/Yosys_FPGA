# Automatizar el flujo con make

Correr Yosys, nextpnr, gowin_pack y openFPGALoader a mano sirve para entender cada etapa. 

Una vez entendidas, `make` las encadena en un solo comando y solo repite las que hacen falta.

Requisitos en [INSTALACION.md](INSTALACION.md). 

Ejemplo completo en [luces/Makefile](luces/Makefile).

## 1. Uso

Desde la carpeta del proyecto, con el entorno activo.

```bash
source ~/oss-cad/oss-cad-suite/environment
cd luces
make          # síntesis, place and route y empaquetado, genera top.fs
make cargar   # a SRAM, volátil
make flash    # a flash, persistente
make clean    # borra los archivos generados
```

## 2. Cómo funciona

Un Makefile es una lista de reglas. Cada regla dice qué archivo se produce, de qué archivos depende y con qué comando.

```make
objetivo: dependencias
	comando
```

En nuestro flujo, cada etapa es una regla y la salida de una es la dependencia de la siguiente.

```make
top.json: $(FUENTES)
	yosys -p "read_verilog $(FUENTES); synth_gowin -top top -json top.json"

pnr.json: top.json top.cst
	nextpnr-himbaechel --json top.json --write pnr.json \
	  --device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=top.cst --freq 27

top.fs: pnr.json
	gowin_pack -d $(FAMILY) -o top.fs pnr.json
```

| Regla | Depende de | Equivale a |
|---|---|---|
| `top.json` | los `.v` | Síntesis con Yosys |
| `pnr.json` | `top.json`, `top.cst` | Place and route con nextpnr |
| `top.fs` | `pnr.json` | Empaquetado con gowin_pack |
| `cargar`, `flash` | `top.fs` | Carga con openFPGALoader |

Al pedir `make top.fs`, make sigue la cadena hacia atrás y ejecuta lo necesario en orden.

### Solo rehace lo que cambió

make compara las fechas de modificación. Si una dependencia es más nueva que el objetivo, rehace el objetivo y todo lo que viene después.

- Cambias un `.v`: repite las tres etapas.
- Cambias solo `top.cst`: se salta Yosys y repite nextpnr y gowin_pack.
- No cambias nada: `make: No se hace nada para 'all'.`

Para ver qué haría sin ejecutar nada, `make -n`. Para forzar todo, `make -B`.

### Variables

Arriba del Makefile van los valores que cambian entre proyectos.

**NOTA: Esto es lo mas importante!**

```make
FUENTES = top.v tick_gen.v debounce.v patrones.v
DEVICE  = GW1NR-LV9QN88PC6/I5
FAMILY  = GW1N-9C
```

`$(FUENTES)` se reemplaza por su valor en cada comando.

### Objetivos que no son archivos

```make
all: top.fs
.PHONY: all cargar flash clean
```

`all` es el primer objetivo, por eso es el que corre con `make` sin argumentos. `.PHONY` marca los objetivos que no producen un archivo con ese nombre, para que siempre se ejecuten aunque exista un archivo llamado, por ejemplo, `clean`.

## 3. Reusar el Makefile en otro proyecto

1. Copia `luces/Makefile` a la carpeta nueva.
2. Pon tus archivos en `FUENTES`.
3. Si el módulo principal no se llama `top`, cambia `-top top` en la regla de `top.json`.
4. Crea el `top.cst`, ver [CST.md](CST.md).

Para otra placa Gowin cambian `DEVICE`, `FAMILY` y el `-b` de openFPGALoader.

## 4. Errores comunes

| Mensaje | Causa |
|---|---|
| `*** falta un separador.  Alto.` | El comando está sangrado con espacios. make exige un tabulador al inicio de cada comando. |
| `yosys: not found` y `Error 127` | No se activó el entorno de OSS CAD Suite en esa terminal. make no lo activa solo. |
| `make: No se hace nada para 'all'.` | No es un error, todo está al día. |

Si una etapa falla, make se detiene ahí y no corre las siguientes.
