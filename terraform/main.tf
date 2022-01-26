provider "xenorchestra" {
  insecure = true
}

provider "dns" {
  update {
    server        = "ns1.dylanlab.xyz"
    key_name      = "dylanlab.xyz."
    key_algorithm = "hmac-sha256"
    key_secret    = "QZnULB75ySdwR1CNHx3Bjx6CXJKQBa/jcjTfPceoBXU="
  }
}

## Data

data "xenorchestra_pool" "pool" {
  name_label = "xcp-ng-pool-01"
}

data "xenorchestra_template" "vm_template" {
  name_label = "ubuntu-focal-20.04-cloudimg-20220124"
}

data "xenorchestra_sr" "iscsi" {
  name_label = "iscsi-vm-store"
  pool_id = data.xenorchestra_pool.pool.id
}

data "xenorchestra_network" "network" {
  name_label = "52-cloudnet"
  pool_id = data.xenorchestra_pool.pool.id
}

## Resources

### Controller Nodes

resource "random_id" "controllers" {
  count = var.vm_count_controllers
  byte_length = 8
}

resource "xenorchestra_cloud_config" "controllers" {
  count = var.vm_count_controllers

  name = "cloud config name"
  template = <<EOF
#cloud-config
hostname: ${var.vm_name_prefix}${random_id.controllers[count.index].hex}.${var.vm_name_suffix}
users:
  - name: ${var.username_admin}
    gecos: ${var.username_admin}
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${var.public_key_admin}
  - name: ${var.username_ansible}
    gecos: ${var.username_ansible}
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${var.public_key_ansible}

runcmd:
  - reboot  

packages:
  - xe-guest-utilities

EOF
}

resource "xenorchestra_vm" "controllers" {
    count = var.vm_count_controllers

    memory_max = var.vm_memory_size_gb * 1024 * 1024 * 1024 # GB to B
    cpus = var.vm_cpu_count
    name_label = "${var.vm_name_prefix}${random_id.controllers[count.index].hex}.${var.vm_name_suffix}"
    name_description = "Ubuntu 20.04 Kubernetes controller node"
    template = data.xenorchestra_template.vm_template.id
    cloud_config = xenorchestra_cloud_config.controllers[count.index].template

    network {
        network_id = data.xenorchestra_network.network.id
    }

    wait_for_ip = true

    disk {
        sr_id = data.xenorchestra_sr.iscsi.id
        name_label = "${var.vm_name_prefix}${random_id.controllers[count.index].hex}"
        size = var.vm_disk_size_gb * 1024 * 1024 * 1024 # GB to B
    }

    tags = [
      "ubuntu20.04",
      "kubernetes",
      "ansible",
      "terraform-managed",
      "kubernetes.io/role:master"
    ]

}

### Worker Nodes

resource "random_id" "workers" {
  count = var.vm_count_workers
  byte_length = 8
}

resource "xenorchestra_cloud_config" "workers" {
  count = var.vm_count_workers

  name = "cloud config name"
  template = <<EOF
#cloud-config
hostname: ${var.vm_name_prefix}${random_id.workers[count.index].hex}.${var.vm_name_suffix}
users:
  - name: ${var.username_admin}
    gecos: ${var.username_admin}
    passwd: $1$SaltSalt$YhgRYajLPrYevs14poKBQ0
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${var.public_key_admin}
  - name: ${var.username_ansible}
    gecos: ${var.username_ansible}
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${var.public_key_ansible}

runcmd:
  - reboot 

packages:
  - xe-guest-utilities

EOF
}

resource "xenorchestra_vm" "workers" {
    count = var.vm_count_workers

    memory_max = var.vm_memory_size_gb * 1024 * 1024 * 1024 # GB to B
    cpus = var.vm_cpu_count
    name_label = "${var.vm_name_prefix}${random_id.workers[count.index].hex}.${var.vm_name_suffix}"
    name_description = "Ubuntu 20.04 Kubernetes worker node"
    template = data.xenorchestra_template.vm_template.id
    cloud_config = xenorchestra_cloud_config.workers[count.index].template

    network {
        network_id = data.xenorchestra_network.network.id
    }

    wait_for_ip = true

    disk {
        sr_id = data.xenorchestra_sr.iscsi.id
        name_label = "${var.vm_name_prefix}${random_id.workers[count.index].hex}"
        size = var.vm_disk_size_gb * 1024 * 1024 * 1024 # GB to B
    }

    tags = [
      "ubuntu20.04",
      "kubernetes",
      "ansible",
      "terraform-managed",
      "kubernetes.io/role:worker"
    ]
}

# Future / set additional cnames to cluster
#resource "dns_a_record_set" "vm_dns" {
#  count = length(var.vm_names)

#  zone = "${var.dns_search_domain}."
#  name = "${var.vm_names[count.index]}"
#  addresses = [
#    "${var.vm_ipv4_addresses[count.index]}",
#  ]
#}

output "k8s-controller-hostnames" {
  value = xenorchestra_vm.controllers[*].name_label
}

output "k8s-controller-ipv4" {
  value = xenorchestra_vm.controllers[*].network[0].ipv4_addresses[0]
}

output "k8s-worker-hostnames" {
  value = xenorchestra_vm.workers[*].name_label
}

output "k8s-worker-ipv4" {
  value = xenorchestra_vm.workers[*].network[0].ipv4_addresses[0]
}