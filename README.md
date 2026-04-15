Here’s a clear, step-by-step guide to getting your **Vagrant + Ansible (local)** setup working with that `Vagrantfile`.

---

## 🧱 1. Install prerequisites

You’ll need:

* **Vagrant**
* **VirtualBox**

### On Ubuntu / Debian

```bash
sudo apt update
sudo apt install -y vagrant virtualbox
```

### On macOS (Homebrew)

```bash
brew install --cask virtualbox
brew install vagrant
```

---

## 📁 2. Create project structure

Your directory should look like this:

```
project/
├── Vagrantfile
└── provisioning/
    └── install_software.yml
```

---

## 📝 3. Add your Vagrantfile

Save exactly what you wrote as `Vagrantfile`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64" # Ubuntu 22.04.5 LTS

  config.vm.synced_folder "provisioning", "/vagrant", create: true

  config.vm.provision "ansible_local", run: "always" do |ansible|
    ansible.become = true
    ansible.playbook = "/vagrant/install_software.yml"
    ansible.install = true
  end  

  config.vm.network "private_network", ip: "192.168.33.10"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end
end
```

---

## ⚙️ 4. Create Ansible playbook

Create `provisioning/install_software.yml`:

```yaml
---
- name: Install Java, Git, Node.js, curl, nginx and Docker
  hosts: all
  become: yes

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes

    - name: Install Java
      apt:
        name: openjdk-17-jdk
        state: present

    - name: Install Git
      apt:
        name: git
        state: present

    - name: Install Node.js
      apt:
        name: nodejs
        state: present

    - name: Install npm
      apt:
        name: npm
        state: present

    # List style installation
    - name: Install packages curl and nginx
      apt:
        name:
          - curl
          - nginx
        state: present

    - name: Install Docker dependencies
      apt:
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - software-properties-common
        state: present

    - name: Add Docker GPG key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Add Docker repository
      apt_repository:
        repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_lsb.codename }} stable
        state: present

    - name: Update apt cache after adding Docker repository
      apt:
        update_cache: yes

    - name: Install Docker
      apt:
        name: docker-ce
        state: present

    - name: Ensure Docker service is started and enabled
      service:
        name: docker
        state: started
        enabled: yes
```

---

## 🚀 5. Start the VM

Run:

```bash
vagrant up
```

What happens:

1. Downloads `ubuntu/jammy64` box (first time only)
2. Creates VM in VirtualBox
3. Sets private IP `192.168.33.10`
4. Syncs `provisioning/` → `/vagrant`
5. Installs Ansible inside VM (`ansible_local`)
6. Runs your playbook

---

## 🔄 6. Re-run provisioning

Because you set:

```ruby
run: "always"
```

You can re-run provisioning anytime:

```bash
vagrant provision
```

---

## 🔐 7. SSH into the VM

```bash
vagrant ssh
```

Test installed software:

```bash
ansible --version
git --version
docker --version
node --version
npm --version
java --version
nginx -v
curl --version
```

---

## 🌐 8. Access the VM

Since you set a private IP:

```
http://192.168.33.10
```

You should see the default Nginx page.

---

## 🧹 9. Stop / destroy VM

Stop:

```bash
vagrant halt
```

Destroy:

```bash
vagrant destroy -f
```

---

## ⚠️ Common issues (and fixes)

**1. Synced folder confusion**

* You mapped:

  ```
  "provisioning" → "/vagrant"
  ```
* Default `/vagrant` mapping is overridden (this is intentional but easy to forget)

**2. Ansible playbook not found**

* Make sure file exists:

  ```
  provisioning/install_software.yml
  ```

**3. Private network not reachable**

* Ensure no IP conflict with your local network
* Try another IP like:

  ```
  192.168.56.10
  ```

**4. Memory too low**

* If provisioning fails, increase:

  ```ruby
  vb.memory = "2048"
  ```

---

## 💡 Optional improvements

* Add CPU:

```ruby
vb.cpus = 2
```

* Use port forwarding:

```ruby
config.vm.network "forwarded_port", guest: 80, host: 8080
```

