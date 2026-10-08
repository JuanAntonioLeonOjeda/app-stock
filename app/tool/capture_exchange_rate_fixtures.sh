#!/usr/bin/env bash
# Captura respuestas reales de tipos de cambio como fixtures de test.
#
# Uso (desde app/):  tool/capture_exchange_rate_fixtures.sh
# Guarda en test/fixtures/exchange_rates/: una respuesta recortada del BCE
# (yen), la de una moneda que no existe, y el CSV del Banco de España recortado
# a su cabecera, unas filas del principio y del final y las líneas de pie.
set -euo pipefail

cd "$(dirname "$0")/.."
out="test/fixtures/exchange_rates"
mkdir -p "$out"
ecb="https://data-api.ecb.europa.eu/service/data/EXR"

curl -s -H "Accept: application/json" \
  "$ecb/D.JPY.EUR.SP00.A?startPeriod=2026-09-21&format=jsondata&detail=dataonly" \
  -o "$out/ecb_jpy.json"
curl -s -H "Accept: application/json" \
  "$ecb/D.SAR.EUR.SP00.A?startPeriod=2026-09-21&format=jsondata&detail=dataonly" \
  -o "$out/ecb_unknown_currency.txt"

curl -s --compressed \
  "https://www.bde.es/webbe/es/estadisticas/compartido/datos/csv/tc_1_1.csv" \
  -o /tmp/tc_full.csv
python3 - "$out" <<'PY'
import sys
out = sys.argv[1]
raw = open('/tmp/tc_full.csv', 'rb').read()
lines = raw.split(b'\r\n') if b'\r\n' in raw else raw.split(b'\n')
head = lines[:6]
data = [l for l in lines[6:] if l[:1] == b'"' and l[1:3].isdigit()]
tail = [l for l in lines[6:] if l.startswith((b'"FUENTE"', b'"NOTAS"'))]
open(f'{out}/bde_tc_1_1.csv', 'wb').write(
    b'\r\n'.join(head + data[:3] + data[-10:] + tail) + b'\r\n')
PY
echo "Fixtures guardadas en $out"
