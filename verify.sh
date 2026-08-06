#!/bin/bash
# nextupalarm.com — migration verifier. Safe to run at any stage; tells you what's done.
# usage: ./verify.sh
D=nextupalarm.com
g="\033[32m"; r="\033[31m"; y="\033[33m"; n="\033[0m"
ok(){ printf "  ${g}✓${n} %s\n" "$1"; }
no(){ printf "  ${r}✗${n} %s\n" "$1"; }
hm(){ printf "  ${y}•${n} %s\n" "$1"; }

echo
echo "── DNS ─────────────────────────────────────────"
ns=$(dig +short $D NS 2>/dev/null | sort | tr '\n' ' ')
case "$ns" in
  *bluehost*) no "nameservers still Bluehost: $ns" ;;
  "")         no "no nameservers resolving — domain may be in transition" ;;
  *cloudflare*) ok "nameservers moved to Cloudflare" ;;
  *)          hm "nameservers: $ns" ;;
esac

a=$(dig +short $D A 2>/dev/null | sort | tr '\n' ' ')
gh_ips=0
for ip in 185.199.108.153 185.199.109.153 185.199.110.153 185.199.111.153; do
  case "$a" in *$ip*) gh_ips=$((gh_ips+1));; esac
done
if [ "$gh_ips" -eq 4 ]; then ok "all 4 GitHub Pages A records present"
elif [ "$gh_ips" -gt 0 ]; then hm "only $gh_ips/4 GitHub Pages A records — add the rest"
else no "A records not pointing at GitHub Pages: ${a:-none}"; fi

case "$a" in *162.241.224.65*) no "Bluehost A record still present — delete it";; esac

echo
echo "── Site ────────────────────────────────────────"
for p in "/" "/privacy-policy/" "/faq/" "/support/"; do
  code=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 15 "https://$D$p" 2>/dev/null)
  if [ "$code" = "200" ]; then ok "https://$D$p → 200"
  else no "https://$D$p → ${code:-unreachable}"; fi
done
red=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 15 "http://$D/" 2>/dev/null)
[ "$red" = "301" ] || [ "$red" = "308" ] && ok "http → https redirect ($red)" || hm "http returns ${red:-nothing} (expect 301)"

echo
echo "── Certificate ─────────────────────────────────"
# macOS has no timeout(1). curl IS the verification test: a 200 without -k means
# the chain validated. openssl is used only to read the dates.
verified=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 15 "https://$D/" 2>/dev/null)
dates=$(echo | openssl s_client -servername $D -connect $D:443 2>/dev/null \
       | openssl x509 -noout -subject -enddate 2>/dev/null)
if [ "$verified" = "200" ]; then
  ok "certificate valid (chain verified by curl)"
  [ -n "$dates" ] && echo "$dates" | sed 's/^/      /'
elif [ -n "$dates" ]; then
  hm "certificate present but chain did not verify"; echo "$dates" | sed 's/^/      /'
else
  no "no certificate yet (GitHub can take up to an hour after DNS resolves)"
fi

echo
echo "── Email ───────────────────────────────────────"
mx=$(dig +short $D MX 2>/dev/null | sort | tr '\n' ' ')
case "$mx" in
  *mx.cloudflare*) ok "Cloudflare Email Routing MX present" ;;
  "")              no "no MX records — support@$D will bounce" ;;
  *nextupalarm*)   no "MX still points at the dead Bluehost host: $mx" ;;
  *)               hm "MX: $mx" ;;
esac

echo
echo "── The one that matters ────────────────────────"
pp=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 15 "https://$D/privacy-policy/" 2>/dev/null)
if [ "$pp" = "200" ]; then
  printf "  ${g}✓${n} Privacy Policy URL live — App Store guideline 5.1.1(i) exposure cured\n"
else
  printf "  ${r}✗${n} Privacy Policy URL not serving (got ${pp:-nothing}).\n"
  printf "      This is the URL in App Store Connect that cannot be changed without a build.\n"
fi
echo
