/**
 * Escenario de Login - Simula el proceso de autenticación de usuarios
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { authHeaders, randomSleep } from '../lib/helpers.js';
import { API_BASE_URL, ENDPOINTS, TEST_USER } from '../lib/const.js';

/**
 * Ejecuta un flujo de login y retorna el token de autenticación
 * @returns {string|null} Token JWT si el login es exitoso, null en caso contrario
 */
export function loginScenario() {
  const loginUrl = `${API_BASE_URL}${ENDPOINTS.LOGIN}`;

  const payload = JSON.stringify({
    email: TEST_USER.email,
    password: TEST_USER.password,
  });

  const response = http.post(loginUrl, payload, {
    headers: {
      'Content-Type': 'application/json',
    },
  });

  const success = check(response, {
    'login status is 200': (r) => r.status === 200,
    'login response has token': (r) => r.json('token') !== undefined,
  });

  if (success && response.status === 200) {
    const token = response.json('token');
    sleep(randomSleep(1, 3));
    return token;
  }

  return null;
}

/**
 * Ejecuta un logout/cierre de sesión
 * @param {string} token - Token JWT para autenticar la solicitud de logout
 * @returns {boolean} True si logout fue exitoso
 */
export function logoutScenario(token) {
  const logoutUrl = `${API_BASE_URL}${ENDPOINTS.LOGOUT}`;

  const response = http.post(logoutUrl, null, {
    headers: authHeaders(token),
  });

  const success = check(response, {
    'logout status is 200': (r) => r.status === 200 || r.status === 204,
  });

  sleep(randomSleep(1, 2));
  return success;
}

/**
 * Completa un ciclo completo de login y logout
 */
export function fullAuthCycle() {
  const token = loginScenario();

  if (token) {
    logoutScenario(token);
  }
}
