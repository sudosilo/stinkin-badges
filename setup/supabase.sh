#!/data/data/com.termux/files/usr/bin/bash
REF="$1"
if [ -z "$REF" ]; then echo "Add the reference ID after the script name."; exit 1; fi
TOKEN="$(cat ~/.supabase/access-token 2>/dev/null)"
if [ -z "$TOKEN" ]; then echo "No Supabase login token found on this phone."; exit 1; fi
API="https://api.supabase.com/v1/projects/$REF"
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Adding the badge tables."
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/database/query" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data @"$DIR/tables.json")
if [ "$CODE" != "201" ] && [ "$CODE" != "200" ]; then echo "Tables step failed with code $CODE."; exit 1; fi

echo "Adding the login code to the emails."
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$API/config/auth" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data @"$DIR/email.json")
if [ "$CODE" != "200" ]; then echo "Email step failed with code $CODE."; exit 1; fi

ANON=$(curl -s "$API/api-keys" -H "Authorization: Bearer $TOKEN" | tr '{' '\n' | grep '"name":"anon"' | sed 's/.*"api_key":"\([^"]*\)".*/\1/')
if [ -z "$ANON" ]; then echo "Could not read the public key."; exit 1; fi

printf 'SUPABASE_URL=https://%s.supabase.co\nSUPABASE_ANON_KEY=%s\n' "$REF" "$ANON" > ~/stinkin-badges-supabase.env
echo "Finished. The two public values are saved in ~/stinkin-badges-supabase.env"
