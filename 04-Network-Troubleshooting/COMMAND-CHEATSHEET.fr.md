# Aide-mémoire des commandes réseau (Windows · Linux · Cisco IOS)

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](COMMAND-CHEATSHEET.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](COMMAND-CHEATSHEET.md)

![Level](https://img.shields.io/badge/Level-Beginner-3fe0a0?style=flat-square)
![Type](https://img.shields.io/badge/Type-Reference%20sheet-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20Cisco%20IOS-555?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--11-555?style=flat-square)

| Élément | Contenu |
|---|---|
| **Référent** | Les commandes de diagnostic réseau équivalentes sous Windows, Linux et Cisco IOS. |
| **Émetteur** | **bazeeza** |
| **Message** | Trouver vite la bonne commande, quel que soit le système devant vous. |
| **Récepteur** | Techniciens de soutien et techniciens réseau. |
| **Canal** | Dépôt GitHub `Bazeeza/Technical-Runbooks` |
| **Code** | Français, rédaction technique (traduction de l'original anglais) |
| **Référence** | [Windows commands](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/windows-commands) · [Packet Monitor (pktmon)](https://learn.microsoft.com/en-us/windows-server/networking/technologies/pktmon/pktmon) · `man ip`, `man ss` · Références des commandes Cisco IOS |

---

## Objectif

Garder une seule page ouverte pendant un diagnostic au lieu de chercher la syntaxe. À utiliser avec le [runbook de dépannage](README.fr.md).

## Configuration et adressage

| Tâche | Windows | Linux | Cisco IOS |
|---|---|---|---|
| Afficher la configuration IP | `ipconfig /all` | `ip a` | `show ip interface brief` |
| Afficher les interfaces et l'état du lien | `Get-NetAdapter` | `ip link` | `show interfaces status` |
| Afficher la table de routage | `route print` | `ip route` | `show ip route` |
| Afficher la passerelle par défaut | `ipconfig` | `ip route show default` | `show ip route 0.0.0.0` |
| Renouveler le bail DHCP | `ipconfig /release` puis `/renew` | `sudo dhclient -r && sudo dhclient` (ou `nmcli con up <name>`) | — |
| Afficher la table ARP (IP ↔ MAC) | `arp -a` | `ip neigh` | `show arp` |
| Afficher la table des adresses MAC | — | — | `show mac address-table` |
| Afficher les VLAN | — | — | `show vlan brief` |
| Afficher le VLAN d'accès, le VLAN voix et le mode trunk d'un port | — | — | `show interfaces <port> switchport` |
| Afficher les trunks et les VLAN autorisés | — | — | `show interfaces trunk` |
| Afficher les ports bloqués et la raison | — | — | `show interfaces status err-disabled` |
| Afficher la puissance PoE par port | — | — | `show power inline` |

La configuration derrière ces commandes Cisco est expliquée dans [11 Cisco Switch Baseline](../11-Cisco-Switch-Baseline/README.fr.md).

## Connectivité

| Tâche | Windows | Linux | Cisco IOS |
|---|---|---|---|
| Tester l'accessibilité | `ping 1.1.1.1` | `ping -c 4 1.1.1.1` | `ping 1.1.1.1` |
| Ping continu | `ping -t 1.1.1.1` | `ping 1.1.1.1` (arrêter avec `Ctrl+C`) | `ping 1.1.1.1 repeat 1000` |
| Tracer le chemin | `tracert 1.1.1.1` | `traceroute 1.1.1.1` ou `tracepath` | `traceroute 1.1.1.1` |
| Chemin avec statistiques de perte | `pathping 1.1.1.1` | `mtr 1.1.1.1` | — |
| Tester un port TCP | `Test-NetConnection host -Port 443` | `nc -zv host 443` | `telnet host 443` |

## DNS

| Tâche | Windows | Linux |
|---|---|---|
| Résoudre un nom | `nslookup example.com` | `dig example.com` ou `nslookup example.com` |
| Interroger un serveur DNS précis | `nslookup example.com 1.1.1.1` | `dig @1.1.1.1 example.com` |
| Demander un type d'enregistrement | `Resolve-DnsName example.com -Type MX` | `dig example.com MX` |
| Vider le cache DNS | `ipconfig /flushdns` | `sudo resolvectl flush-caches` |
| Afficher les serveurs DNS utilisés | `Get-DnsClientServerAddress` | `resolvectl status` |

## Sessions et ports

| Tâche | Windows | Linux | Cisco IOS |
|---|---|---|---|
| Ports en écoute + processus | `netstat -ano` ou `Get-NetTCPConnection -State Listen` | `sudo ss -tulpn` | `show control-plane host open-ports` |
| Trouver le processus d'un PID | `tasklist /fi "PID eq 1234"` | `ps -p 1234 -o comm=` | — |
| État du pare-feu | `Get-NetFirewallProfile` | `sudo ufw status verbose` | `show access-lists` |
| Tester un port TCP depuis une autre machine | `Test-NetConnection <host> -Port 22` | `nc -zv <host> 22` | `telnet <host> 22` |
| Ports publiés par des conteneurs | — | `docker ps --format 'table {{.Names}}\t{{.Ports}}'` | — |

> [!TIP]
> Sur un serveur Linux, un port de conteneur que `ss` affiche sur `0.0.0.0` est joignable même quand `ufw` le refuse : voir [Docker ports and the firewall](../12-Linux-Server-Hardening/DOCKER-PORT-BINDING.fr.md).

## Capture

| Tâche | Windows | Linux |
|---|---|---|
| Capturer des paquets | Wireshark | `sudo tcpdump -i eth0 -n` |
| Capturer un seul hôte et un seul port | Filtre Wireshark `ip.addr==10.0.0.5 && tcp.port==443` | `sudo tcpdump -i eth0 host 10.0.0.5 and port 443` |
| Enregistrer dans un fichier pour Wireshark | `pktmon start --capture --pkt-size 0 --file-name capture.etl`, puis `pktmon stop` et `pktmon etl2pcap capture.etl --out capture.pcapng` (intégré à Windows, administrateur ; `--pkt-size 0` garde les paquets entiers au lieu des 128 premiers octets) | `sudo tcpdump -i eth0 -w capture.pcap` |

> [!WARNING]
> Ne capturez le trafic que sur des réseaux que vous êtes autorisé à analyser : les captures peuvent contenir des mots de passe et des données personnelles.

---

<sub>Écrit par bazeeza · Vous avez trouvé une erreur ? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Signalez-la ici</a>.</sub>
