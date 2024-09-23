

# Deploying ODF Metro-DR for OpenShift Virtualization

This document outlines the deployment process for **OpenShift Data Foundation (ODF) Metro-DR** within an OpenShift Virtualization environment. Although demonstrated in a virtualized lab setting, the instructions are applicable to bare-metal environments as well.

## Architecture Overview

The following ASCII diagram illustrates the deployment architecture for ODF Metro-DR. The networks are represented by horizontal lines, and each cluster is mapped to its respective network. At the bottom, the KVM hypervisor is shown as a full-width rectangle, hosting all clusters.



```
Machine Network: 10.17.3.0/24      Storage Network: 10.17.5.0/24      VM Network: 10.17.4.0/24
-----------------------------------------------------------------------------------------------
                 |                               |                               |
            +----------+                   +----------+                   +----------+
            | Cluster1 |                   | Cluster2 |                   | SNO-Hub  |
            | (ODF +   |                   | (ODF +   |                   | (ACM     |
            | CNV)     |                   | CNV)     |                   | Managed) |
            +----------+                   +----------+                   +----------+
-----------------------------------------------------------------------------------------------
+---------------------------------------------------------------------------------------------+
|                               KVM Hypervisor                                                |
|                                                                                             |
|       Hosts all virtualized clusters: Cluster1, Cluster2, and SNO-Hub                       |
+---------------------------------------------------------------------------------------------+
```

---

## Prerequisites

Before starting the deployment, ensure the following prerequisites are met:

- **Three OpenShift Container Platform (OCP) clusters**:
  - **Cluster1**: Hosts ODF and CNV.
  - **Cluster2**: Hosts ODF and CNV.
  - **SNO-Hub**: Serves as the hub cluster with Advanced Cluster Management (ACM) installed.
- **Administrative access** to all clusters.
- **OpenShift CLI (`oc`)** installed on the Bastion machine.
- **Valid pull secret** for OpenShift authentication.

---

## 1. Preparing the ACM Hub Cluster

### 1.1 Importing Cluster1 and Cluster2 into ACM


To centrally manage your OpenShift clusters, they need to be imported into the Advanced Cluster Management (ACM) hub. This allows for unified monitoring, policy enforcement, and overall cluster management.
#### Method 1: Using the GUI

1. **Navigate to the ACM Console** on the SNO-Hub cluster.
2. Click on **"Clusters"** in the left navigation pane.
3. Click on **"Import Cluster"**.

   ![Import Cluster Step 1](pix/Import-cluster/Screenshot%20from%202024-09-18%2013-17-33.png)

4. Enter the **Cluster Name** (e.g., `cluster2`) and click **"Generate Command"**.

   ![Import Cluster Step 2](pix/Import-cluster/Screenshot%20from%202024-09-18%2013-17-52.png)

5. Copy the content of cluster2 kubeconfig 

   ![Import Cluster Step 3](pix/Import-cluster/Screenshot%20from%202024-09-18%2013-18-04.png)

   ![Import Cluster Step 4](pix/Import-cluster/Screenshot%20from%202024-09-18%2013-18-50.png)

   ![Import Cluster Step 4](pix/Import-cluster/Screenshot%20from%202024-09-18%2013-19-05.png)

6. Click **"Import"** and allow ACM to process the import.

    ![Import Cluster Step 4](pix/Import-cluster/Screenshot%20from%202024-09-18%2013-19-12.png)
    ![Import Cluster Step 4](pix/Import-cluster/Screenshot%20from%202024-09-18%2013-19-22.png)

7. Wait for the cluster status to change to **Ready**.
    ![Import Cluster Step 4](pix/Import-cluster/Screenshot%20from%202024-09-18%2013-19-36.png)
    ![Import Cluster Step 4](pix/Import-cluster/Screenshot%20from%202024-09-18%2013-19-54.png)

8. Repeat the same steps for **Cluster1**.

#### Method 2: Using the CLI

In progress

---

### 1.2 Creating a ClusterSet

In ACM, a ClusterSet is a logical grouping of clusters that allows you to manage them as a single entity. This simplifies tasks like policy enforcement, application deployment, and resource management across multiple clusters.

1. Apply the ManagedClusterSet manifest by running the following command:

   ```shell
   oc apply -f manifests/managedclusterset.yaml
   ```

   Where `managedclusterset.yaml` contains:

   ```yaml
   apiVersion: cluster.open-cluster-management.io/v1beta1
   kind: ManagedClusterSet
   metadata:
     name: saq-dr-clusterset
   ```

---

### 1.3 Adding Clusters to the ClusterSet

Once the ClusterSet is created, the next step is to add **Cluster1** and **Cluster2** to it. This allows centralized management, making it easier to enforce policies and deploy applications consistently across all clusters in the set.


#### Method: Using the GUI

1. **Navigate to Cluster sets** in the ACM Console.

2. Click on **"Create cluster set"**.

   ![Add to ClusterSet Step 1](pix/clusterset/Screenshot%20from%202024-09-18%2014-26-50.png)

3. Choose your cluster set name and confirm.

   ![Add to ClusterSet Step 2](pix/clusterset/Screenshot%20from%202024-09-18%2014-26-59.png)

4. Click on **"Manage resource assignments"**.

   ![Add to ClusterSet Step 2](pix/clusterset/Screenshot%20from%202024-09-18%2014-27-08.png)

5. Select *cluster1* and *cluster2* 

   ![Add to ClusterSet Step 2](pix/clusterset/Screenshot%20from%202024-09-18%2014-27-25.png)

6. Confirm changes and save

   ![Add to ClusterSet Step 2](pix/clusterset/Screenshot%20from%202024-09-18%2014-27-33.png)
---

### 1.4 Installing the ODF Multicluster Orchestrator Operator

To manage ODF in a multi-cluster environment, the **ODF Multicluster Orchestrator Operator** needs to be installed. Follow the steps below to install it:

1. In the ACM Console, navigate to **"Operators"** > **"OperatorHub"**.
2. Search for **"ODF Multicluster Orchestrator"**.
3. Click on the operator and select **"Install"**.

   ![Install ODF Multicluster Orchestrator Step 1](pix/operator-hub/Screenshot%20from%202024-09-18%2014-17-39.png)

4. Choose the appropriate **installation options** and proceed.

   ![Install ODF Multicluster Orchestrator Step 2](pix/operator-hub/Screenshot%20from%202024-09-18%2014-17-49.png)

---

## 2. Installing ODF on Cluster1 and Cluster2

### Method 1: Using the GUI

For a graphical interface, follow the steps outlined in the pix/ODF directory, which provides detailed instructions for installation on cluster1 and cluster2

### Method 2: Using the CLI and ACM policies

Alternatively, you can use an ACM policy to install ODF via the command line. This policy is available in the policies directory of the repository.

To apply the ODF policy, use the following command:

```shell
oc apply -f policies/odf-policy.yaml
```
After applying the policy, verify the resources were successfully created on Cluster1 and Cluster2 by running:

```shell
oc get storageclusters.ocs.openshift.io -n openshift-storage
NAME                 AGE     PHASE   EXTERNAL   CREATED AT             VERSION
ocs-storagecluster   7h59m   Ready              2024-09-18T13:43:03Z   4.16.2

```
Next, check the status of the pods in the openshift-storage namespace:

```shell
oc get pod -n openshift-storage

```
The output will list all the running pods, for example:

```bash
NAME                                                              READY   STATUS      RESTARTS        AGE
csi-addons-controller-manager-68cc4dff7d-t8cwh                    2/2     Running     2               8h
csi-cephfsplugin-lrvrr                                            2/2     Running     3               8h
csi-cephfsplugin-provisioner-7676c8956c-dpgdj                     6/6     Running     10              8h
csi-cephfsplugin-provisioner-7676c8956c-m4b4k                     6/6     Running     7               8h
csi-cephfsplugin-vnsq2                                            2/2     Running     3               8h
csi-cephfsplugin-wrvwl                                            2/2     Running     3               8h
csi-nfsplugin-crd44                                               2/2     Running     3               8h
csi-nfsplugin-dk49t                                               2/2     Running     3               8h
csi-nfsplugin-provisioner-766bd6568-d928z                         5/5     Running     6               8h
csi-nfsplugin-provisioner-766bd6568-wwbnf                         5/5     Running     9               8h
csi-nfsplugin-xq5gc                                               2/2     Running     3               8h
csi-rbdplugin-6dk9h                                               3/3     Running     4               8h
csi-rbdplugin-h2zqm                                               3/3     Running     4               8h
csi-rbdplugin-provisioner-858c6d67c6-bt4vf                        6/6     Running     7               8h
csi-rbdplugin-provisioner-858c6d67c6-mn492                        6/6     Running     11              8h
csi-rbdplugin-x4hzn                                               3/3     Running     7 (4h51m ago)   8h
noobaa-core-0                                                     2/2     Running     2               7h58m
noobaa-db-pg-0                                                    1/1     Running     1               7h58m
noobaa-endpoint-64d79d8fd4-nkmrf                                  1/1     Running     1               7h57m
noobaa-operator-6754dbd74d-jh5gl                                  1/1     Running     1               8h
ocs-metrics-exporter-56c557c7b7-cqwnr                             1/1     Running     1               7h58m
ocs-operator-5f67fc986-cbr88                                      1/1     Running     3 (4h48m ago)   8h
odf-console-6c7d54f86d-xxs6c                                      1/1     Running     1               8h
odf-operator-controller-manager-67c5f7677-cxkzn                   2/2     Running     2               8h
rook-ceph-crashcollector-ocp4-master0.cluster2.lab.local-76m96z   1/1     Running     1               7h58m
rook-ceph-crashcollector-ocp4-master1.cluster2.lab.local-76xdg9   1/1     Running     1               7h58m
rook-ceph-crashcollector-ocp4-master2.cluster2.lab.local-7xnpkb   1/1     Running     1               7h58m
rook-ceph-exporter-ocp4-master0.cluster2.lab.local-545b6fbhzqcp   1/1     Running     1               7h58m
rook-ceph-exporter-ocp4-master1.cluster2.lab.local-56d4fc5p5vrs   1/1     Running     1               7h58m
rook-ceph-exporter-ocp4-master2.cluster2.lab.local-78d6777tjd57   1/1     Running     1               7h58m
rook-ceph-mds-ocs-storagecluster-cephfilesystem-a-8569d484vbtwv   2/2     Running     2               7h58m
rook-ceph-mds-ocs-storagecluster-cephfilesystem-b-65b6c5742vr8h   2/2     Running     2               7h58m
rook-ceph-mgr-a-65d8487749-b2xm6                                  3/3     Running     3               7h59m
rook-ceph-mgr-b-8485f7566d-wfpmv                                  3/3     Running     3               7h59m
rook-ceph-mon-a-9645c469c-mc64h                                   2/2     Running     2               8h
rook-ceph-mon-b-594d478f64-ks6ll                                  2/2     Running     2               8h
rook-ceph-mon-c-5959d58478-rf5s2                                  2/2     Running     2               7h59m
rook-ceph-nfs-ocs-storagecluster-cephnfs-a-6cbb74d974-t5m5l       2/2     Running     2               7h58m
rook-ceph-operator-5f87c78878-2wqcl                               1/1     Running     1               8h
rook-ceph-osd-0-67f8d77fd-xx4lv                                   2/2     Running     2               7h58m
rook-ceph-osd-1-68f8dfc7bf-jh297                                  2/2     Running     2               7h58m
rook-ceph-osd-10-77c7d79b64-9prf2                                 2/2     Running     2               7h58m
rook-ceph-osd-11-6f58f68846-9scfv                                 2/2     Running     2               7h58m
rook-ceph-osd-2-5d4d4f6dc-bbkkg                                   2/2     Running     2               7h58m
```
---

## 3. Installing OpenShift Virtualization (CNV) on Cluster1 and Cluster2

To install OpenShift Virtualization (CNV) on Cluster1 and Cluster2, we will use an ACM policy to simplify the process.

### Steps:

1. Apply the CNV policy:

   ```shell
   oc apply -f policies/cnv-policy.yaml
   ```


---

## 4. Setting Up Submariner for Network Connectivity

Submariner enables seamless network connectivity between clusters located in different network environments. Follow the steps below to install and configure Submariner using the ACM Console.

### Steps:

1. In the ACM Console, navigate to **"Clusters sets"**.
2. Click on **"Install Submariner add-ons"**.

   ![Install Submariner Step 1](pix/submariner/Screenshot%20from%202024-09-18%2014-33-28.png)

4. Configure the necessary settings and proceed with the installation.

   ![Install Submariner Step 2](pix/submariner/Screenshot%20from%202024-09-18%2014-33-45.png)

   Select cluster1 and cluster2 in dropdown menu

   ![Install Submariner Step 2](pix/submariner/Screenshot%20from%202024-09-18%2014-33-52.png)
   Click *Next*

   ![Install Submariner Step 2](pix/submariner/Screenshot%20from%202024-09-18%2014-34-06.png)

   Click *Install*
   ![Install Submariner Step 2](pix/submariner/Screenshot%20from%202024-09-18%2014-34-18.png)

5. Wait for installation to complete
  ![Install Submariner Step 2](pix/submariner/Screenshot%20from%202024-09-18%2014-36-57.png)

### 4.1 Verifying Connectivity Between Clusters

After Submariner is installed, you can verify the network connectivity between **Cluster1** and **Cluster2** by following these steps:

1. Access **Cluster1** and **Cluster2** using the OpenShift CLI.
2. On **Cluster1**, run the following command to test connectivity to **Cluster2**:

   ```shell
   oc --kubeconfig=./kube/config-cluster1 exec -n submariner-operator <submariner-gateway-pod-name> -- ping <cluster2-service-ip>
 
   ```

   Replace <submariner-gateway-pod-name> with the name of the Submariner Gateway pod running on Cluster1, and <cluster2-service-ip> with a service IP from Cluster2.

    Similarly, test connectivity from Cluster2 to Cluster1:


   ```shell

      oc --kubeconfig=./kube/config-cluster2 exec -n submariner-operator <submariner-gateway-pod-name> -- ping <cluster1-service-ip>
   ```
   If the ping command returns a successful response, it confirms that the clusters are connected via Submariner.


## 5. Configuring SSL Access Between S3 Endpoints

To ensure secure transport of metadata between clusters, we need to configure SSL access for the S3 endpoints. These steps are required to store metadata securely in a Multi-Cloud Gateway (MCG) object bucket on an alternate cluster. Additionally, the Hub cluster must be able to verify access to the object buckets.

**Note**: If all your OpenShift clusters are deployed using signed and valid certificates for your environment, you can skip this section.

### 5.1 Extracting Ingress Certificates

To begin, you need to extract the ingress certificates from both the primary and secondary managed clusters.

#### Step 1: Extract the Ingress Certificate from the Primary Managed Cluster

Use the following command to extract the ingress certificate from the primary cluster and save it to a file named `primary.crt`:

```bash
oc get cm default-ingress-cert -n openshift-config-managed \
  -o jsonpath="{['data']['ca-bundle\.crt']}" \
  --kubeconfig=./kube/config-cluster1 > certs/primary.crt
```

#### Step 2: Extract the Ingress Certificate from the Secondary Managed Cluster

Similarly, extract the ingress certificate from the secondary cluster and save it as `secondary.crt`:

```bash
oc get cm default-ingress-cert -n openshift-config-managed \
  -o jsonpath="{['data']['ca-bundle\.crt']}" \
  --kubeconfig=./kube/config-cluster2 > certs/secondary.crt
```  
### 5.2 Creating the ConfigMap with Certificates

Create a new YAML file named `cm-clusters-crt.yaml` to hold the certificate bundles from both the primary and secondary managed clusters.

**Note**: There could be more or fewer than three certificates for each cluster, so adjust accordingly.

Here is an example of the ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-ca-bundle
  namespace: openshift-config
data:
  ca-bundle.crt: |
    -----BEGIN CERTIFICATE-----
    <copy contents of cert1 from primary.crt here>
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    <copy contents of cert2 from primary.crt here>
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    <copy contents of cert3 from primary.crt here>
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    <copy contents of cert1 from secondary.crt here>
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    <copy contents of cert2 from secondary.crt here>
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    <copy contents of cert3 from secondary.crt here>
    -----END CERTIFICATE-----
```

**Instructions**:

1. Open `primary.crt` and `secondary.crt` with a text editor.

2. Copy the contents of each certificate from `primary.crt` and paste them into the `ca-bundle.crt` section of `cm-clusters-crt.yaml`, between `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----`.

3. Repeat this process for all certificates in both `primary.crt` and `secondary.crt`.

**Example**:

If `primary.crt` contains:

```
-----BEGIN CERTIFICATE-----
MIID...
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIE...
-----END CERTIFICATE-----
```

And `secondary.crt` contains:

```
-----BEGIN CERTIFICATE-----
MIIA...
-----END CERTIFICATE-----
```

Then your `ca-bundle.crt` section should look like:

```yaml
data:
  ca-bundle.crt: |
    -----BEGIN CERTIFICATE-----
    MIID...
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIIE...
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIIA...
    -----END CERTIFICATE-----
```
### 5.3 Generating the ConfigMap with Certificates

To automate the creation of the `cm-clusters-crt.yaml` file containing the combined certificates from both clusters, we will use the `assemble-certs.sh` script located in the `certs` directory.

#### Using the `assemble-certs.sh` Script

The `assemble-certs.sh` script reads the `primary.crt` and `secondary.crt` files and generates the `cm-clusters-crt.yaml` file in the `manifests` directory.



##### Steps to Use the Script

1. **Run the Script**:

   ```bash
   cd certs
   bash assemble-certs.sh
   ```

   This will generate the `cm-clusters-crt.yaml` file in the `manifests` directory.

2. **Verify the Generated ConfigMap**:

   ```bash
   cat ../manifests/cm-clusters-crt.yaml
   ```

   Ensure that the certificates from both `primary.crt` and `secondary.crt` are included properly.

### 5.4 Applying the ConfigMap to All Clusters

Once the cm-clusters-crt.yaml file is generated, the next step is to apply it to the primary, secondary, and hub clusters to ensure secure communication.

#### Applying the ConfigMap Manually

Use the following commands to apply the ConfigMap to each cluster:

```bash
oc --kubeconfig=./kube/config-cluster1 apply -f manifests/cm-clusters-crt.yaml
oc --kubeconfig=./kube/config-cluster2 apply -f manifests/cm-clusters-crt.yaml
oc --kubeconfig=./kube/config-hub-cluster apply -f manifests/cm-clusters-crt.yaml
```
Expected output. (Don't mind the warning) 
```bash
configmap/user-ca-bundle created
configmap/user-ca-bundle created
Warning: resource configmaps/user-ca-bundle is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by oc apply. oc apply should only be used on resources created declaratively by either oc create --save-config or oc apply. The missing annotation will be patched automatically.
configmap/user-ca-bundle configured

```

### 5.5 Patching the Proxy Resource

After applying the ConfigMaps with the new certificates, it’s important to ensure that the clusters are aware of and trust these certificates for secure communication. In OpenShift, the **Proxy** resource is responsible for managing external network communication and uses the trusted certificate authority (CA) bundle to validate secure connections.

By patching the **Proxy** resource, we are updating each cluster to use the newly applied **user-ca-bundle** ConfigMap as the trusted CA for these operations. This step ensures that the clusters can securely communicate with external services and each other, leveraging the certificates we have just set up.

#### Steps to Patch the Proxy Resource:

1. Patch the **Proxy** resource on **Cluster1** with the following command:

   ```bash
   oc --kubeconfig=./kube/config-cluster1 patch proxy cluster --type=merge --patch='{"spec":{"trustedCA":{"name":"user-ca-bundle"}}}'
   ```

2. Repeat the patch for **Cluster2** using this command:

   ```bash
   oc --kubeconfig=./kube/config-cluster2 patch proxy cluster --type=merge --patch='{"spec":{"trustedCA":{"name":"user-ca-bundle"}}}'
   ```

3. Finally, patch the **Proxy** resource on the **Hub** cluster:

   ```bash
   oc --kubeconfig=./kube/config-hub-cluster patch proxy cluster --type=merge --patch='{"spec":{"trustedCA":{"name":"user-ca-bundle"}}}'
   ```

#### Verification:

If the patch is applied successfully, you should see the following output:

```bash
proxy.config.openshift.io/cluster patched
```

This output confirms that the **Proxy** on each cluster is now using the specified **user-ca-bundle** ConfigMap as the trusted CA, ensuring secure and validated communications.


### 6. Creating a Disaster Recovery (DR) Policy

In this section, we will walk through creating a **Disaster Recovery (DR) Policy** that automates failover and data replication between **Cluster1** and **Cluster2**. This policy leverages several key components of OpenShift Data Foundation (ODF) to ensure data redundancy and availability across clusters in case of an outage.

#### Key Components Involved:
- **DRCluster**: Defines the participating clusters in the DR setup (primary and secondary).
- **DRPolicy**: Specifies the rules for replication and failover between clusters.
- **VolumeReplicationClass**: Governs replication strategies for persistent volumes.
- **CephBlockPool with Mirroring**: Provides data redundancy through mirroring across clusters.
- **Ramen Operator**: Manages the orchestration of DR activities, including failover and recovery.
- **Object Buckets**: Store metadata for persistent volumes (PVs) and persistent volume claims (PVCs).
- **VolSync Operator**: Ensures data consistency between clusters by synchronizing persistent volumes.

#### Steps to Create the DR Policy:

1. **Navigate to the Disaster Recovery section**:
   - In the OpenShift Web Console, go to **Data Services** > **Disaster Recovery**.
   
2. **Create a New DR Policy**:
    ![DR Policy](pix/drpolicy/Screenshot%20from%202024-09-19%2006-53-25.png)
   - Click **Create a disaster recovery policy**.
   - Provide a **name** for the DR policy (e.g., `dr-policy-cluster1-cluster2`).
    ![DR Policy](pix/drpolicy/Screenshot%20from%202024-09-19%2006-53-45.png)
   - Select **Cluster1** as the primary cluster and **Cluster2** as the secondary cluster.

3. **Configure the Replication Policy**:
   - Set the **Replication Policy** to **asynchronous** (async). This mode replicates data at defined intervals rather than in real-time.
   - Define the **sync schedule**, e.g., every 5 minutes, to control how often data is replicated between **Cluster1** and **Cluster2**.
    ![Replication Policy Configuration](pix/drpolicy/Screenshot%20from%202024-09-19%2006-54-17.png)

4. **Deploy the DR Policy**:
   - Click **Create** to deploy the DR policy. Once done, the system will set up the DR components across the clusters, including the DRClusters, CephBlockPool mirroring, and VolumeReplicationClass.
   ![Create DRPolicy Step](pix/drpolicy/Screenshot%20from%202024-09-19%2006-54-39.png)


5. **Monitor Deployment**:
   - Once the DR policy is created, you can monitor its progress. When fully deployed, the status of the DR policy will change to **Validated**.
   ![Create DRPolicy Step](pix/drpolicy/Screenshot%20from%202024-09-19%2006-56-00.png)#### Example Commands to Verify Installed Components:

You can use the following commands to view and check the status of the key components installed as part of the DR policy.

1. **Check the CephBlockPool configuration**:
   
   To see if the **CephBlockPool** is set up with mirroring, run the following command:

   ```bash
   oc describe cephblockpools ocs-storagecluster-cephblockpool -n openshift-storage
   ```

   Example output:

   ```bash
   Name:         ocs-storagecluster-cephblockpool
   Namespace:    openshift-storage
   Spec:
     Mirroring:
       Enabled:  true
       Mode:     image
   ```

   This confirms that mirroring is enabled in **image** mode, meaning that each individual volume is mirrored between the clusters.

2. **Verify the VolumeReplicationClass**:
   
   To verify the configuration of the **VolumeReplicationClass**, which controls how often data is replicated, use:

   ```bash
   oc describe volumereplicationclasses.replication.storage.openshift.io <volume-replication-class-name>
   ```

   Example output:

   ```bash
   Name:         rbd-volumereplicationclass-1625360775
   Spec:
     Mirroring Mode:           snapshot
     Scheduling Interval:      5m
   ```

   This shows that data replication is done every 5 minutes (`5m`) in **snapshot** mode.

3. **Check the status of object buckets**:
   
   Object buckets store metadata for PVCs and PVs. To see the status of the object buckets created for disaster recovery, run:

   ```bash
   oc get objectbuckets -n openshift-storage
   ```

   Example output:

   ```bash
   NAME                                           STORAGE-CLASS                 PHASE
   obc-openshift-storage-odrbucket-b1b922184baf   openshift-storage.noobaa.io    Bound
   ```

   This shows that the object bucket is in the **Bound** phase, meaning it is correctly configured and active.

4. **Check the Ramen Operator status**:
   
   The **Ramen Operator** coordinates the entire DR process. To confirm it’s running, use:

   ```bash
   oc get operators -n openshift-dr-system
   ```

   Example output:

   ```bash
   NAME                                             AGE
   odr-cluster-operator.openshift-dr-system         5h5m
   ```

   This confirms that the Ramen operator, labeled as `odr-cluster-operator`, is active in the **openshift-dr-system** namespace.


### 7. Testing Disaster Recovery with real life scenario

In progress
