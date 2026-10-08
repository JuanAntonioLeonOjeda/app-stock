// Captura transcripciones reales del canal de gráficos de TradingView como
// fixtures de test (Node 22+). Uso (desde app/):
//   node tool/capture_tradingview_chart.mjs
// Guarda en test/fixtures/tradingview/: la secuencia de mensajes enviados y
// todos los recibidos, sin interpretar.
import { writeFileSync } from 'node:fs';

const OUT = 'test/fixtures/tradingview';
const frame = (s) => `~m~${s.length}~m~${s}`;
const msg = (m, p) => frame(JSON.stringify({ m, p }));

function capture(symbol, bars, name) {
  return new Promise((resolve) => {
    const session = 'cs_fixture0001';
    const sent = [
      msg('set_auth_token', ['unauthorized_user_token']),
      msg('chart_create_session', [session, '']),
      msg('resolve_symbol', [session, 'sds_sym_1', `={"symbol":"${symbol}","adjustment":"splits"}`]),
      msg('create_series', [session, 'sds_1', 's1', 'sds_sym_1', 'D', bars, '']),
    ];
    const received = [];
    const ws = new WebSocket('wss://data.tradingview.com/socket.io/websocket', {
      headers: { Origin: 'https://www.tradingview.com', 'User-Agent': 'Mozilla/5.0' },
    });
    const finish = () => {
      writeFileSync(`${OUT}/${name}.json`, JSON.stringify({ symbol, sent, received }, null, 1));
      console.log(name, 'recibidos:', received.length);
      try { ws.close(); } catch {}
      resolve();
    };
    const timer = setTimeout(finish, 8000);
    ws.onopen = () => sent.forEach((m) => ws.send(m));
    ws.onmessage = (e) => {
      const data = String(e.data);
      received.push(data);
      const heartbeat = data.match(/^~m~\d+~m~(~h~\d+)$/);
      if (heartbeat) ws.send(frame(heartbeat[1]));
      if (data.includes('series_completed') || data.includes('symbol_error') || data.includes('critical_error')) {
        setTimeout(() => { clearTimeout(timer); finish(); }, 400);
      }
    };
  });
}

await capture('TSE:7974', 30, 'chart_tse_7974');
await capture('NASDAQ:ZZZZZZQ', 30, 'chart_unknown_symbol');
process.exit(0);
