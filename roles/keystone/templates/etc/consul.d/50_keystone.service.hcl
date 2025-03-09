# {{ ansible_managed }}

services {
  name = "openstack-keystone"
  id   = "openstack-keystone"
  port = 5000

  check = {
    id = "openstack-keystone"
    name = "Keystone API on port 5000"
    http = "https://127.0.0.1:5000/healthcheck"
    tls_skip_verify = true # skipping verify because we can't get the fqdn

    interval = "30s"
    timeout = "5s"
  }

  meta {
    haproxy_t2 = "true"
    haproxy_t2_check_uri = "/healthcheck"
  }
}