### Set k8s for Yandex Cloud use RKE

* Ubuntu v22.04 (2CPU, 40GB HDD, 8Gb RAM)
* k8s v1.25.9

#### Ansible install (terminal_host who ssh connect to VM's cluster)
```Bash
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
```

### Configure terraform provider on host
Create ~/.terraformrc
```
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
} 
```

#### Initialisation VM's and Configuration (dynamic inventory Ansible)
```Bash
git clone https://github.com/geksogen/k8s_install_yandex_cloud_rke.git
cd terraform
terraform init
terraform apply
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i ../ansible/host.ini ../ansible/playbook.yml

```

### Install RKE (terminal_host who ssh connect to VM's cluster)
```Bash
curl -s https://api.github.com/repos/rancher/rke/releases/latest | grep download_url | grep amd64 | cut -d '"' -f 4 | wget -qi -
chmod +x rke_linux-amd64
sudo mv rke_linux-amd64 /usr/local/bin/rke
rke --version
rke config --list-version --all
```

### Deploy k8s
```Bash
cd ../rke_config
vm cluster.yml # Replace IP for nodes
# Remove old config cluster
rke up --ignore-docker-version
kubectl --kubeconfig kube_config_cluster.yml get nodes 

NAME    STATUS   ROLES                      AGE     VERSION
node1   Ready    controlplane,etcd,worker   2m10s   v1.25.9
node2   Ready    worker                     2m6s    v1.25.9
node3   Ready    worker                     2m6s    v1.25.9

scp kube_config_cluster.yml student@158.160.102.8:~/ & ssh student@158.160.102.8
```

### Install Kubectl (master node)
```Bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
```

### Set kubeconfig
```Bash
mkdir ~/.kube/
cat kube_config_cluster.yml >~/.kube/k8s-hls & export KUBECONFIG=$(find ~/.kube -maxdepth 1 -type f -name '*' | tr "\n" ":")
```

### Install StorageClass in Cluster
```Bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.22/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl get storageclass
```

### Clear
```Bash
#exit from cluster node
pwd rke_config
rke remove --ignore-docker-version
cd ../terraform  
terraform destroy
```
