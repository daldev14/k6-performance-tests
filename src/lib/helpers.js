import { check } from 'k6';
import http from 'k6/http';

/**
 * Constantes de cabeceras HTTP comunes para las solicitudes a la API
 */
export const defaultHeaders = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

/**
 * Crea las cabeceras de autenticación con token Bearer
 * @param {string} token - JWT o Bearer token
 * @returns {object} Objeto de cabeceras con Authorization incluido
 */
export function authHeaders(token) {
  return {
    ...defaultHeaders,
    'Authorization': `Bearer ${token}`,
  };
}

/**
 * Realiza una comprobación de estado en la URL proporcionada
 * @param {string} url - URL para comprobar
 * @returns {boolean} True si status es 200
 */
export function healthCheck(url) {
  const res = http.get(url);
  return check(res, {
    'status is 200': (r) => r.status === 200,
  });
}

/**
 * Genera una cadena aleatoria para datos de prueba
 * @param {number} length - Longitud de la cadena a generar
 * @returns {string} Cadena aleatoria de la longitud especificada
 */
export function randomString(length) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

/**
 * Genera un tiempo de espera (sleep) aleatorio entre un rango de segundos especificado
 * @param {number} min - Minimo de segundos
 * @param {number} max - Maximo de segundos
 * @returns {number} Tiempo de espera en segundos
 */
export function randomSleep(min, max) {
  const duration = Math.random() * (max - min) + min;
  return duration;
}
