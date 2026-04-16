#!/bin/bash

set -e

# Initialize cluster
kubeadm init --apiserver-advertise-address=192.168.56.10 --pod-network-cidr=192.168.0.0/16 | tee /home/vagrant/kubeinit.log

# Setup kubeconfig
mkdir -p /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

# Install network plugin (Calico)
su - vagrant -c "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"

# Save join command
kubeadm token create --print-join-command > /home/vagrant/join.sh
chmod +x /home/vagrant/join.sh