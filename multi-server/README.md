Great direction—this is where Vagrant + Ansible starts to feel like real infrastructure. I’ll show you all three upgrades in a clean progression so you can actually use them together.

---

# 🧱 1. Multi-VM Vagrant setup

We’ll create:

* **web** server
* **db** server

### Updated `Vagrantfile`

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  # Common settings
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 1
  end

  # WEB SERVER
  config.vm.define "web" do |web|
    web.vm.hostname = "web"
    web.vm.network "private_network", ip: "192.168.33.10"

    web.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "provisioning/site.yml"
      ansible.inventory_path = "provisioning/inventory.ini"
      ansible.limit = "web"
    end
  end

  # DB SERVER
  config.vm.define "db" do |db|
    db.vm.hostname = "db"
    db.vm.network "private_network", ip: "192.168.33.11"

    db.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "provisioning/site.yml"
      ansible.inventory_path = "provisioning/inventory.ini"
      ansible.limit = "db"
    end
  end
end
```

👉 Key change:
We switched from `ansible_local` → **`ansible` (remote)**
So Ansible runs on your host machine instead of inside the VM.

---

# ⚙️ 2. Inventory file (important)

Create:

```bash
provisioning/inventory.ini
```

```ini
[web]
web ansible_host=192.168.33.10 ansible_user=vagrant ansible_private_key_file=.vagrant/machines/web/virtualbox/private_key

[db]
db ansible_host=192.168.33.11 ansible_user=vagrant ansible_private_key_file=.vagrant/machines/db/virtualbox/private_key
```

---

# 📦 3. Convert playbook → roles (best practice)

## Folder structure

```bash
provisioning/
├── inventory.ini
├── site.yml
└── roles/
    ├── web/
    │   └── tasks/main.yml
    └── db/
        └── tasks/main.yml
```

---

## 🧠 `site.yml` (entry point)

```yaml
---
- hosts: web
  become: yes
  roles:
    - web

- hosts: db
  become: yes
  roles:
    - db
```

---

## 🌐 Web role

`roles/web/tasks/main.yml`

```yaml
---
- name: Install nginx
  apt:
    name: nginx
    state: present
    update_cache: yes

- name: Start nginx
  service:
    name: nginx
    state: started
    enabled: true
```

---

## 🗄️ DB role

`roles/db/tasks/main.yml`

```yaml
---
- name: Install MySQL
  apt:
    name: mysql-server
    state: present
    update_cache: yes

- name: Start MySQL
  service:
    name: mysql
    state: started
    enabled: true
```

---

# 🔁 4. Running everything

### Start both VMs

```bash
vagrant up
```

### Or individually:

```bash
vagrant up web
vagrant up db
```

---

# 🔄 5. ansible_local → remote Ansible (what changed)

### Before (your version)

```ruby
config.vm.provision "ansible_local"
```

* Ansible installed inside VM
* Playbook runs inside VM
* Simpler but less realistic

---

### Now (recommended)

```ruby
config.vm.provision "ansible"
```

* Runs from your host machine
* Uses SSH
* Matches real-world DevOps workflows

---

# ⚠️ Common pitfalls (multi-VM + remote Ansible)

### ❌ SSH key errors

If provisioning fails:

```bash
vagrant ssh web
```

Then test:

```bash
ansible -i provisioning/inventory.ini all -m ping
```

---

### ❌ VM not ready when Ansible runs

Add this if needed:

```ruby
ansible.retry_files_enabled = false
```

---

### ❌ Wrong inventory path

Make sure:

```ruby
ansible.inventory_path = "provisioning/inventory.ini"
```

---

# 💡 Nice upgrades (optional but powerful)

## 1. Group variables

```bash
provisioning/group_vars/web.yml
```

```yaml
nginx_port: 80
```

---

## 2. Templates (dynamic configs)

```bash
roles/web/templates/nginx.conf.j2
```

Use:

```yaml
template:
  src: nginx.conf.j2
  dest: /etc/nginx/nginx.conf
```

---

## 3. Add a load balancer VM

Just define another machine:

```ruby
config.vm.define "lb" do |lb|
  lb.vm.network "private_network", ip: "192.168.33.12"
end
```

---

# 🧠 Big picture

You now have:

* Multi-node infrastructure
* Role-based configuration
* Host-based Ansible execution

This is basically a **mini production environment on your laptop**.
