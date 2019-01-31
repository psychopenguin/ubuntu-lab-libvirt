provider "libvirt" {
  uri = "qemu:///system"
}

# Base image to build instances
# resource "libvirt_volume" "ubuntu_image" {
#  name = "${var.ubuntu_release}.img"
#  pool = "isos"
# source = "https://cloud-images.ubuntu.com/${var.ubuntu_release}/current/${var.ubuntu_release}-server-cloudimg-amd64.img"
#}

# Cloud init templates

data "template_file" "user_data" {
  count    = "${var.instance["count"]}"
  template = "${file("${path.module}/cloud_init.cfg")}"

  vars {
    hostname = "${var.instance["base_name"]}-${count.index}"
  }
}

data "template_file" "network_config" {
  count    = "${var.instance["count"]}"
  template = "${file("${path.module}/network_config.cfg")}"
}

resource "libvirt_cloudinit_disk" "cloud_init" {
  count          = "${var.instance["count"]}"
  pool           = "vm_images"
  name           = "${var.instance["base_name"]}-${count.index}-cloud_init.iso"
  user_data      = "${element(data.template_file.user_data.*.rendered, count.index)}"
  network_config = "${element(data.template_file.network_config.*.rendered, count.index)}"
}

# Root disk for each instance

resource "libvirt_volume" "boot_disk" {
  count            = "${var.instance["count"]}"
  pool             = "vm_images"
  base_volume_name = "${var.ubuntu_release}.img"
  base_volume_pool = "isos"
  size             = "${var.instance["disksize"]}"
  name             = "${var.instance["base_name"]}-${count.index}-boot_disk.img"
}

# Virtual Machines

resource "libvirt_domain" "vm" {
  count     = "${var.instance["count"]}"
  name      = "${var.instance["base_name"]}-${count.index}"
  memory    = "${var.instance["memory"]}"
  vcpu      = "${var.instance["vcpu"]}"
  cloudinit = "${element(libvirt_cloudinit_disk.cloud_init.*.id, count.index)}"

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  disk {
    volume_id = "${element(libvirt_volume.boot_disk.*.id, count.index)}"
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }
}

# Show vm ip address in the end
output "ips" {
  value = "${libvirt_domain.vm.*.network_interface.0.addresses}"
}
