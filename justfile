_default:
    @just --list

# Decrypt vault secrets for local use
vault-decrypt:
    ansible-vault decrypt --output group_vars/all/vault.yaml group_vars/all/vault.yaml.enc

# Re-encrypt vault secrets after editing
vault-encrypt:
    ansible-vault encrypt --output group_vars/all/vault.yaml.enc group_vars/all/vault.yaml
