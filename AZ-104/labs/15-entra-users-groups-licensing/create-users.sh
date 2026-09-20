#!/usr/bin/env bash
# AZ-104 Lab 15: Microsoft Entra Users, Groups & Licensing
# Domain: Manage Azure identities and governance — Manage Microsoft Entra users and groups
# Cost: $0 — Entra ID user objects carry no charge on their own.
#
# Bulk-creates a handful of demo users with az ad user create, the CLI-native
# alternative to the portal's "Bulk create users" CSV upload (both exist —
# see the lab README). Requires User Administrator (or higher) in the tenant.
#
# Run:
#   TENANT_DOMAIN=<yourtenant>.onmicrosoft.com ./create-users.sh

set -euo pipefail

: "${TENANT_DOMAIN:?Set TENANT_DOMAIN, e.g. TENANT_DOMAIN=contoso.onmicrosoft.com ./create-users.sh}"
TEMP_PASSWORD="ChangeMe!$(date +%s | tail -c 5)"

USERS=(
  "AZ104 Lab15 Sales One|az104lab15-sales1"
  "AZ104 Lab15 Sales Two|az104lab15-sales2"
  "AZ104 Lab15 Sales Three|az104lab15-sales3"
)

for entry in "${USERS[@]}"; do
  DISPLAY_NAME="${entry%%|*}"
  MAIL_NICKNAME="${entry##*|}"
  UPN="${MAIL_NICKNAME}@${TENANT_DOMAIN}"

  echo "Creating ${UPN} ..."
  az ad user create \
    --display-name "${DISPLAY_NAME}" \
    --user-principal-name "${UPN}" \
    --password "${TEMP_PASSWORD}" \
    --force-change-password-next-sign-in true \
    --output table
done

echo "Done. Temp password for all demo users: ${TEMP_PASSWORD}"
echo "Set each user's usage location and department before assigning licenses or testing dynamic group membership — see the lab README."
