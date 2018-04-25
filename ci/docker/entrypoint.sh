#!/bin/ash

# generate host keys if not present
ssh-keygen -A

# start up dockerd
/usr/local/bin/initdocker

# do not detach (-D), log to stderr (-e), passthrough other arguments
exec /usr/sbin/sshd -D -e -p 2222 "$@"