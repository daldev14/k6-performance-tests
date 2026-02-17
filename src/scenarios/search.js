/**
 * Escenario de Búsqueda - Simula búsquedas de productos o contenido
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { authHeaders, randomSleep } from '../lib/helpers.js';
import { API_BASE_URL, ENDPOINTS, HTTP_STATUS } from '../lib/const.js';

/**
 * Realiza una búsqueda simple
 * @param {string} query - Término de búsqueda
 * @param {string} token - Token de autenticación (opcional)
 * @returns {object|null} Resultados de la búsqueda
 */
export function basicSearch(query, token = null) {
  const searchUrl = `${API_BASE_URL}${ENDPOINTS.SEARCH}`;

  const params = {
    q: query,
    limit: 10,
  };

  const headers = token ? authHeaders(token) : { 'Content-Type': 'application/json' };

  const response = http.get(searchUrl, {
    headers,
    params,
  });

  const success = check(response, {
    'search status is 200': (r) => r.status === HTTP_STATUS.OK,
    'search has results': (r) => r.json('results') !== undefined,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(randomSleep(0.5, 2));
  return success ? response.json() : null;
}

/**
 * Realiza una búsqueda avanzada con filtros
 * @param {string} query - Término de búsqueda
 * @param {object} filters - Filtros adicionales (precio, categoría, etc.)
 * @param {string} token - Token de autenticación
 * @returns {object|null} Resultados filtrados
 */
export function advancedSearch(query, filters = {}, token = null) {
  const searchUrl = `${API_BASE_URL}${ENDPOINTS.SEARCH}`;

  const params = {
    q: query,
    limit: 20,
    ...filters,
  };

  const headers = token ? authHeaders(token) : { 'Content-Type': 'application/json' };

  const response = http.get(searchUrl, {
    headers,
    params,
  });

  check(response, {
    'advanced search status is 200': (r) => r.status === HTTP_STATUS.OK,
    'response time < 1s': (r) => r.timings.duration < 1000,
  });

  sleep(randomSleep(1, 3));
  return response.json();
}

/**
 * Simula una secuencia de búsquedas consecutivas (usuario haciendo múltiples búsquedas)
 */
export function searchSequence(token = null) {
  const queries = ['laptop', 'phone', 'tablet', 'headphones', 'charger'];

  queries.forEach((query) => {
    basicSearch(query, token);
  });

  // Búsqueda con filtros
  advancedSearch('laptop', { min_price: 500, max_price: 1500 }, token);
}
