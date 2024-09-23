terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Cluster 1
variable "cluster2_nodes" {
  type = list(string)
  default = ["ocp4-node0-cluster2", "ocp4-node1-cluster2", "ocp4-node2-cluster2"]
}


# Nodes for Cluster 1
resource "libvirt_volume" "rootdisk-cluster2" {
  name   = "rootdisk-${element(var.cluster2_nodes, count.index)}"
  pool   = "default"
  size   = 120000000000 
  format = "qcow2"
  count  = "${length(var.cluster2_nodes)}"
}

resource "libvirt_volume" "volume-mon-workers" {
  name   = "volume-mon-${element(var.cluster2_nodes, count.index)}"
  pool   = "default"
  size   = "30000000000"
  format = "qcow2"
  count = "${length(var.cluster2_nodes)}"
}
resource "libvirt_volume" "volume-osd1-workers" {
  name   = "volume-osd1-${element(var.cluster2_nodes, count.index)}"
  pool   = "default"
  size   = "30000000000"
  format = "qcow2"
  count = "${length(var.cluster2_nodes)}"
}
resource "libvirt_volume" "volume-osd2-workers" {
  name   = "volume-osd2-${element(var.cluster2_nodes, count.index)}"
  pool   = "default"
  size   = "30000000000"
  format = "qcow2"
  count = "${length(var.cluster2_nodes)}"
}
resource "libvirt_volume" "volume-osd3-workers" {
  name   = "volume-osd3-${element(var.cluster2_nodes, count.index)}"
  pool   = "default"
  size   = "80000000000"
  format = "qcow2"
  count = "${length(var.cluster2_nodes)}"
}


resource "libvirt_domain" "nodes-cluster2" {
  name   = "${element(var.cluster2_nodes, count.index)}"
  memory = "96000"  
  vcpu   = 32      
  cpu {
    mode = "host-passthrough"
  }
  boot_device {
      dev = ["hd","cdrom"]
  }
  network_interface {
    network_name = "lab-net"
    mac = "AA:BB:CC:11:43:2${count.index}"
  }
  network_interface {
    network_name = "lab-net"
    mac = "AA:BB:CC:11:43:5${count.index}"
  }
  network_interface {
    network_name = "vm-net"
    mac = "AA:BB:CC:11:43:6${count.index}"
  }
  network_interface {
    network_name = "storage-net"
    mac = "AA:BB:CC:11:43:7${count.index}"
  }
  #    network_interface {
  #    network_name = "osp-trunk-network"
  #    mac = "AA:BB:CC:11:43:7${count.index}"
  #  }

  disk {
      file = "/var/lib/libvirt/images/discovery_image.iso"
    }
  disk {
    volume_id = "${element(libvirt_volume.rootdisk-cluster2.*.id, count.index)}"  
  }
  disk {
    volume_id = "${element(libvirt_volume.volume-mon-workers.*.id, count.index)}"
  }
  disk {
    volume_id = "${element(libvirt_volume.volume-osd1-workers.*.id, count.index)}"
  }
  disk {
    volume_id = "${element(libvirt_volume.volume-osd2-workers.*.id, count.index)}"
  }
  disk {
    volume_id = "${element(libvirt_volume.volume-osd3-workers.*.id, count.index)}"
  }

  
  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }


  running = true

  count = "${length(var.cluster2_nodes)}"
}

