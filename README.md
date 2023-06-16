### Set k8s for Yandex Cloud use RKE

* Ubuntu v22.04
* k8s v1.25.9

#### Initialisation VM's
```Bash
curl <repo my terraform>
terraform apply
```

#### Ansible install (host who ssh connect to VM's cluster)
```Bash
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
```


#### Configuration VM's
```Bash
git clone https://github.com/geksogen/k8s_install_yandex_cloud_rke/tree/master
cd k8s_install_yandex_cloud_rke/ansible
vim host.ini # Replace IP
ansible-playbook -i host.ini playbook.yml
cd ~
```

### Install RKE (host who ssh connect to VM's cluster)
```Bash
curl -s https://api.github.com/repos/rancher/rke/releases/latest | grep download_url | grep amd64 | cut -d '"' -f 4 | wget -qi -
chmod +x rke_linux-amd64
sudo mv rke_linux-amd64 /usr/local/bin/rke
rke --version
```

### Install Kubectl (host who ssh connect to VM's cluster)
```Bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
```

### Deploy k8s
```Bash
cd k8s_install_yandex_cloud_rke/rke_config
rke up --ignore-docker-version
kubectl --kubeconfig kube_config_cluster.yml get nodes 

NAME    STATUS   ROLES                      AGE     VERSION
node1   Ready    controlplane,etcd,worker   2m10s   v1.25.9
node2   Ready    worker                     2m6s    v1.25.9
node3   Ready    worker                     2m6s    v1.25.9
```

### Set kubeconfig
```Bash
mkdir ~/.kube/
cat kube_config_cluster.yml >~/.kube/k8s-hls
export KUBECONFIG=$(find ~/.kube -maxdepth 1 -type f -name '*' | tr "\n" ":")
```
