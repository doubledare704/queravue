#!/bin/sh
# The image ships with AllowTcpForwarding no; the tunnel tests need it. They
# also drop the connection after the host key check, which OpenSSH 9.8+
# penalises per source address unless it is switched off.
sed -i 's/^AllowTcpForwarding no/AllowTcpForwarding yes/' /config/sshd/sshd_config
grep -q '^PerSourcePenalties' /config/sshd/sshd_config || echo 'PerSourcePenalties no' >> /config/sshd/sshd_config
