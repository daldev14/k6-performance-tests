import http from 'k6/http';
import { check, sleep } from 'k6';

// Configuración de pruebas de estrés: encuentra puntos de ruptura.
export const options = {
  scenarios: {
    stress_test: {
      executor: 'ramping-arrival-rate',
      startRate: 10,
      timeUnit: '1s',
      preAllocatedVUs: 50,
      maxVUs: 500,
      stages: [
        { duration: '2m', target: 10 }, // Por debajo de la carga normal
        { duration: '5m', target: 50 }, // Carga normal
        { duration: '2m', target: 100 }, // Punto de ruptura inicial (Around breaking point)
        { duration: '5m', target: 200 }, // Punto de ruptura alto (Beyond breaking point)
        { duration: '2m', target: 300 }, // Punto de ruptura extremo (High stress)
        { duration: '5m', target: 300 }, // Punto de ruptura extremo sostenido (Sustained high stress)
        { duration: '2m', target: 0 }, // Recuperación (Recovery)
      ],
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.5'], // Menos del 50% de las solicitudes deben fallar (en estrés, se espera más errores)
    http_req_duration: ['p(95)<3000'], // 95% de las solicitudes deben responder en menos de 3000ms (en estrés, se espera tiempos más altos)
  },
};

const BASE_URL = __ENV.BASE_URL || 'https://test-api.k6.io';

export default function () {
  const res = http.get(`${BASE_URL}/public/crocodiles/`);

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time acceptable': (r) => r.timings.duration < 3000,
  });
}
