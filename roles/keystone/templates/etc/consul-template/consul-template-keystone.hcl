# {{ ansible_managed }}

vault {
  address = "http://127.0.0.1:8100"
  renew_token = false
  retry {
    # Settings to 0 for unlimited retries.
    attempts = 0
  }
}

consul {
  address = "127.0.0.1:8500"
  retry {
    # Settings to 0 for unlimited retries.
    attempts = 0
  }
}

# Postgres CA
template {
  source = "/etc/consul-template/templates/keystone/postgres-server-ca.crt.ctmpl"
  destination = "/etc/keystone/postgres-server-ca.crt"
  create_dest_dirs = false
  perms = "0644"
  exec {
    command = "sudo systemctl reload-or-restart apache2 || true"
  }
}

# Postgres User
template {
  source = "/etc/consul-template/templates/keystone/postgres-user-keystone.ctmpl"
  destination = "/etc/keystone/postgres-user-keystone.rendered"
  create_dest_dirs = false
  perms = "0600"
  exec {
    command = "sudo systemctl reload-or-restart apache2 || true"
  }
}

# Keystone Internal CA
template {
  source = "/etc/consul-template/templates/keystone/keystone-internal-ca.crt.ctmpl"
  destination = "/etc/keystone/keystone-internal-ca.crt"
  create_dest_dirs = false
  perms = "0644"
  exec {
    command = "sudo systemctl reload-or-restart apache2 || true"
  }
}

# Keystone Internal Cert
template {
  source = "/etc/consul-template/templates/keystone/keystone-internal.ctmpl"
  destination = "/etc/keystone/keystone-internal.rendered"
  create_dest_dirs = false
  perms = "0600"
  exec {
    command = "sudo systemctl reload-or-restart apache2 || true"
  }
}

# Keystone Admin Cert
template {
  source = "/etc/consul-template/templates/keystone/keystone-user-admin.ctmpl"
  destination = "/etc/keystone/keystone-user-admin.rendered"
  create_dest_dirs = false
  perms = "0600"
}