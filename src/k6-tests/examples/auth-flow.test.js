/**
* Test de flujo de autenticación utilizando helpers de login.js
* Objetivo: Evaluar el rendimiento del flujo de autenticación de usuarios virtuales.
* Escenario: Simular 10 usuarios virtuales que realizan el proceso completo de autenticación, acceso a un endpoint protegido y cierre de sesión durante 1 minuto.
* Métricas clave: Tasa de éxito del login, tiempo de respuesta del endpoint protegido, tasa de errores.
* Resultados esperados: La tasa de éxito del login debe ser superior al 95%.
* Notas adicionales: Este test combina los helpers definidos en `login.js` para simular un flujo completo de autenticación.
*/

import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate } from 'k6/metrics';
import { loginScenario, logoutScenario } from '../../scenarios/login.js';

// Métrica custom para tasa de login exitosos
const loginSuccessRate = new Rate('login_success_rate');

/*
 * Combina los helpers de login.js para simular usuarios
 * iniciando sesión, accediendo a un endpoint protegido y cerrando sesión.
 */
export const options = {
  vus: 10,
  duration: '1m',
  thresholds: {
    'login_success_rate': ['rate>0.95'],
  },
};

export default function () {
  group('auth cycle', () => {
    const token = loginScenario();

    const success = check(token, { 'received token': (t) => t !== null });

    // registrar en la métrica custom
    loginSuccessRate.add(success);

    if (token) {
      const res = http.get('https://test-api.k6.io/private/', {
        headers: { Authorization: `Bearer ${token}` },
      });

      check(res, {
        'private status 200': (r) => r.status === 200,
      });

      sleep(1);
      logoutScenario(token); // cierre de sesión
    }
  });
}
