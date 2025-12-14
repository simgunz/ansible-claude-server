# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ansible repository for provisioning remote servers with Docker, WireGuard VPN, and security hardening. Take inspiration from `/media/data/self_hosted/ansible-home-servers` and use the same style when possible - the goal is to extract common roles into a collection later.

## Code Style

### File Extensions
- Templates: Use `.jinja` extension (e.g., `compose.yaml.jinja`, `.env.jinja`)
- Playbooks: Use `.yaml` extension

### Variable Organization
Variables are organized by scope with Jinja2 references for DRY:

**`group_vars/all.yaml`**: Global variables
```yaml
service_user: simone
service_group: simone
services_dir: /home/simone/services
docker_users:
  - simone
```

**`host_vars/{hostname}.yml`**: Host-specific variables organized by topic
```yaml
# Base network config
docker_bridge_ip: "10.43.43.43"
docker_bridge_subnet: "10.43.43.0/24"
wireguard_port: "51820"

# Role-specific variables reference base config
wg_easy_bridge_ip: "{{ docker_bridge_ip }}"
wg_easy_port: "{{ wireguard_port }}"
ufw_ssh_allowed_subnet: "{{ docker_bridge_subnet }}"
```

### Role Structure
Standard Ansible layout:
```
roles/role_name/
├── defaults/main.yml    # Default variables
├── tasks/main.yml       # Task definitions
└── templates/           # Jinja2 templates with .jinja extension
```

### Adding New Roles

1. **Create role structure** in `roles/role_name/`
2. **Add to playbook** in `playbooks/{target}.yaml`:
   ```yaml
   - name: Setup server
     hosts: all
     become: true
     roles:
       - existing_role
       - role_name  # Add here
   ```
3. **Define variables**:
   - Defaults in `roles/role_name/defaults/main.yml`
   - Host-specific in `host_vars/{hostname}.yml`
4. **Tag all tasks** with role name: `tags: role_name`

### Variable Inheritance Pattern
Use Jinja2 references to maintain single source of truth and avoid duplication across roles:
```yaml
base_variable: "value"
role_specific_variable: "{{ base_variable }}"
```

## Inventory Structure

Dual host entries for same physical server:
- `{hostname}-public`: Public IP for initial provisioning
- `{hostname}`: VPN IP for normal operations after SSH lockdown
