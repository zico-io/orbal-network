# Network Topology

## Overview

All networking is managed by the Unifi stack. NixOS hosts are consumers, not controllers.

## Hosts

| Host | IP | Role |
|------|-----|------|
| forge | 192.168.12.205 | Dev VM on TrueNAS (mother-brain) |
| seed | 46.62.190.233 | Hetzner dedicated server |
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
| 22 | SSH | forge, seed |
