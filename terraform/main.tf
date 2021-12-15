## Data

data "xenorchestra_pool" "pool" {
  name_label = "xcp-ng-01"
}

data "xenorchestra_template" "vm_template" {
  name_label = "ubuntu-focal-20.04-cloudimg-20211202-iscsi"
}

data "xenorchestra_sr" "sr" {
  name_label = "Local storage"
  pool_id = data.xenorchestra_pool.pool.id
}

data "xenorchestra_sr" "iscsi" {
  name_label = "iscsi-vm-store"
  pool_id = data.xenorchestra_pool.pool.id
}

data "xenorchestra_network" "network" {
  name_label = "50-shopnet"
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
hostname: ${var.vm_name_prefix}-${random_id.controllers[count.index].hex}
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

packages:
  - xe-guest-utilities

runcmd:
  - reboot  
EOF
}

resource "xenorchestra_vm" "controllers" {
    count = var.vm_count_controllers

    memory_max = var.vm_memory_size_gb * 1024 * 1024 * 1024 # GB to B
    cpus = var.vm_cpu_count
    name_label = "${var.vm_name_prefix}-${random_id.controllers[count.index].hex}"
    name_description = "Ubuntu 20.04 Kubernetes controller node"
    template = data.xenorchestra_template.vm_template.id
    cloud_config = xenorchestra_cloud_config.controllers[count.index].template

    network {
        network_id = data.xenorchestra_network.network.id
    }

    disk {
        sr_id = data.xenorchestra_sr.iscsi.id
        name_label = "${var.vm_name_prefix}-${random_id.controllers[count.index].hex}"
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
hostname: ${var.vm_name_prefix}-${random_id.workers[count.index].hex}
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

packages:
  - xe-guest-utilities

runcmd:
  - reboot 
EOF
}

resource "xenorchestra_vm" "workers" {
    count = var.vm_count_workers

    memory_max = var.vm_memory_size_gb * 1024 * 1024 * 1024 # GB to B
    cpus = var.vm_cpu_count
    name_label = "${var.vm_name_prefix}-${random_id.workers[count.index].hex}"
    name_description = "Ubuntu 20.04 Kubernetes worker node"
    template = data.xenorchestra_template.vm_template.id
    cloud_config = xenorchestra_cloud_config.workers[count.index].template

    network {
        network_id = data.xenorchestra_network.network.id
    }

    disk {
        sr_id = data.xenorchestra_sr.iscsi.id
        name_label = "${var.vm_name_prefix}-${random_id.workers[count.index].hex}"
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

output "k8s-controller-hostnames" {
  value = xenorchestra_vm.controllers[*].name_label
}

output "k8s-worker-hostnames" {
  value = xenorchestra_vm.workers[*].name_label
}