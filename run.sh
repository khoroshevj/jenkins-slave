#!/usr/bin/env bash
/opt/consul/consul agent -config-dir=/etc/consul.d/ -bind '{{ GetPrivateInterfaces | include "network" "172.0.0.0/8" | attr "address" }}' > /dev/null 2>&1 &
bash < /usr/local/bin/setup-sshd
