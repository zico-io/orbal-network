# Network Topology

## Overview

All networking is managed by the Unifi stack. NixOS hosts are consumers, not controllers.

## Hosts

| Host | IP | Role |
|------|-----|------|
| zebes | TBD | Main server |
| elitedesk-1 | TBD | Compute node |
| elitedesk-2 | TBD | Compute node |
| elitedesk-3 | TBD | Compute node |

## VLANs

TBD — document VLAN layout as configured in Unifi.

## DNS

TBD — document local DNS setup.

## Ports

| Port | Service | Host |
|------|---------|------|
| 32400 | Plex | zebes |
| 8989 | Sonarr | zebes |
| 7878 | Radarr | zebes |
| 9696 | Prowlarr | zebes |
