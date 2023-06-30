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
export ANSIBLE_HOST_KEY_CHECKING=False
git clone https://github.com/geksogen/k8s_install_yandex_cloud_rke.git
cd terraform
terraform init
terraform apply
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
cd k8s_install_yandex_cloud_rke/rke_config
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


#### Install Kustomize
```Bash
cd ~
wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.0.0/kustomize_v5.0.0_linux_amd64.tar.gz
tar -xvf kustomize_v5.0.0_linux_amd64.tar.gz
chmod +x kustomize
sudo mv kustomize /usr/local/bin/kustomize
kustomize version
```

#### Install StorageClass in Cluster
```Bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.22/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl get storageclass
```

### Set quota for resources
```Bash
cd ~
nano quota.yaml
kubectl apply -f quota.yaml
```

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
spec:
  hard:
    pods: "4" 
    requests.cpu: "1" 
    requests.memory: 1Gi 
    requests.ephemeral-storage: 2Gi 
    limits.cpu: "2" 
    limits.memory: 2Gi 
    limits.ephemeral-storage: 4Gi
```

#### Install Kubeflow use Kustomize
```Bash
cd ~
git clone https://github.com/kubeflow/manifests.git
cd manifests
# Change APP_SECURE_COOKIES (APP_SECURE_COOKIES=false)
while ! kustomize build example | awk '!/well-defined/' | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done
watch kubectl -n kubeflow get pod 
kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec": {"type": "NodePort"}}' 
kubectl -n istio-system get service
# email (user@example.com) and password (12341234)
```

#### Change APP_SECURE_COOKIES (APP_SECURE_COOKIES=false)
* vim apps/jupyter/jupyter-web-app/upstream/base/params.env
* vim apps/volumes-web-app/upstream/base/params.env 

#### Cnange default password 
```Bash
sudo apt install python3-pip
pip install passlib
python3 -c 'from passlib.hash import bcrypt; import getpass; print(bcrypt.using(rounds=12, ident="2y").hash(getpass.getpass()))'
# Enter new password
# Edit common/dex/base/config-map.yaml
vim common/dex/base/config-map.yaml

staticPasswords:
    - email: user@example.com
      hash: <replace hash from python hash>


```
#### Issues

* APP_SECURE_COOKIES
* The node was low on resource: ephemeral-storage (fixed increase HDD to 40GB)

### APP_SECURE_COOKIES
```Bash
kustomize build apps/jupyter/jupyter-web-app/upstream/overlay/istio | kubectl apply -f -
kubectl get pods --all-namespaces -o wide --field-selector spec.nodeName=<node>
kubectl get nodes -o=custom-columns=NodeName:.metadata.name,TaintKey:.spec.taints[*].key,TaintValue:.spec.taints[*].value,TaintEffect:.spec.taints[*].effect
```

### Add image for jupiternotebook
```Bash
kubectl -n kubeflow get cm
kubectl edit cm jupyter-web-app-config-<> -n kubeflow
kubectl delete pod jupyter-web-app-deployment-<> -n kubeflow
```

docker pull jupyter/datascience-notebook
