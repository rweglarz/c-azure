#!/bin/bash
set -o xtrace
mkdir /var/log/bird
touch /var/log/bird/bird.log
chown -R bird:bird /var/log/bird
systemctl restart bird
