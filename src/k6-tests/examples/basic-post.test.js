/**
* Test de rendimiento para la creación de un nuevo recurso (POST)
* Objetivo: Evaluar el rendimiento de la API al crear nuevos recursos bajo una carga moderada de usuarios virtuales.
* Escenario: Simular 5 usuarios virtuales que realizan solicitudes POST a la API para crear nuevos recursos durante un período de 20 segundos.
* Métricas clave: Tiempo de respuesta, tasa de errores, rendimiento bajo carga.
* Resultados esperados: La mayoría de las solicitudes deben responder en menos de 800ms, y la tasa de errores debe ser inferior al 5%.
*/

import http from 'k6/http';
import { check, sleep } from 'k6';

// Configuración del test
export const options = {
  vus: 5, // Número de usuarios virtuales
  duration: '20s', // Duración total del test
  thresholds: {  // Definición de umbrales para evaluar el rendimiento
    http_req_duration: ['p(90)<800'], // 90% de las solicitudes deben responder en menos de 800ms
    http_req_failed: ['rate<0.05'], // Menos del 5% de las solicitudes deben fallar
  },
};

const BASE_URL = __ENV.BASE_URL || 'https://test-api.k6.io';

export default function () {

  // Payload para la solicitud POST,
  const payload = JSON.stringify({
    name: `test-${__VU}-${__ITER}`,
    age: 5,
  });

  // Configuración de los headers para la solicitud POST
  const params = {
    headers: { 'Content-Type': 'application/json' },
  };

  // Realizamos una solicitud POST a la API para crear un nuevo recurso
  const res = http.post(`${BASE_URL}/public/crocodiles/`, payload, params);

  // Comprobaciones (Assertions) para validar la respuesta
  check(res, {
    'created (201)': (r) => r.status === 201,
    'body has id': (r) => r.json('id') !== undefined,
  });

  // Pausa de 1 segundo entre cada iteración para simular un comportamiento más realista
  sleep(1);
}
