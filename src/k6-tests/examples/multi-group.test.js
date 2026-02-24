import http from 'k6/http';
import { group, check, sleep } from 'k6';

/*
 * Simula un usuario que navega varias secciones de una web.
 * Cada grupo representa un “paso” del flujo.
 */
export const options = {
  vus: 3,
  duration: '1m',
};

export default function () {
  group('homepage', () => {
    const res = http.get('https://test-api.k6.io/');
    check(res, { 'homepage 200': (r) => r.status === 200 });
    sleep(1);
  });

  group('search products', () => {
    const res = http.get('https://test-api.k6.io/search?q=kitten');
    check(res, { 'search ok': (r) => r.status === 200 });
    sleep(2);
  });

  group('add to cart', () => {
    const payload = JSON.stringify({ item: 'crocodile', qty: 1 });
    const res = http.post('https://test-api.k6.io/cart', payload, {
      headers: { 'Content-Type': 'application/json' },
    });
    check(res, { 'added item': (r) => r.status === 201 });
  });
}
