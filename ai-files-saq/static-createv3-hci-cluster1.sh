export AI_URL='http://10.17.3.1:8090'
export NIC_CONFIG='bond-static-cluster1'
export BASE_DNS_DOMAIN='lab.local'
export CLUSTER_NAME="cluster1"
export MACHINE_CIDR="10.17.3.0/24"
export VERSION="4.16"

#####Create cluster#####

jq -n  --arg PULLSECRET "$(cat pull-secret.json)" --arg SSH_KEY "$(cat ~/.ssh/id_ed25519.pub)" --arg VERSION "$VERSION" --arg DOMAIN "$BASE_DNS_DOMAIN" --arg CLUSTERN "$CLUSTER_NAME" --arg CIDR "$MACHINE_CIDR" '{
    "name": $CLUSTERN,
    "openshift_version": $VERSION,
    "base_dns_domain": $DOMAIN,
    "hyperthreading": "all",
    "olm_operators": [
      {
        "name": "lso",
      }
    ],
    "api_vips": [
    {
      "ip": "10.17.3.2",
      "verification": "unverified"
    }
    ],
    "ingress_vips": [
    {
      "ip": "10.17.3.3",
      "verification": "unverified"
    }
    ],
    "schedulable_masters": true,
    "platform": {
      "type": "baremetal"
     },
    "user_managed_networking": false,
    "cluster_networks": [
      {
        "cidr": "172.20.0.0/16",
        "host_prefix": 23
      }
    ],
    "service_networks": [
      {
        "cidr": "172.31.0.0/16"
      }
    ],
    "machine_networks": [
      {
        "cidr": $CIDR
      }
    ],
    "network_type": "OVNKubernetes",
    "additional_ntp_source": "ntp1.hetzner.de",
    "vip_dhcp_allocation": false,
    "high_availability_mode": "Full",
    "ssh_public_key": $SSH_KEY,
    "pull_secret": $PULLSECRET
}' > deployment.json

curl -s -X POST "$AI_URL/api/assisted-install/v2/clusters" \
  -d @./deployment.json \
  --header "Content-Type: application/json" \
  | jq .

export CLUSTER_ID=$(curl -s -X GET "$AI_URL/api/assisted-install/v2/clusters?with_hosts=true" -H "accept: application/json" -H "get_unregistered_clusters: false"| jq -r '.[].id')
echo $CLUSTER_ID
rm -f deployment.json



######prepare infra####

jq -n --arg CLUSTERID "$CLUSTER_ID" --arg PULLSECRET "$(cat pull-secret.json)" \
      --arg SSH_KEY "$(cat ~/.ssh/id_ed25519.pub)" \
      --arg VERSION "$VERSION" \
      --arg NMSTATE_YAML0 "$(cat ./$NIC_CONFIG/nmstate-$NIC_CONFIG-worker0.yaml)" --arg NMSTATE_YAML1 "$(cat ./$NIC_CONFIG/nmstate-$NIC_CONFIG-worker1.yaml)" --arg NMSTATE_YAML2 "$(cat ./$NIC_CONFIG/nmstate-$NIC_CONFIG-worker2.yaml)" '{
  "name": "cluster1_infra-env",
  "openshift_version": $VERSION,
  "pull_secret": $PULLSECRET,
  "ssh_authorized_key": $SSH_KEY,
  "image_type": "full-iso",
  "cluster_id": $CLUSTERID,
  "static_network_config": [
    {
      "network_yaml": $NMSTATE_YAML0,
      "mac_interface_map": [{"mac_address": "aa:bb:cc:11:42:20", "logical_nic_name": "ens3"}, {"mac_address": "aa:bb:cc:11:42:50", "logical_nic_name": "ens4"},{"mac_address": "aa:bb:cc:11:42:60", "logical_nic_name": "ens5"},{"mac_address": "aa:bb:cc:11:42:70", "logical_nic_name": "ens6"}]
    },
    {
      "network_yaml": $NMSTATE_YAML1,
      "mac_interface_map": [{"mac_address": "aa:bb:cc:11:42:21", "logical_nic_name": "ens3"}, {"mac_address": "aa:bb:cc:11:42:51", "logical_nic_name": "ens4"},{"mac_address": "aa:bb:cc:11:42:61", "logical_nic_name": "ens5"},{"mac_address": "aa:bb:cc:11:42:71", "logical_nic_name": "ens6"}]
    },
    {
      "network_yaml": $NMSTATE_YAML2,
      "mac_interface_map": [{"mac_address": "aa:bb:cc:11:42:22", "logical_nic_name": "ens3"}, {"mac_address": "aa:bb:cc:11:42:52", "logical_nic_name": "ens4"},{"mac_address": "aa:bb:cc:11:42:62", "logical_nic_name": "ens5"},{"mac_address": "aa:bb:cc:11:42:72", "logical_nic_name": "ens6"}]
    }
  ]
}' > nmstate-$NIC_CONFIG

curl -H "Content-Type: application/json" -X POST -d @nmstate-$NIC_CONFIG ${AI_URL}/api/assisted-install/v2/infra-envs | jq .

export INFRAENV_ID=$(curl -X GET "$AI_URL/api/assisted-install/v2/infra-envs" -H "accept: application/json" | jq -r '.[].id' | awk 'NR<2')
echo $INFRAENV_ID

rm -rf nmstate-$NIC_CONFIG


ISO_URL=$(curl -X GET "$AI_URL/api/assisted-install/v2/infra-envs/$INFRAENV_ID/downloads/image-url" -H "accept: application/json"|jq -r .url)
rm -rf /var/lib/libvirt/images/discovery_image.iso
curl -X GET "$ISO_URL" -H "accept: application/octet-stream" -o /var/lib/libvirt/images/discovery_image.iso

terraform  -chdir=../terraform-cluster1 apply -auto-approve

sleep 1200



mkdir ../kube
curl -X GET $AI_URL/api/assisted-install/v2/clusters/$CLUSTER_ID/downloads/credentials?file_name=kubeconfig \
     -H 'accept: application/octet-stream' > ../kube/config-$CLUSTER_NAME
export KUBECONFIG=../kube/config-$CLUSTER_NAME
#####Get console passwords######
curl -X 'GET'   "$AI_URL/api/assisted-install/v2/clusters/$CLUSTER_ID/downloads/credentials?file_name=kubeadmin-password"   -H 'accept: application/octet-stream' > ../credentials/pwd-$CLUSTER_NAME


