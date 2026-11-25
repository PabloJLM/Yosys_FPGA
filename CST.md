# Cómo hacer tu propio archivo de pines (.cst)

El `.cst` le dice a nextpnr a qué pin físico de la FPGA va cada puerto del módulo principal y con qué características eléctricas. 

Sin él, nextpnr no sabe dónde están el reloj, los botones ni los LEDs de la placa.


## 1. Sintaxis

Cada puerto lleva dos líneas.

```
IO_LOC  "sys_clk" 52;
IO_PORT "sys_clk" IO_TYPE=LVCMOS33 PULL_MODE=UP;
```

| Línea | Qué indica |
|---|---|
| `IO_LOC "puerto" pin;` | El pin físico del chip. |
| `IO_PORT "puerto" atributos;` | Estándar de voltaje, resistencia interna y corriente. |

Los comentarios empiezan con `//`. Cada línea termina en `;`.

### Atributos de `IO_PORT`

| Atributo | Valores | Uso |
|---|---|---|
| `IO_TYPE` | `LVCMOS33`, `LVCMOS25`, `LVCMOS18` | Voltaje del pin: 3,3 V, 2,5 V o 1,8 V. |
| `PULL_MODE` | `UP`, `DOWN`, `NONE` | Resistencia interna. `UP` para botones a tierra, `NONE` para salidas. |
| `DRIVE` | `4`, `8`, `12`, ... | Corriente de salida en mA. Opcional. |

### Buses

Un puerto de varios bits se asigna bit por bit, con el índice entre corchetes.

```
IO_LOC  "led[0]" 10;
IO_PORT "led[0]" IO_TYPE=LVCMOS18 PULL_MODE=NONE;
IO_LOC  "led[1]" 11;
IO_PORT "led[1]" IO_TYPE=LVCMOS18 PULL_MODE=NONE;
```

## 2. Paso a paso

### 2.1 Lista los puertos de tu módulo

Los nombres en el `.cst` deben ser exactamente los del módulo principal, el que pasas a `-top`. Los puertos de submódulos no van.

```verilog
module top (
    input        sys_clk,
    input        sys_rst_n,
    input        btn_n,
    output [5:0] led
);
```

### 2.2 Busca el pin de cada uno

El pin depende de cómo está cableada la placa. Fuentes, en orden de comodidad.

1. El ejemplo de Apicula para la placa, `examples/tangnano9k.cst` en https://github.com/YosysHQ/apicula.
2. La wiki y el esquemático de Sipeed, https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html.

Pines de la Tang Nano 9K usados en este repositorio.

| Señal | Pin | Voltaje | Nota |
|---|---|---|---|
| Reloj 27 MHz | 52 | 3,3 V | |
| Botón S1 | 4 | 1,8 V | Activo en bajo, usado como reset. |
| Botón S2 | 3 | 1,8 V | Activo en bajo. |
| LEDs 0 a 5 | 10, 11, 13, 14, 15, 16 | 1,8 V | Encienden con 0. |

### 2.3 Elige el voltaje según el banco

Los pines de la FPGA se agrupan en bancos, y la placa alimenta cada banco con un voltaje fijo. El `IO_TYPE` debe coincidir con ese voltaje, que sale del esquemático. En la Tang Nano 9K los LEDs y botones están en un banco de 1,8 V, por eso usan `LVCMOS18`, y el reloj en uno de 3,3 V.

nextpnr no avisa si te equivocas de voltaje, el diseño compila igual. Revisa el esquemático.

### 2.4 Pon la resistencia interna

- Botones que conectan a tierra al presionar: `PULL_MODE=UP`, así el pin lee 1 cuando está suelto.
- Salidas como LEDs: `PULL_MODE=NONE`.

### 2.5 Pruébalo con nextpnr

Corre el place and route 
## 3. Nota
- El ejemplo de Apicula se puede copiar entero aunque no uses todos los pines.
(Aunque no es recomendable para aprender )


-  A diferencia del IDE, ahi se hace interactivamente con la GUI (es mas pesado)

