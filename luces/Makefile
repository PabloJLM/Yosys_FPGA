# Flujo completo para la Tang Nano 9K. Requiere el entorno de OSS CAD Suite activo.
FUENTES = top.v tick_gen.v debounce.v patrones.v
DEVICE  = GW1NR-LV9QN88PC6/I5
FAMILY  = GW1N-9C

all: top.fs

top.json: $(FUENTES)
	yosys -p "read_verilog $(FUENTES); synth_gowin -top top -json top.json"

pnr.json: top.json top.cst
	nextpnr-himbaechel --json top.json --write pnr.json \
	  --device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=top.cst --freq 27

top.fs: pnr.json
	gowin_pack -d $(FAMILY) -o top.fs pnr.json

cargar: top.fs
	openFPGALoader -b tangnano9k top.fs

flash: top.fs
	openFPGALoader -b tangnano9k -f top.fs

clean:
	rm -f top.json pnr.json top.fs

.PHONY: all cargar flash clean
