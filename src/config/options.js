/**
 * Configuración de opciones de ejecución para k6
 * Incluye diferentes escenarios: prueba rápida, carga normal, estrés
 */

export const quickTest = {
  vus: 5,
  duration: '10s',
  thinkTime: '1s',
};

export const normalLoad = {
  stages: [
    { duration: '1m', target: 10 },
    { duration: '3m', target: 20 },
    { duration: '2m', target: 0 },
  ],
};

export const stressTest = {
  stages: [
    { duration: '2m', target: 50 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 200 },
    { duration: '5m', target: 0 },
  ],
};

export const soakTest = {
  vus: 30,
  duration: '30m',
};

export const baseOptions = {
  nocolor: false,
  ext: {
    loadimpact: {
      projectID: 0,
      name: 'k6-performance-tests',
    },
  },
};
