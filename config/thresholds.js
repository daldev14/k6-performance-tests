/**
 * Umbrales de rendimiento (thresholds) para validar el éxito de las pruebas
 * Define límites aceptables para métricas de rendimiento
 */

export const defaultThresholds = {
  http_req_duration: ['p(95)<500', 'p(99)<1000'],
  http_req_failed: ['rate<0.1'],
  http_reqs: ['rate>100'],
};

export const strictThresholds = {
  http_req_duration: ['p(95)<300', 'p(99)<500', 'p(99.9)<1000', 'max<2000'],
  http_req_failed: ['rate<0.05'],
  http_reqs: ['rate>500'],
};

export const relaxedThresholds = {
  http_req_duration: ['p(95)<1000', 'p(99)<2000'],
  http_req_failed: ['rate<0.2'],
};

export const apiThresholds = {
  http_req_duration: ['p(90)<200', 'p(95)<500'],
  http_req_failed: ['rate<0.1'],
  checks: ['rate>=0.95'],
};
