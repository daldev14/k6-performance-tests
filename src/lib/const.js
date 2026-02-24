/**
 * Constantes globales para pruebas de rendimiento con k6
 */

// URLs base según el entorno
export const BASE_URL = __ENV.BASE_URL || 'https://test-api.k6.io';
export const API_BASE_URL = __ENV.API_BASE_URL || `${BASE_URL}/api`;

// Endpoints comunes
export const ENDPOINTS = {
  LOGIN: '/login',
  LOGOUT: '/auth/logout',
  USERS: '/users',
  SEARCH: '/search',
  PRODUCTS: '/products',
  HEALTH: '/health',
};

// Códigos HTTP
export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  INTERNAL_ERROR: 500,
};

// Timeouts
export const TIMEOUTS = {
  SHORT: 5000,
  MEDIUM: 10000,
  LONG: 30000,
};

// Datos de prueba
export const TEST_USER = {
  email: 'default',
  password: '12345678',
};

// Códigos de error comunes
export const ERROR_CODES = {
  INVALID_CREDENTIALS: 'INVALID_CREDENTIALS',
  USER_NOT_FOUND: 'USER_NOT_FOUND',
  SERVER_ERROR: 'SERVER_ERROR',
};
