#!/bin/bash

# =========================
# IP-Blocklist Importer für UFW + ipset
# =========================

### EINSTELLUNGEN ###
BLOCKLIST_URL="https://domain.tld/blocklists/all.txt"
IPSET_NAME_V4="blocked_ips_v4"
IPSET_NAME_V6="blocked_ips_v6"
TMP_FILE="/tmp/blocklist.txt"

# =========================
# Hilfsfunktionen
# =========================
log()    { echo -e "\e[34m🔹 $1\e[0m"; }
ok()     { echo -e "\e[32m✅ $1\e[0m"; }
warn()   { echo -e "\e[33m⚠️  $1\e[0m"; }
error()  { echo -e "\e[31m❌ $1\e[0m"; exit 1; }

add_ufw_rule() {
    local FILE=$1
    local RULE=$2
    if ! grep -Fxq "$RULE" "$FILE"; then
        log "Füge Regel in $FILE ein: $RULE"
        sed -i "/^COMMIT/i $RULE" "$FILE"
    fi
}

# =========================
# Überprüfe Tools
# =========================
log "Überprüfe benötigte Tools ..."
for tool in ipset iptables ip6tables curl ufw; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        error "$tool nicht gefunden. Bitte installieren."
    else
        ok "$tool gefunden"
    fi
done

# =========================
# Lade IP-Blockliste
# =========================
log "Lade IP-Blockliste von $BLOCKLIST_URL ..."
curl -sSf "$BLOCKLIST_URL" -o "$TMP_FILE" || error "Fehler beim Herunterladen der Blockliste"
ok "IP-Liste erfolgreich heruntergeladen."

# =========================
# Erstelle ipset-Listen
# =========================
log "Bereite ipset-Listen vor ..."
ipset create $IPSET_NAME_V4 hash:net -exist || error "Konnte $IPSET_NAME_V4 nicht erstellen"
ipset create $IPSET_NAME_V6 hash:net family inet6 -exist || error "Konnte $IPSET_NAME_V6 nicht erstellen"
ok "ipset-Listen erstellt."

# =========================
# Füge IPs hinzu
# =========================
log "Füge IP-Adressen hinzu ..."
count_v4=0
count_v6=0
while read -r ip; do
    [[ "$ip" =~ ^#.*$ || -z "$ip" ]] && continue
    if [[ "$ip" == *:* ]]; then
        ipset add $IPSET_NAME_V6 "$ip" -exist || warn "Konnte IPv6 nicht hinzufügen: $ip"
        ((count_v6++))
    else
        ipset add $IPSET_NAME_V4 "$ip" -exist || warn "Konnte IPv4 nicht hinzufügen: $ip"
        ((count_v4++))
    fi
done < "$TMP_FILE"
ok "$count_v4 IPv4- und $count_v6 IPv6-Adressen wurden hinzugefügt."

# =========================
# UFW Integration
# =========================
log "Integriere ipset-Regeln in UFW ..."
UFW_V4_RULE="-A INPUT -m set --match-set $IPSET_NAME_V4 src -j DROP"
UFW_V6_RULE="-A INPUT -m set --match-set $IPSET_NAME_V6 src -j DROP"

add_ufw_rule "/etc/ufw/before.rules" "$UFW_V4_RULE"
add_ufw_rule "/etc/ufw/before6.rules" "$UFW_V6_RULE"

ufw reload && ok "UFW wurde erfolgreich neu geladen."

# =========================
# Ausgabe
# =========================
ok "Gesamtanzahl IPv4 in '$IPSET_NAME_V4': $(ipset list $IPSET_NAME_V4 | grep -c '^')"
ok "Gesamtanzahl IPv6 in '$IPSET_NAME_V6': $(ipset list $IPSET_NAME_V6 | grep -c '^')"
ok "Fertig. Regeln aktiv & in UFW integriert."

exit 0
