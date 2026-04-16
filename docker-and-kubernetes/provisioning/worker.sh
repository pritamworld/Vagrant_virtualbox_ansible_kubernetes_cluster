#!/bin/bash

set -e

# Wait until master is ready
sleep 30

# Copy join command from master
scp -o StrictHostKeyChecking=no vagrant@192.168.56.10:/home/vagrant/join.sh /home/vagrant/join.sh

# Join cluster
bash /home/vagrant/join.sh