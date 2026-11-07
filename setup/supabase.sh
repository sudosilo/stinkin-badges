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

echo "Allowing logins to return to the badge tool."
SITE="https://pajamastan-badge-tool.vercel.app"
CUR=$(curl -s "$API/config/auth" -H "Authorization: Bearer $TOKEN" | grep -o '"uri_allow_list":"[^"]*"' | sed 's/"uri_allow_list":"//; s/"$//')
case ",$CUR," in
  *",$SITE,"*) echo "Already allowed." ;;
  *)
    if [ -z "$CUR" ]; then NEW="$SITE"; else NEW="$CUR,$SITE"; fi
    CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$API/config/auth" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data "{\"uri_allow_list\":\"$NEW\"}")
    if [ "$CODE" != "200" ]; then echo "Return address step failed with code $CODE."; exit 1; fi
    ;;
esac

ANON=$(curl -s "$API/api-keys" -H "Authorization: Bearer $TOKEN" | tr '{' '\n' | grep '"name":"anon"' | sed 's/.*"api_key":"\([^"]*\)".*/\1/')
if [ -z "$ANON" ]; then echo "Could not read the public key."; exit 1; fi

printf 'SUPABASE_URL=https://%s.supabase.co\nSUPABASE_ANON_KEY=%s\n' "$REF" "$ANON" > ~/stinkin-badges-supabase.env
echo "Finished. The two public values are saved in ~/stinkin-badges-supabase.env"
