# k6 Performance Testing Project

Proyecto de pruebas de rendimiento utilizando [k6](https://k6.io/).

## 🛠 Instalación

[Guía de instalación K6 Oficial](https://grafana.com/docs/k6/latest/set-up/install-k6/)

### Windows

Para realizar la instalación de **K6 en windows** tenemos varias formas:

#### Windows Package Manager (Winget) - RECOMENDADO

Asegurece de tener instalado winget para ello mediante el CMD ejecutar el siguiente comando. En caso de no tenerlo instalado puede descargarlo desde el [repositorio oficial](https://github.com/microsoft/winget-cli/releases).

```bash
winget
```

Eejecutar el siguiente comando para instalar K6.

```cmd
winget install k6 --source winget
```

_El proceso de descarga e instalación es automático._

#### Binario .exe

Entre al siguiente [enlace](https://grafana.com/docs/k6/latest/set-up/install-k6/#windows) para descargar el instalador.

### Linux

Para instalar k6 en Linux ejecute los siguientes comandos:

```bash
sudo gpg -k
```

```bash
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
```

```bash
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
```

```bash
sudo apt-get update && sudo apt-get install k6
```

## Uso

### Ejecutar prueba powershell (script)

```bash
./run-test.ps1
```

### Ejecutar prueba cmd (script)

```bash
./run-test.bat
```

### Ejecutar prueba bash (script)

```bash
./run-test.sh
```

### Ejecutar prueba (comando k6)

```bash
k6 run src/k6-tests/example.test.js
```

### Generar reporte HTML

```bash
k6 run --out json=reports/results.json src/k6-tests/example.test.js
```

### Ejecutar con múltiples VUs rápidamente

```bash
k6 run --vus 10 --duration 30s src/k6-tests/example.test.js
```
