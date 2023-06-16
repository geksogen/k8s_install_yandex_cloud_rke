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
IP's in host.ini
```Bash
curl <repo my terraform>
terraform apply
```
