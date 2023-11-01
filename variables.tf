variable "master_vms" {
    type = list(string)
    default = ["master"]
}

variable "worker_vms" {
    type = list(string)
    default = ["worker"]
}

variable "admin_name" {
    type = string
    default = "azure_user"
}

variable "ansible_ssh_private_key_file" {
    type = string
    default = "~/.ssh/id_rsa.pub"
}