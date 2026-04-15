You can do this—but a quick reality check first: running full Kubernetes inside Vagrant VMs is **resource-heavy and slower than cloud or native installs**. It’s great for learning and testing, not for anything performance-sensitive.

That said, here’s a clean, working setup using:

* **Docker**
* **Kubernetes via kubeadm**
* 1 control plane + 1 worker

---

# 🧱 1. Multi-VM Vagrantfile (K8s cluster)

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end

  # CONTROL PLANE
  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "192.168.56.10"

    master.vm.provision "shell", path: "provisioning/common.sh"
    master.vm.provision "shell", path: "provisioning/master.sh"
  end

  # WORKER NODE
  config.vm.define "worker" do |worker|
    worker.vm.hostname = "worker"
    worker.vm.network "private_network", ip: "192.168.56.11"

    worker.vm.provision "shell", path: "provisioning/common.sh"
    worker.vm.provision "shell", path: "provisioning/worker.sh"
  end
end
```

---

# 📁 2. Folder structure

```bash
project/
├── Vagrantfile
└── provisioning/
    ├── common.sh
    ├── master.sh
    └── worker.sh
```

---

# ⚙️ 3. Common setup (Docker + Kubernetes deps)

`provisioning/common.sh`

```bash
#!/bin/bash

set -e

# Disable swap (required by Kubernetes)
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Load kernel modules
modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

# Install Docker
apt-get update
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

# Install Kubernetes tools
apt-get update
apt-get install -y apt-transport-https curl

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
```

---

# 🎛️ 4. Master node setup

`provisioning/master.sh`

```bash
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
```

---

# 🧩 5. Worker node setup

`provisioning/worker.sh`

```bash
#!/bin/bash

set -e

# Wait until master is ready
sleep 30

# Copy join command from master
scp -o StrictHostKeyChecking=no vagrant@192.168.56.10:/home/vagrant/join.sh /home/vagrant/join.sh

# Join cluster
bash /home/vagrant/join.sh
```

---

# 🚀 6. Start the cluster

```bash
vagrant up
```

Then SSH into master:

```bash
vagrant ssh master
```

Check cluster:

```bash
kubectl get nodes
```

You should see:

```
master   Ready
worker   Ready
```

---

# 🌐 7. Test Kubernetes (deploy app)

Inside master:

```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=NodePort --port=80
```

Check service:

```bash
kubectl get svc
```

---

# ⚠️ Important fixes (very common issues)

## ❌ Worker can't join

Replace `scp` with Vagrant synced folder (more reliable):

Add in Vagrantfile:

```ruby
config.vm.synced_folder ".", "/vagrant"
```

Then in `master.sh`:

```bash
kubeadm token create --print-join-command > /vagrant/join.sh
```

And in `worker.sh`:

```bash
bash /vagrant/join.sh
```

---

## ❌ Nodes stuck in NotReady

Apply network plugin again:

```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

---

## ❌ Docker vs containerd warning

Modern Kubernetes prefers containerd:

Replace Docker install with:

```bash
apt-get install -y containerd
```

---

# 💡 Optional upgrades

## 1. Add more workers

```ruby
(2..3).each do |i|
  config.vm.define "worker#{i}" do |node|
    node.vm.network "private_network", ip: "192.168.56.1#{i}"
  end
end
```

---

## 2. Install Kubernetes dashboard

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
```

---

## 3. Use Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

---

# 🧠 What you just built

You now have:

* VM-based lab (Vagrant)
* Container runtime (Docker/containerd)
* Kubernetes cluster (kubeadm)
* Multi-node networking

This is essentially a **mini on-prem cluster simulation**.
