terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}


resource "libvirt_volume" "fatdisk-sno" {
  name           = "fatdisk-sno"
  pool           = "default"
  size           = 120000000000
}

resource "libvirt_volume" "volume-mon-sno" {
  name   = "volume-mon-sno"
  pool   = "default"
  size   = "30000000000"
  format = "qcow2"
}
resource "libvirt_volume" "volume-osd1-sno" {
  name   = "volume-osd1-sno"
  pool   = "default"
  size   = "80000000000"
  format = "qcow2"
}
# resource "libvirt_volume" "volume-osd2-sno" {
#   name   = "volume-osd2-sno"
#   pool   = "default"
#   size   = "80000000000"
#   format = "qcow2"
# }
# resource "libvirt_volume" "volume-osd3-sno" {
#   name   = "volume-osd3-sno"
#   pool   = "default"
#   size   = "80000000000"
#   format = "qcow2"
# }

resource "libvirt_domain" "sno" {
  name   = "ocp4-sno"
  memory = "64000"
  vcpu   = 24
  cpu  {
  mode = "host-passthrough"
  }
  running = true
  boot_device {
      dev = ["hd","cdrom"]
    }
  network_interface {
    network_name = "lab-net"
    mac = "ba:bb:cc:11:82:20"
  }
   network_interface {
    network_name = "lab-net"
    mac = "ba:bb:cc:11:82:21"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id =  "${libvirt_volume.fatdisk-sno.id}"
  }
  disk {
      file = "/var/lib/libvirt/images/discovery_image_ocpd.iso"
    }
  disk {
    volume_id = "${libvirt_volume.volume-mon-sno.id}"
  }
  disk {
    volume_id = "${libvirt_volume.volume-osd1-sno.id}"
  }
  # disk {
  #   volume_id = "${libvirt_volume.volume-osd2-sno.id}"
  # }
  # disk {
  #   volume_id = "${libvirt_volume.volume-osd3-sno.id}"
  # }
 graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }
}
