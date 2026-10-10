// Experimental relay for integration tests. No identity/game-world authority;
// DO NOT expose publicly until secure authentication, per-user permissions,
// proximity checks, encryption, moderation and proper rate limiting exist.
const { WebSocketServer, WebSocket } = require('ws');
const port = Number(process.env.PORT || 8082);
const server = new WebSocketServer({ port, host: process.env.HOST || '127.0.0.1', maxPayload: 1500 });
const peers = new Set();
server.on('connection', (ws, req) => {
  const room = String(req.headers['x-lexus-voice-room'] || '').slice(0, 64);
  if (!room || room !== 'cidade_lexus_demo') return ws.close(1008, 'Unknown room');
  let lastWindow = Date.now(); let packets = 0;
  ws.room = room; peers.add(ws);
  ws.on('message', (payload, binary) => {
    if (!binary || payload.length !== 640) return;
    const now = Date.now();
    if (now - lastWindow >= 1000) { lastWindow = now; packets = 0; }
    if (++packets > 55) return ws.close(1008, 'Rate limited');
    for (const p of peers) if (p !== ws && p.readyState === WebSocket.OPEN && p.room === room && p.bufferedAmount < 128000) p.send(payload, { binary: true });
  });
  ws.on('close', () => peers.delete(ws));
  ws.on('error', () => peers.delete(ws));
});
console.log(`Cidade Lexus EXPERIMENTAL voice relay on 127.0.0.1:${port}`);
