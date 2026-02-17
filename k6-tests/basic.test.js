import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Metricas customizadas para medir la tasa de errores y el tiempo de respuesta
const errorRate = new Rate('errors');
const responseTrend = new Trend('response_time');

// Configuración del test
export const options = {
  stages: [
    { duration: '30s', target: 10 }, // Aumenta a 10 usuario en 30 segundos (Ramp up)
    { duration: '1m', target: 10 }, // Mantiene 10 usuario durante 1 minuto (Stay)
    { duration: '30s', target: 0 }, // Disminuye a 0 usuarios en 30 segundos (Ramp down)
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% de las solicitudes deben responder en menos de 500ms
    errors: ['rate<0.1'], // Menos del 10% de las solicitudes deben ser errores
  },
};

// Funcion por defecto ejecutada para cada usuario virtual
export default function () {
  const BASE_URL = __ENV.BASE_URL || 'https://test-api.k6.io';

  // Realizamos un solicitud GET a la API
  const res = http.get(`${BASE_URL}/public/crocodiles/`);

  // Registramos el tiempo de respuesta a la metrica y si hubo un error
  responseTrend.add(res.timings.duration);
  errorRate.add(res.status !== 200);

  // Comprobaciones (Assetions) para validar la respuesta
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'response has data': (r) => {
      const ct = r.headers['Content-Type'] || r.headers['content-type'] || '';
      if (!ct.includes('application/json')) return false;
      try {
        const body = r.json();
        if (Array.isArray(body)) return body.length > 0;
        if (body && typeof body === 'object') return Object.keys(body).length > 0;
        return !!body;
      } catch (e) {
        return false;
      }
    },
  });

  // Pausa de 1 segundo entre cada iteración para simular un comportamiento más realista
  sleep(1);
}
