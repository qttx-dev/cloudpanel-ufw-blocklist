# 🔒 IP-Blocklist Integration via ipset + UFW

Dieses Skript lädt automatisch eine IP-Blocklisten, importiert sie in `ipset` und blockiert den Verkehr via `iptables`/`ip6tables`. Zusätzlich werden die Regeln in UFW integriert, um CloudPanel-kompatibel zu bleiben.

---

## 📦 Voraussetzungen

Das Skript benötigt folgende Tools:

- `curl`
- `ipset`
- `iptables`
- `ip6tables`
- `ufw`

Stelle sicher, dass sie installiert sind (meist vorinstalliert bei Ubuntu 20.04+).

---

## ⚙️ Funktionen

- ✅ Automatischer Download der aktuellen Blockliste
- ✅ Trennung nach IPv4 und IPv6 in `ipset`-Sets
- ✅ Automatische Integration in UFW über `/etc/ufw/before.rules` und `/etc/ufw/before6.rules`
- ✅ Protokollausgabe mit Erfolgen und Warnungen
- ✅ Wiederholbare Ausführung möglich (löscht alte ipsets und Regeln automatisch)

---

## 🚀 Installation & Nutzung

1. Skript herunterladen:

```bash
curl -o /usr/local/bin/update_firewallrules.sh https://raw.githubusercontent.com/qttx-dev/cloudpanel-ufw-blocklist/refs/heads/main/update_firewallrules.sh
chmod +x /usr/local/bin/update_firewallrules.sh
````

2. Skript ausführen:

```bash
sudo /usr/local/bin/update_firewallrules.sh
```

3. (Optional) Automatisch via Cronjob täglich aktualisieren:

```bash
sudo crontab -e
```

Dann hinzufügen:

```cron
@daily /usr/local/bin/update_firewallrules.sh >> /var/log/ipblock.log 2>&1
```

---

## 🔁 UFW-Integration

Das Skript prüft automatisch, ob die `ipset`-Regeln bereits in UFW eingebunden sind. Falls nicht, werden folgende Zeilen in die UFW-Konfigurationsdateien eingefügt:

* `/etc/ufw/before.rules` (für IPv4):

```bash
-A INPUT -m set --match-set blocked_ips_v4 src -j DROP
```

* `/etc/ufw/before6.rules` (für IPv6):

```bash
-A INPUT -m set --match-set blocked_ips_v6 src -j DROP
```

Nach jeder Änderung wird UFW automatisch neu geladen.

---

## 🧪 Testen

Nach dem Ausführen kannst du prüfen, ob `ipset` korrekt gefüllt ist:

```bash
ipset list blocked_ips_v4
ipset list blocked_ips_v6
```

Und ob die Regeln aktiv sind:

```bash
sudo iptables -S | grep blocked_ips_v4
sudo ip6tables -S | grep blocked_ips_v6
```

---

## 🧹 Entfernen

Falls du die Regeln und ipsets löschen möchtest:

```bash
ipset destroy blocked_ips_v4
ipset destroy blocked_ips_v6
```

UFW-Regeln musst du manuell aus `/etc/ufw/before.rules` und `/etc/ufw/before6.rules` entfernen und anschließend UFW neu laden:

```bash
sudo ufw reload
```

---

## 📄 Lizenz

MIT License – freie Nutzung, Veränderung und Verbreitung erlaubt.

