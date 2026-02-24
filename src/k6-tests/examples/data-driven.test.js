import http from 'k6/http';
import { check } from 'k6';
import { SharedArray } from 'k6/data';

/*
 * Carga usuarios desde un JSON/CSV y lanza peticiones GET
 * Ideal para pruebas funcionales con multitud de datos.
 */
const users = new SharedArray('users', function () {
  return JSON.parse(open(__ENV.USER_DATA || 'data/data.json'));
});

export const options = {
  vus: 20,
  iterations: users.length,
};

export default function () {
  const user = users[__ITER % users.length];
  const res = http.get(`https://test-api.k6.io/user/${user.id}/profile`);

  check(res, {
    'status 200': (r) => r.status === 200,
  });
}
