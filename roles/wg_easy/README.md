# wg_easy Role

Deploys [wg-easy](https://github.com/wg-easy/wg-easy) - WireGuard VPN server with web-based admin UI.

## Architecture

WireGuard runs inside a Docker container with the following network topology:

```
VPN Clients (10.8.0.0/24)
    ↓
wg0 interface (in container)
    ↓
Docker bridge (10.42.42.0/24)
    ├─ Container: 10.42.42.42
    └─ Host: 10.42.42.1
        ↓
Host network (ansible_host)
Example: 192.168.77.240 or 203.0.113.5
```

## Configuration Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `wg_easy_host` | Public hostname/IP for VPN endpoint | `"vpn.example.com"` or `"203.0.113.5"` |

**Note:** Must be set in `host_vars/<hostname>.yaml`. No sensible default exists.

### Common Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `wg_easy_port` | `"51820"` | UDP port for WireGuard traffic |
| `wg_easy_dns` | `"1.1.1.1,1.0.0.1"` | DNS servers for VPN clients |
| `wg_easy_allow_server_access` | `true` | Allow SSH to server (via `ansible_host`) over VPN |
| `wg_easy_allowed_ips_extra` | `""` | Additional networks/IPs accessible via VPN |

### Advanced Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `wg_easy_client_ipv4_cidr` | `"10.8.0.0/24"` | VPN client IP range (IPv4) |
| `wg_easy_client_ipv6_cidr` | `"fd08:8:8::/64"` | VPN client IP range (IPv6) |
| `wg_easy_version` | `"15.1"` | wg-easy Docker image version |
| `wg_easy_admin_username` | `"admin"` | Admin UI username |

**Important:** Change `wg_easy_client_ipv4_cidr` if running multiple WireGuard VPNs to avoid IP conflicts.

## Admin Panel

### Accessing the Admin UI

The admin interface binds to `127.0.0.1:51821` and is **not exposed** to external networks.

**Access via SSH Tunnel:**
```bash
ssh -L 51821:localhost:51821 user@housefly
# Then browse to: http://localhost:51821
```

### Initial Configuration

The Admin Panel has two configuration sections:

- **Config** - Default settings for new client configurations (what gets written to client config files)
- **Interface** - Server-side WireGuard interface parameters (wg0 interface inside container)

**v15.1 Users:** `INIT_ALLOWED_IPS` only works in v15.2+. For v15.1, manually configure via Admin Panel:
1. Access admin UI (see above)
2. Navigate to: **Admin Panel > Config > Allowed IPs**
3. Set networks as configured in `wg_easy_allowed_ips_extra`
   - This controls the `AllowedIPs` field in generated client configurations
   - Determines which traffic routes through the VPN tunnel

**MTU Configuration:**
1. Navigate to: **Admin Panel > Config > MTU** (client default) and **Admin Panel > Interface > MTU** (server interface)
2. **Set both to 1280** - Recommended for mobile networks to avoid packet fragmentation and connection instability
   - Config MTU: Sets default MTU in client configurations
   - Interface MTU: Sets MTU on server's wg0 interface

**Why 1280?** Mobile networks and complex routing paths often have lower MTU limits. Using 1280 provides a safe margin that works reliably across most network conditions. See [finding optimal MTU discussion](https://old.reddit.com/r/WireGuard/comments/plm8y7/finding_the_optimal_mtu_for_wg_server_and_wg_peer/) for details.

## Network Access Patterns

### Allowed IPs Configuration

The `INIT_ALLOWED_IPS` setting controls which networks are routed through the VPN. It is automatically built from:

1. **VPN client networks** (always included):
   - `{{ wg_easy_client_ipv4_cidr }}` (default: `10.8.0.0/24`)
   - `{{ wg_easy_client_ipv6_cidr }}` (default: `fd08:8:8::/64`)

2. **Server access** (if `wg_easy_allow_server_access: true`):
   - `{{ ansible_host }}/32` - The server's IP from Ansible inventory

3. **Additional networks** (if `wg_easy_allowed_ips_extra` is set):
   - User-defined subnets or IPs

### Split Tunneling vs Full Tunneling

**Recommended approach:** Configure `wg_easy_allowed_ips_extra` for **split tunneling** (only specific networks route through VPN). Then create two VPN client configurations:

1. **Split Tunnel Profile** - Routes only specified networks through VPN
   - Uses configured `INIT_ALLOWED_IPS`
   - Internet traffic uses local connection (faster)
   - Use for: Accessing home services while traveling

2. **Full Tunnel Profile** - Routes all traffic through VPN
   - Edit client config: Set `AllowedIPs = 0.0.0.0/0, ::/0`
   - All internet traffic routes through VPN (privacy/security)
   - Use for: Untrusted networks (airports, cafes)

Both profiles connect to the same VPN server - only the client-side routing differs.

### Use Case Examples

#### Home Network Deployment (Split Tunnel)

Access entire home LAN and DNS servers over VPN:

```yaml
# host_vars/housefly.yaml
wg_easy_host: "home.example.com"
wg_easy_port: "51820"
wg_easy_allow_server_access: false  # Home LAN subnet already includes server
wg_easy_allowed_ips_extra: "192.168.1.0/24,8.8.8.8/32,8.8.4.4/32"
```

**Result:** VPN clients can access:
- `10.8.0.0/24` - Other VPN clients
- `192.168.1.0/24` - Home network devices (including server at `192.168.1.100`)
- `8.8.8.8`, `8.8.4.4` - Specific DNS servers

#### Public Server Deployment

Access only the VPN server over encrypted tunnel:

```yaml
# inventory.yml
hosts:
  public-vpn:
    ansible_host: 203.0.113.5

# host_vars/public-vpn.yaml
wg_easy_host: "vpn.example.com"
wg_easy_port: "51820"
wg_easy_allow_server_access: true  # SSH to 203.0.113.5 over VPN
wg_easy_allowed_ips_extra: ""
```

**Result:** VPN clients can access:
- `10.8.0.0/24` - Other VPN clients
- `203.0.113.5/32` - SSH to server via `ssh user@203.0.113.5` (routed through VPN tunnel)

#### Multiple VPN Servers

Avoid client IP conflicts:

```yaml
# host_vars/vpn1.yaml
wg_easy_client_ipv4_cidr: "10.8.0.0/24"
wg_easy_allowed_ips_extra: "192.168.1.0/24"

# host_vars/vpn2.yaml
wg_easy_client_ipv4_cidr: "10.9.0.0/24"  # Different subnet!
wg_easy_allowed_ips_extra: "192.168.2.0/24"
```

## Testing

```bash
# Deploy to host
./install --limit housefly --tags wg_easy

# Verify container
ssh housefly 'docker ps | grep wg-easy'

# Test VPN connection
# 1. Access admin UI and create client
# 2. Download/scan QR code
# 3. Connect and verify: ping 10.8.0.1
```

## Rationale & Design Decisions

### Why No Bridge Network Variables?

**Previous design:** Exposed `wg_easy_bridge_ip`, `wg_easy_bridge_subnet`, `wg_easy_bridge_host_ip` as variables.

**Problem:**
- Bridge network (`10.42.42.0/24`) is Docker implementation detail
- Unnecessarily complex when running multiple VPN instances
- Users never need to change it

**Solution:** Hardcode bridge network in `compose.yaml.jinja`. Multiple wg-easy instances can share the same bridge subnet since Docker networks are isolated.

### Why Use `ansible_host` Instead of Bridge IP?

**Previous design:** Added `10.42.42.1/32` to `INIT_ALLOWED_IPS` for server SSH access.

**Problem:**
- Requires configuring different bridge subnets for multiple VPNs
- Bridge IP is awkward (`10.42.42.1` has no meaning to users)

**Solution:** Use `{{ ansible_host }}` from inventory:
- **Public server:** Routes traffic to public IP through VPN tunnel (bypasses internet firewall)
- **Private server:** Routes traffic to private IP through VPN (e.g., `192.168.77.240`)
- Single source of truth for server address

### Why Separate `allow_server_access` and `allowed_ips_extra`?

**Use case distinction:**
- `wg_easy_allow_server_access`: "I want SSH to the VPN server itself"
- `wg_easy_allowed_ips_extra`: "I want access to other networks/services"

**Benefits:**
- Clear intent in configuration
- Avoids duplicating server IP when using LAN subnet
- Easy to disable server access for home deployments (where LAN subnet includes server)
