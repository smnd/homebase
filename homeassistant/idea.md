# Home Ops Monitor — Ideas

## 1) What to track

### A. Synology NAS (DSM)
**Signals:** volume/RAID state, free %, IOPS, SMART (temp, reallocated/pending), CPU/RAM/temp/fans, snapshots/Hyper Backup age & delta, package status, UPS state, NTP sync, DSM version.  
**Alerts:** free < 15% (or projected in 7 days), SMART error or temp > 60 °C, backup/snapshot older than 24 h, RAID degraded.

### B. Certificates & DNS
**Signals:** public cert expiry/chain, ACME renewal logs, Cloudflare DNS drift, HTTP→HTTPS redirect/HSTS, mixed content.  
**Alerts:** cert < 21 days to expiry, renewal failed, DNS mismatch vs expected.

### C. Containers & Services (Docker/Compose/Podman)
**Signals:** container up/down, restarts, CPU/RAM, OOM kills, image outdated, healthcheck, port bindings, 4xx/5xx rate.  
**Alerts:** restart loop (>3/10 min), healthcheck “unhealthy”, critical image > 30 days old.

### D. Backups & Off-site Copies
**Signals:** job success age, size deltas, sample restore checks, 3-2-1 compliance.  
**Alerts:** off-site backup > 48 h old, no sample restore in 30 days.

### E. Network & Internet
**Signals:** WAN up/down, public IP changes, latency/jitter/loss to targets, scheduled speedtest, port-surface changes, uPnP.  
**Alerts:** loss > 2% for 10 min, unexpected open port, uPnP re-enabled.

### F. DNS/Ad-blocking (Pi-hole/AdGuard)
**Signals:** resolver status, query rate, blocked %, list update age, upstream reachability, DHCP leases.  
**Alerts:** resolver down, lists stale > 7 days, upstream intermittent.

### G. Security
**Signals:** Fail2ban bans, SSH auth attempts, sudo failures, WAF blocks, VPN peers up/down.  
**Alerts:** brute-force spikes, new country/ASN on admin surface, tunnel down > 5 min.

### H. Macs & Endpoints
**Signals:** Time Machine age/size, disk free %, battery health/cycles, FileVault, firewall, OS/brew updates.  
**Alerts:** TM > 48 h, disk < 10%, critical updates pending > 7 days.

### I. Home Automation & Cameras
**Signals:** Home Assistant core/add-on updates, offline devices (Zigbee/Wi-Fi), NVR disk health, dropped frames.  
**Alerts:** >5 devices offline 15+ min, recording gaps, HA backup > 7 days.

### J. Power & Environment
**Signals:** UPS on-battery events, load %, runtime, self-tests; room/rack temp/humidity.  
**Alerts:** runtime < 5 min at current load, temp > threshold for 10 min.

### K. Jobs & Schedules
**Signals:** cron/launchd success/failure, runtime deviation, healthcheck pings.  
**Alerts:** job missed window, runtime > P95×2.

---

## 2) Suggested integrations (Home Assistant)
- **Synology DSM**, **NUT (UPS)**, **UniFi/MikroTik/OpenWrt**, **Pi-hole** or **AdGuard Home**, **Certificate Expiry**, **Cloudflare** (A-record updater),  
- **Monitor Docker** (HACS), **Glances** (host metrics), **Speedtest** (scheduled), **Healthchecks.io** (HACS or REST).

---

## 3) Automations to add (examples)

### NAS free space < 15%
```yaml
alias: NAS low free space
trigger:
  - platform: numeric_state
    entity_id: sensor.synology_volume_1_volume_used
    above: 85
action:
  - service: notify.mobile_app_phone
    data:
      message: "NAS volume >85% used. Plan cleanup or add capacity."
```

### TLS cert expires in < 21 days
```yaml
alias: TLS cert expiring
trigger:
  - platform: template
    value_template: >
      {{ (as_timestamp(states('sensor.cert_expiry_example_com')) - now().timestamp())/86400 < 21 }}
action:
  - service: notify.mobile_app_phone
    data:
      message: "example.com certificate <21 days to expiry."
```

### UPS on battery
```yaml
alias: UPS on battery
trigger:
  - platform: state
    entity_id: sensor.nut_ups_status
    to: "OB"
action:
  - service: notify.mobile_app_phone
    data:
      message: "UPS on battery. Runtime: {{ states('sensor.nut_ups_runtime') }} sec."
```

### Container restart loop
```yaml
alias: Container restarting
trigger:
  - platform: numeric_state
    entity_id: sensor.docker_myservice_container_restarts
    above: 3
    for: "00:10:00"
action:
  - service: notify.mobile_app_phone
    data:
      message: "Container myservice restarted >3 times in 10 min."
```

---

## 4) One “Ops” dashboard (cards to add)
- **NAS & UPS:** volume used %, disk temps, UPS state/runtime.  
- **Network:** WAN state, last speedtest, latency/loss (ping sensors).  
- **Security:** failed logins/bans (from router/Fail2ban).  
- **Services:** Docker containers (status, restarts), AdGuard/Pi-hole status.  
- **Certs & DNS:** days-to-expiry per domain, Cloudflare updater state.

---

## 5) Hardening & hygiene
- Put tokens in `secrets.yaml`.  
- Schedule nightly **backups** and do a quarterly **test restore**.  
- Throttle heavy polls (e.g., Speedtest).  
- Keep HACS/integrations updated.

---

## 6) Centralize with an app vs existing tools

### Option A — Build a macOS menu bar app
**Pros:** Always-visible status, native notifications, low ceremony, local-first.  
**Cons:** You own integrations/alerts/UX; sharing dashboards is harder.

### Option B — Use Home Assistant as the hub (baseline)
**Pros:** Dozens of ready integrations, automations, notifications, local dashboards/history.  
**Cons:** Another service to maintain; metrics math is basic vs Grafana.

### Option C — Prometheus + Grafana + Alertmanager
**Pros:** Industrial-grade metrics, dashboards, routing, silences.  
**Cons:** Heavier setup/ops; overkill for small home labs.

### Option D — Uptime Kuma + Healthchecks + scripts
**Pros:** Fast uptime/TLS/cron coverage; tiny footprint.  
**Cons:** Fragmented view; shallow device metrics.

**Recommendation:** Start with Home Assistant as the aggregator (B). If you miss native Mac UX, add a thin menu bar client that reads HA state and shows condensed status + notifications—no need to re-implement every integration.
