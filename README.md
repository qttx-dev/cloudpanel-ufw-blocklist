# cloudpanel-ufw-blocklist
Dieses Skript lädt automatisch eine IP-Blocklisten, importiert sie in `ipset` und blockiert den Verkehr via `iptables`/`ip6tables`. Zusätzlich werden die Regeln in UFW integriert, um CloudPanel-kompatibel zu bleiben.
