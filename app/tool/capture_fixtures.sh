#!/usr/bin/env bash
# Captura respuestas reales de Alpha Vantage como fixtures de test.
#
# Uso (desde app/):  tool/capture_fixtures.sh
# Lee la clave de config/secrets.json (no versionado) y NUNCA la muestra.
# Gasta 9 peticiones de la cuota diaria. Al terminar comprueba que la clave
# no aparece en ningún fixture.
set -euo pipefail

cd "$(dirname "$0")/.."
secrets="config/secrets.json"
out="test/fixtures/alpha_vantage"
pause_seconds=15

if [[ ! -f "$secrets" ]]; then
  echo "Falta $secrets (copia config/secrets.example.json y pon tu clave)." >&2
  exit 1
fi
api_key="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["ALPHA_VANTAGE_API_KEY"])' "$secrets")"
if [[ -z "$api_key" ]]; then
  echo "ALPHA_VANTAGE_API_KEY está vacía en $secrets." >&2
  exit 1
fi

mkdir -p "$out"

# nombre_del_fixture|parámetros de la petición
requests=(
  "overview_ibm|function=OVERVIEW&symbol=IBM"
  "time_series_daily_full_ibm|function=TIME_SERIES_DAILY&symbol=IBM&outputsize=full"
  "income_statement_ibm|function=INCOME_STATEMENT&symbol=IBM"
  "balance_sheet_ibm|function=BALANCE_SHEET&symbol=IBM"
  "cash_flow_ibm|function=CASH_FLOW&symbol=IBM"
  "earnings_ibm|function=EARNINGS&symbol=IBM"
  "symbol_search_inditex|function=SYMBOL_SEARCH&keywords=inditex"
  "symbol_search_no_results|function=SYMBOL_SEARCH&keywords=zzqxwvnotacompany"
  "overview_unknown_symbol|function=OVERVIEW&symbol=NOEXISTE123"
)

for i in "${!requests[@]}"; do
  name="${requests[$i]%%|*}"
  params="${requests[$i]#*|}"
  curl -sS --max-time 60 \
    "https://www.alphavantage.co/query?${params}&apikey=${api_key}" \
    -o "$out/$name.json"
  printf '%-28s %9s bytes  %s\n' "$name" "$(wc -c < "$out/$name.json")" \
    "$(head -c 90 "$out/$name.json" | tr -d '\n' | tr -s ' ')"
  if (( i < ${#requests[@]} - 1 )); then sleep "$pause_seconds"; fi
done

if grep -rlF "$api_key" "$out" > /dev/null; then
  echo "ERROR: la clave aparece en algún fixture. Se borran los capturados." >&2
  for request in "${requests[@]}"; do rm -f "$out/${request%%|*}.json"; done
  exit 1
fi
echo "Listo. La clave no aparece en ningún fixture."
