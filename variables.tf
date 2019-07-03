variable "instance" {
  default = {
    "base_name" = "ubuntu"
    "count"     = 1
    "disksize"  = 10737418240
    "memory"    = 1024
    "vcpu"      = 1
  }
}

variable "ubuntu_release" {
  default = "bionic"
}
