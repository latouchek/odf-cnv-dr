#!/bin/bash

# List of VMs to take snapshots of
VMS=("ocp4-node0-cluster1" "ocp4-node0-cluster2" "ocp4-node1-cluster1" "ocp4-node1-cluster2" "ocp4-node2-cluster1" "ocp4-node2-cluster2" "ocp4-sno")

# Function to take a snapshot of each VM
snapshot_vms() {
    for VM in "${VMS[@]}"; do
        echo "Taking snapshot of $VM..."
        virsh snapshot-create-as --domain "$VM" "${VM}-snapshot" --description "Snapshot of $VM" --atomic
        
        if [ $? -eq 0 ]; then
            echo "Snapshot for $VM created successfully."
        else
            echo "Failed to create snapshot for $VM."
        fi
    done
}

# Call the function
snapshot_vms
