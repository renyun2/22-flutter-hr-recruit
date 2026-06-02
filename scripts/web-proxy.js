'use strict';

const http = require('http');
const net = require('net');
const { URL } = require('url');

const LISTEN_HOST = process.env.WEB_PROXY_HOST || '0.0.0.0';
const LISTEN_PORT = Number(process.env.WEB_PROXY_PORT || 5173);
const FLUTTER_TARGET = process.env.FLUTTER_TARGET || 'http://127.0.0.1:5174';
const BACKEND_TARGET = process.env.BACKEND_TARGET || 'http://127.0.0.1:3009';

function isBackendRoute(url) {
  return url === '/health' || url.startsWith('/api');
}

function buildForwardHeaders(req, target) {
  const headers = { ...req.headers, host: target.host };
  if (req.headers.host) {
    headers['x-forwarded-host'] = req.headers.host;
  }
  headers['x-forwarded-proto'] = req.headers['x-forwarded-proto'] || 'http';
  headers['x-forwarded-for'] = req.headers['x-forwarded-for']
    ? `${req.headers['x-forwarded-for']}, ${req.socket.remoteAddress}`
    : req.socket.remoteAddress || '';
  return headers;
}

function forwardHttp(req, res, targetBase) {
  const target = new URL(req.url, targetBase);
  const proxyReq = http.request(
    {
      hostname: target.hostname,
      port: target.port,
      path: `${target.pathname}${target.search}`,
      method: req.method,
      headers: buildForwardHeaders(req, target),
    },
    (proxyRes) => {
      res.writeHead(proxyRes.statusCode || 502, proxyRes.headers);
      proxyRes.pipe(res);
    },
  );
  proxyReq.on('error', (err) => {
    if (!res.headersSent) {
      res.writeHead(502, { 'Content-Type': 'text/plain; charset=utf-8' });
    }
    res.end(`Bad gateway: ${err.message}`);
  });
  req.pipe(proxyReq);
}

const server = http.createServer((req, res) => {
  const url = req.url || '/';
  forwardHttp(req, res, isBackendRoute(url) ? BACKEND_TARGET : FLUTTER_TARGET);
});

server.on('upgrade', (req, socket, head) => {
  const url = req.url || '/';
  if (isBackendRoute(url)) {
    socket.destroy();
    return;
  }

  const target = new URL(FLUTTER_TARGET);
  const headers = buildForwardHeaders(req, target);
  const proxySocket = net.connect(Number(target.port), target.hostname, () => {
    const headerLines = [`${req.method} ${url} HTTP/${req.httpVersion}`];
    for (const [key, value] of Object.entries(headers)) {
      headerLines.push(`${key}: ${value}`);
    }
    headerLines.push('', '');
    proxySocket.write(`${headerLines.join('\r\n')}`);
    if (head?.length) {
      proxySocket.write(head);
    }
    proxySocket.pipe(socket);
    socket.pipe(proxySocket);
  });

  proxySocket.on('error', () => socket.destroy());
  socket.on('error', () => proxySocket.destroy());
});

server.listen(LISTEN_PORT, LISTEN_HOST, () => {
  console.log(
    `[web-proxy] listening on ${LISTEN_HOST}:${LISTEN_PORT} ` +
      `(app ${FLUTTER_TARGET}, api ${BACKEND_TARGET})`,
  );
});
