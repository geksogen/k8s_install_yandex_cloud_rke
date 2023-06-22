terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.92.0"
}

provider "yandex" {
 token     = "<>"
 cloud_id  = "<>"
 folder_id = "<>"
 zone      = "ru-central1-a"
}

locals {
  vm_names = ["std-00-test-vm-1", "std-00-test-vm-2", "std-00-test-vm-3"]
}


resource "yandex_compute_instance" "vm" {
    count = length(local.vm_names)
    name = local.vm_names[count.index]
    resources {
        cores  = 2
        memory = 6
    }

    boot_disk {
        initialize_params {
            image_id = "fd80jfslq61mssea4ejn"
        }
    }

    network_interface {
        subnet_id = "e9b0nup7lqmaiqf045tf"
        nat       = true
    }

    scheduling_policy {
        preemptible = true
    }

    metadata = {
        user-data = file(var.new_user)
    }
  }

resource "local_file" "hosts_ini" {
     content = templatefile("hosts.tpl",
       {
         k8s-ip = [
            for instance in yandex_compute_instance.vm[*] :
            join(": ", [instance.network_interface.0.nat_ip_address])
            ]
       }
     )
     
     filename = "../ansible/host.ini"

  }

output "instance_output" {
  value = [
    for instance in yandex_compute_instance.vm[*] :
    join(": ", [instance.name, instance.hostname, instance.network_interface.0.ip_address, instance.network_interface.0.nat_ip_address])
  ]
}
