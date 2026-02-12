# k6 Performance Testing Project

Proyecto de pruebas de rendimiento utilizando [k6](https://k6.io/).

## Estructura del Proyecto

```
k6-performance-tests/
├── k6-tests/            # Scripts de pruebas
│   ├── basic-test.js    # Prueba básica con métricas personalizadas
│   ├── load-test.js     # Prueba de carga con escenarios
│   └── stress-test.js   # Prueba de estrés para encontrar límites
├── scenarios/           # Configuraciones de escenarios reutilizables
├── lib/                 # Funciones auxiliares y utilidades
│   └── helpers.js       # Funciones de ayuda comunes
├── reports/             # Reportes generados
├── run-test.bat
├── run-test.ps1
└── run-test.sh
```

## Requisitos

- k6 instalado ([Guía de instalación](https://k6.io/docs/get-started/installation/))

## Uso

### Ejecutar prueba básica
```bash
k6 run scripts/basic-test.js
```

### Ejecutar con URL personalizada
```bash
k6 run -e BASE_URL=https://tu-api.com scripts/basic-test.js
```

### Ejecutar prueba de carga
```bash
k6 run scripts/load-test.js
```

### Ejecutar prueba de estrés
```bash
k6 run scripts/stress-test.js
```

### Generar reporte HTML
```bash
k6 run --out json=reports/results.json scripts/basic-test.js
```

### Ejecutar con múltiples VUs rápidamente
```bash
k6 run --vus 10 --duration 30s scripts/basic-test.js
```

## Tipos de Pruebas

| Tipo | Script | Descripción |
|------|--------|-------------|
| Smoke | basic-test.js | Verificación rápida de funcionalidad |
| Load | load-test.js | Carga sostenida típica |
| Stress | stress-test.js | Encuentra puntos de quiebre |

## Métricas Principales

- `http_req_duration` - Duración de las peticiones HTTP
- `http_req_failed` - Tasa de fallos
- `errors` - Métrica personalizada de errores
- `response_time` - Tendencia de tiempos de respuesta

## Thresholds

Los umbrales están configurados en cada script. Ejemplo:
- 95% de peticiones < 500ms
- Tasa de error < 10%

## Integración CI/CD

```bash
# Ejemplo para GitHub Actions o similar
k6 run --out json=reports/results.json scripts/load-test.js
# El script retorna código de salida no-cero si fallan los thresholds
```
