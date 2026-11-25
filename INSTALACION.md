# Instalación del entorno, Tang Nano 9K

## 1. OSS CAD Suite

Trae Yosys, nextpnr-himbaechel, gowin_pack (Apicula) y openFPGALoader en un solo paquete.

Descarga el `.tgz` de Linux x64 más reciente desde https://github.com/YosysHQ/oss-cad-suite-build/releases y extráelo.

```bash
mkdir -p ~/oss-cad
tar -xzf ~/Descargas/oss-cad-suite-linux-x64-*.tgz -C ~/oss-cad
```

Queda en `~/oss-cad/oss-cad-suite`.

## 2. Activar el entorno

En cada terminal nueva.

```bash
source ~/oss-cad/oss-cad-suite/environment
```

El prompt muestra el prefijo `(OSS CAD Suite)` cuando está activo.

## 3. Verificar las herramientas

```bash
yosys -V
nextpnr-himbaechel --version
gowin_pack -h
openFPGALoader --Version
```

Ojo, el binario es `nextpnr-himbaechel`, no `nextpnr`.

## 4. Acceso USB a la placa

Sin reglas udev, openFPGALoader solo funciona con `sudo`. Para usarlo como usuario normal.

```bash
wget https://raw.githubusercontent.com/trabucayre/openFPGALoader/master/99-openfpgaloader.rules
sudo cp 99-openfpgaloader.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo usermod -a $USER -G plugdev
```

Cierra sesión y vuelve a entrar para que tome el grupo. Luego, con la placa conectada.

```bash
openFPGALoader --detect
```

Debe reportar idcode `0x100481b`, GW1N(R)-9C.

## 5. Graphviz (opcional)

Solo para generar el grafo del diseño con `show` en Yosys.

```bash
sudo apt install graphviz
```

## Fuentes

- OSS CAD Suite, https://github.com/YosysHQ/oss-cad-suite-build
- openFPGALoader, instalación y udev, https://trabucayre.github.io/openFPGALoader/guide/install.html
- Wiki de la placa, https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html
