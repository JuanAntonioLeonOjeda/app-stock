#!/usr/bin/env bash
# Captura respuestas reales de TradingView como fixtures de test.
#
# Uso (desde app/):  tool/capture_tradingview_fixtures.sh
# Pide al scanner exactamente los campos de tradingview_fields.dart. Sin clave
# y sin límite diario conocido; aun así, no lo lances en bucle.
set -euo pipefail

cd "$(dirname "$0")/.."
out="test/fixtures/tradingview"
fields_file="lib/features/analisis_accion/infrastructure/adapters/tradingview_fields.dart"
mkdir -p "$out"

python3 - "$fields_file" "$out" <<'PY'
import json, re, sys, urllib.request

fields_file, out = sys.argv[1], sys.argv[2]
columns = re.findall(r"^  '([^']+)',", open(fields_file, encoding="utf-8").read(), re.M)
ua = {"User-Agent": "Mozilla/5.0"}

def scan(tickers):
    request = urllib.request.Request(
        "https://scanner.tradingview.com/global/scan",
        json.dumps({"symbols": {"tickers": tickers}, "columns": columns}).encode(),
        {**ua, "Content-Type": "application/json"},
    )
    return json.load(urllib.request.urlopen(request))

def search(text):
    request = urllib.request.Request(
        f"https://symbol-search.tradingview.com/symbol_search/v3/?text={text}&search_type=stock&start=0",
        headers={**ua, "Origin": "https://www.tradingview.com"},
    )
    return json.load(urllib.request.urlopen(request))

scans = {
    "scan_tse_7974": "TSE:7974",
    "scan_tse_9983": "TSE:9983",
    "scan_bme_ibe": "BME:IBE",
    "scan_nasdaq_aapl": "NASDAQ:AAPL",
    "scan_otc_ntdoy": "OTC:NTDOY",
    "scan_unknown_symbol": "NASDAQ:ZZZZZZQ",
}
for name, ticker in scans.items():
    json.dump(scan([ticker]), open(f"{out}/{name}.json", "w"), ensure_ascii=False, indent=1)
for name, text in {"search_nintendo": "nintendo", "search_no_results": "zzzzqxj"}.items():
    json.dump(search(text), open(f"{out}/{name}.json", "w"), ensure_ascii=False, indent=1)
print("Fixtures guardadas en", out)
PY
