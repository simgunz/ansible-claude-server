# Ansible remote servers

This is an ansible repository to setup remove servers, typically on Hetzner.

## Server creation

- Type: shared vCPU CX23 or CX22
- Networking: IPv6 only (if the home network supports IPv6) to save money
- Set your SSH Keys as default
- Use this cloud-init (see [Hetzner cloud config](https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://community.hetzner.com/tutorials/basic-cloud-config/&ved=2ahUKEwikxMremLqRAxWi1wIHHdLbKDsQFnoECA0QAQ&usg=AOvVaw16xNg-kh3TNPSPmKAsMZvv)
	- The initial `#cloud-config` comment is required!
```yaml
#cloud-config
users:
  - name: simone
    groups: users, sudo
    sudo: ALL=(ALL) ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - <key here>
```
- Login as root and set the password for `simone` with `passwd simone` before disabling root login over ssh

## Setup

Install requirements:

```bash
ansible-galaxy install -r requirements.yml
```

### Initial provisioning

First run Docker and WireGuard setup:

```bash
 export ANSIBLE_BECOME_PASS=mypassword  # Add leading space to not store in history
./install greenfly --tags docker,wg_easy
```

### Configure WireGuard VPN

1. Create SSH tunnel to access wg-easy web interface:

```bash
ssh -N -L 51821:localhost:51821 simone@<server-ip>
```

2. Open browser and navigate to `http://localhost:51821`

3. Login with username `admin` and the generated password found in:
   - Server path: `/home/simone/services/wg_easy/.env`
   - Look for `INIT_PASSWORD=...`

4. Save the password in your password manager

5. Remove the `INIT_PASSWORD` variable from `/home/simone/services/wg_easy/.env` to avoid credential exposure

6. Create a new WireGuard client in the web interface

7. Download the configuration file or scan QR code

8. Import the configuration into your WireGuard client

### Full provisioning

To run all roles:

```bash
 export ANSIBLE_BECOME_PASS=mypassword  # Add leading space to not store in history
./install greenfly
```

