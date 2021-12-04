
# Instruct terraform to download the provider on `terraform init`
terraform {
  required_providers {
    xenorchestra = {
      source = "terra-farm/xenorchestra"
      version = "~> 0.20.0"
    }
  }
}

# vm.tf
data "xenorchestra_pool" "pool" {
  name_label = "xcp-ng-01"
}

data "xenorchestra_template" "vm_template" {
  name_label = "Ubuntu 20.04"
}

data "xenorchestra_sr" "sr" {
  name_label = "Local storage"
  pool_id = data.xenorchestra_pool.pool.id
}

data "xenorchestra_network" "network" {
  name_label = "50 - ShopNet"
  pool_id = data.xenorchestra_pool.pool.id
}

resource "xenorchestra_cloud_config" "bar" {
  name = "cloud config name"
  template = <<EOF
#cloud-config

runcmd:
 - [ ls, -l, / ]
 - [ sh, -xc, "echo $(date) ': hello world!'" ]
 - [ sh, -c, echo "=========hello world'=========" ]
 - ls -l /root
 - touch /home/dylan/test.txt
EOF
}

resource "random_id" "server" {
  byte_length = 2
}

resource "xenorchestra_vm" "first" {
  memory_max = 2147467264
  cpus = 1
  name_label = "XO terraform tutorial - ${random_id.server.hex}"
  template = data.xenorchestra_template.vm_template.id

  network {
    network_id = data.xenorchestra_network.network.id
  }

  disk {
    sr_id = data.xenorchestra_sr.sr.id
    name_label = "VM root volume"
    size = 50212254720
  }
}

resource "random_id" "server2" {
  byte_length = 2
}

resource "xenorchestra_vm" "second" {
  memory_max = 2147467264
  cpus = 1
  name_label = "XO terraform tutorial - ${random_id.server2.hex}"
  template = data.xenorchestra_template.vm_template.id

  network {
    network_id = data.xenorchestra_network.network.id
  }

  disk {
    sr_id = data.xenorchestra_sr.sr.id
    name_label = "VM root volume"
    size = 50212254720
  }
}

output "ip_address_first" {
  value = xenorchestra_vm.first.ipv4_addresses
}

output "ip_addresss_second" {
  value = xenorchestra_vm.second.ipv4_addresses
}