#!/bin/bash

# List of VMs for each cluster
CLUSTER1_VMS=("ocp4-node0-cluster1" "ocp4-node1-cluster1" "ocp4-node2-cluster1")
CLUSTER2_VMS=("ocp4-node0-cluster2" "ocp4-node1-cluster2" "ocp4-node2-cluster2")
SNO_VM=("ocp4-sno")

# Kubeconfig files for each cluster
KUBECONFIG_CLUSTER1="./kube/config-cluster1"
KUBECONFIG_CLUSTER2="./kube/config-cluster2"
KUBECONFIG_SNO="./kube/config-hub-cluster"

# Function to start a group of VMs and check if the cluster is up
start_vms_and_wait_for_cluster() {
    local kubeconfig=$1
    shift  # Remove the kubeconfig from the list of arguments
    local vms=("$@")

    # Start each VM in the group
    for VM in "${vms[@]}"; do
        echo "Starting $VM..."
        virsh start "$VM"
    done

    # Wait for the cluster to be up and running
    echo "Waiting for cluster to be ready..."
    while true; do
        # Check the status of the cluster using oc
        if oc --kubeconfig="$kubeconfig" get nodes &>/dev/null; then
            echo "Cluster is up and running!"
            break
        else
            echo "Cluster not ready yet. Waiting for 30 seconds..."
            sleep 30
        fi
    done
}

# Restart Cluster 1 VMs and wait for the cluster to be up
echo "Restarting Cluster 1..."
start_vms_and_wait_for_cluster "$KUBECONFIG_CLUSTER1" "${CLUSTER1_VMS[@]}"

# Restart Cluster 2 VMs and wait for the cluster to be up
echo "Restarting Cluster 2..."
start_vms_and_wait_for_cluster "$KUBECONFIG
