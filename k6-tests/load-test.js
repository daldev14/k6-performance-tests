import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { SharedArray } from 'k6/data';

// Configuración del test
export const options = {
  scenarios: {
    load_test: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 50 },   // Aumento gradual de carga (Ramp up)
        { duration: '5m', target: 50 },   // Carga sostenida (Sustained load)
        { duration: '2m', target: 100 },  // Carga máxima (Peak load)
        { duration: '5m', target: 100 },  // Pico sostenido (Sustained peak)
        { duration: '2m', target: 0 },    // Disminución gradual de carga (Ramp down)
      ],
      gracefulRampDown: '30s',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],        // Menos del 1% de las solicitudes deben fallar
    http_req_duration: ['p(99)<1500'],     // 99% de las solicitudes deben responder en menos de 1500ms
  },
};

const BASE_URL = __ENV.BASE_URL || 'https://test-api.k6.io';

export default function () {
  group('API Endpoints', function () {
    // Lista de endpoints
    group('Lista de endpoints', function () {
      const listRes = http.get(`${BASE_URL}/public/crocodiles/`);
      check(listRes, {
        'list status 200': (r) => r.status === 200,
      });
    });

    // Obtener un recurso específico
    group('Obtener un recurso específico', function () {
      const singleRes = http.get(`${BASE_URL}/public/crocodiles/1/`);
      check(singleRes, {
        'status is 200': (r) => r.status === 200,
        'has correct id': (r) => r.json('id') === 1,
      });
    });
  });

  sleep(Math.random() * 3 + 1); // Pausa aleatoria entre 1 y 4 segundos para simular comportamiento realista
}
