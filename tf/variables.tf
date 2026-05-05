variable "region" {
  type    = string
  default = "us-east-1"
}

variable "key_name" {
  type = string
}

variable "nfs_server_instance_type" {
  type    = string
  default = "m5.2xlarge"
}

variable "nfs_server_disk_throughput" {
  type    = number
  default = 250
}

variable "nfs_server_disk_iops" {
  type    = number
  default = 16000
}

variable "client_instance_type" {
  type    = string
  default = "m5.2xlarge"
}

variable "server_nodes" {
  type    = number
  default = 3
}

variable "server_instance_type" {
  type    = string
  default = "m5.2xlarge"
}

variable "server_disk_throughput" {
  type    = number
  default = 250
}

variable "server_disk_iops" {
  type    = number
  default = 16000
}
