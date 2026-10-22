#!/usr/bin/env bash
set -euo pipefail
echo "=== ENV ==="; env | sort | head -40
echo "=== OIDC ==="; OIDC=$(curl -sS -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=api://AzureADTokenExchange" | python3 -c "import json,sys;print(json.load(sys.stdin)['value'])"); echo "LEN=${#OIDC}"
for SCOPE in https://management.azure.com/.default https://storage.azure.com/.default https://vault.azure.net/.default; do
  echo "=== TOKEN $SCOPE ==="; T=$(curl -sS -X POST "https://login.microsoftonline.com/$AZURE_TENANT_ID/oauth2/v2.0/token" -d "client_id=$AZURE_CLIENT_ID" -d "scope=$SCOPE" -d "grant_type=client_credentials" -d "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" -d "client_assertion=$OIDC" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('access_token','ERR:'+str(d)))"); echo "LEN=${#T}"
  if [ "$SCOPE" = "https://management.azure.com/.default" ]; then AZ_TOKEN=$T; fi
  if [ "$SCOPE" = "https://storage.azure.com/.default" ]; then ST_TOKEN=$T; fi
  if [ "$SCOPE" = "https://vault.azure.net/.default" ]; then VT_TOKEN=$T; fi
done
echo "=== RESOURCES ==="; curl -sS -m 30 -H "Authorization: Bearer $AZ_TOKEN" "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resources?api-version=2021-04-01"
echo "=== STORAGE ==="; curl -sS -m 15 -H "Authorization: Bearer $AZ_TOKEN" "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/providers/Microsoft.Storage/storageAccounts?api-version=2023-01-01"
echo "=== VAULTS ==="; curl -sS -m 15 -H "Authorization: Bearer $AZ_TOKEN" "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/providers/Microsoft.KeyVault/vaults?api-version=2022-07-01"
echo "=== WEBAPPS ==="; curl -sS -m 15 -H "Authorization: Bearer $AZ_TOKEN" "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/providers/Microsoft.Web/sites?api-version=2022-03-01"
echo "=== DONE ==="
