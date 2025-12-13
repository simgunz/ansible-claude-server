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

To provision run:

```bash
 export ANSIBLE_BECOME_PASS=mypassword  # Add leading space to not store in history
./install
```

