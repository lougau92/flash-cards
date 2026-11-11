import assert from 'node:assert/strict';
import {createServer} from 'node:http';
import {readFile} from 'node:fs/promises';
import {resolve, extname, sep} from 'node:path';
import {chromium} from 'playwright';

const root = resolve(process.env.PWA_BUILD_DIR || 'app/build/web');
const base = '/flash-cards/';
const types = {'.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json',
  '.wasm': 'application/wasm', '.png': 'image/png', '.woff2': 'font/woff2'};
const server = createServer(async (request, response) => {
  try {
    const url = new URL(request.url, 'http://localhost');
    if (!url.pathname.startsWith(base)) throw new Error('Outside base path');
    const relative = decodeURIComponent(url.pathname.slice(base.length)) || 'index.html';
    const path = resolve(root, relative);
    if (!path.startsWith(root + sep)) throw new Error('Outside build');
    response.setHeader('Content-Type', types[extname(path)] || 'application/octet-stream');
    response.setHeader('Cache-Control', 'no-store');
    response.end(await readFile(path));
  } catch {
    response.writeHead(404).end();
  }
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
let browser;
try {
  browser = await chromium.launch({headless: true, channel: process.env.PWA_BROWSER_CHANNEL});
  const context = await browser.newContext();
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.addInitScript(() => {
    window.firstFrame = false;
    window.addEventListener('flutter-first-frame', () => { window.firstFrame = true; });
  });
  const url = `http://127.0.0.1:${server.address().port}${base}?pwa-test=1`;
  await page.goto(url);
  await page.waitForFunction(() => window.firstFrame, null, {timeout: 60000});
  await page.waitForFunction(() => Boolean(navigator.serviceWorker.controller), null,
    {timeout: 60000});
  const manifest = await page.evaluate(async () => (await fetch('manifest.json')).json());
  assert.equal(manifest.display, 'standalone');
  assert.equal(manifest.name, 'LLM Summary Lab');
  await context.setOffline(true);
  await page.reload({waitUntil: 'load'});
  await page.waitForFunction(() => window.firstFrame, null, {timeout: 60000});
  const cached = await page.evaluate(async () => {
    const result = await fetch('assets/.env');
    return result.ok;
  });
  assert.ok(cached, 'Bundled configuration must be available offline');
  assert.deepEqual(errors, [], 'App should boot without uncaught errors');
  console.log('PWA passed: subpath boot, standalone manifest, worker control, and offline reload.');
} finally {
  await browser?.close();
  await new Promise(resolve => server.close(resolve));
}
