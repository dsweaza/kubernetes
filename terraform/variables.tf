# Set these variables in environment or terraform.tfvars

variable "vm_name_prefix" {
    type = string 
    default = "us20-"
}

variable "vm_name_suffix" {
    type = string
    default = "k8s.dylanlab.xyz"
}

variable "vm_count_controllers" {
    type = number
    default = 5
}

variable "vm_count_workers" {
    type = number
    default = 5
}

variable "vm_disk_size_gb" {
    default = 30
    type    = number
}

variable "vm_memory_size_gb" {
    default = 4
    type    = number
}

variable "vm_cpu_count" {
    default = 2
    type    = number
}

variable "username_ansible" {
    description = "Ansible account username"
    type = string
    default = "ansible"
}

variable "public_key_ansible" {
    type = string
    description = "Ansible account authorized key"
}

variable "username_admin" {
    description = "Administrator account username"
    type = string
    default = "admin"
}

variable "public_key_admin" {
    type = string
    description = "Administrator account authorized key"
}