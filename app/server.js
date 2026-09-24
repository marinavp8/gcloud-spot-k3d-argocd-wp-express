import express from 'express';
import os from 'node:os';

const app = express();
const port = Number(process.env.PORT) || 3000;
const version = process.env.APP_VERSION || 'dev';
const startedAt = new Date();

app.disable('x-powered-by');
app.use(express.json());

app.get('/', (req, res) => {
  res.type('html').send(`<!doctype html>
<html lang="es">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Express en k3d</title>
<style>body{font-family:system-ui,sans-serif;max-width:40rem;margin:3rem auto;padding:0 1rem;line-height:1.5}
code{background:#eee;padding:.1rem .3rem;border-radius:4px}</style></head>
<body>
<h1>Express en k3d + ArgoCD</h1>
<p>Desplegado por ArgoCD en una VM Spot de GCP.</p>
<ul>
  <li>Versión: <code>${version}</code></li>
  <li>Pod: <code>${os.hostname()}</code></li>
  <li>Arrancado: <code>${startedAt.toISOString()}</code></li>
</ul>
<p>API: <a href="/api/info">/api/info</a> · <a href="/healthz">/healthz</a></p>
</body></html>`);
});

app.get('/api/info', (req, res) => {
  res.json({ version, pod: os.hostname(), node: process.version, startedAt, uptime: process.uptime() });
});

app.get('/healthz', (req, res) => res.json({ status: 'ok' }));

const server = app.listen(port, () => console.log(`express-k3d ${version} escuchando en :${port}`));

// Kubernetes manda SIGTERM al parar el pod: cerrar conexiones antes de salir
for (const sig of ['SIGTERM', 'SIGINT']) {
  process.on(sig, () => server.close(() => process.exit(0)));
}
