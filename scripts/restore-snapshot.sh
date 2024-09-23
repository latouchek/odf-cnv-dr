#!/bin/bash

# List of VMs to restore
VMS=("ocp4-node0-cluster1" "ocp4-node0-cluster2" "ocp4-node1-cluster1" "ocp4-node1-cluster2" "ocp4-node2-cluster1" "ocp4-node2-cluster2" "ocp4-sno")

# Function to restore snapshots for each VM
restore_vms() {
    for VM in "${VMS[@]}"; do
        echo "Restoring snapshot for $VM..."
        virsh snapshot-revert --domain "$VM" "${VM}-snapshot" --force
        
        if [ $? -eq 0 ]; then
            echo "Snapshot for $VM restored successfully."
        else
            echo "Failed to restore snapshot for $VM."
        fi
    done
}

# Call the function
restore_vms
