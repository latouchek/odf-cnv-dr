#!/bin/sh

# Define file paths
primary_crt="./primary.crt"
secondary_crt="./secondary.crt"
output_file="../manifests/cm-clusters-crt.yaml"

# Check if the files exist
if [ ! -f "$primary_crt" ]; then
    echo "Error: $primary_crt does not exist."
    exit 1
fi

if [ ! -f "$secondary_crt" ]; then
    echo "Error: $secondary_crt does not exist."
    exit 1
fi

# Start creating the YAML file with the appropriate headers
cat << EOF > $output_file
apiVersion: v1
data:
  ca-bundle.crt: |
EOF

# Function to append certificates ensuring proper spacing
append_certificates() {
    crt_file=$1
    in_certificate_block=false
    while IFS= read -r line; do
        if echo "$line" | grep -q "BEGIN CERTIFICATE"; then
            in_certificate_block=true
            echo "    $line" >> $output_file
        elif echo "$line" | grep -q "END CERTIFICATE"; then
            echo "    $line" >> $output_file
            echo "" >> $output_file  # Add a blank line after each certificate block
            in_certificate_block=false
        elif [ "$in_certificate_block" = true ]; then
            echo "    $line" >> $output_file
        fi
    done < "$crt_file"
}

# Append certificates from primary.crt
append_certificates "$primary_crt"

# Append certificates from secondary.crt
append_certificates "$secondary_crt"

# Ensure no extra blank line before metadata
sed -i '$ d' "$output_file"

# Add the metadata for the ConfigMap without an extra blank line before it
cat << EOF >> $output_file
kind: ConfigMap
metadata:
  name: user-ca-bundle
  namespace: openshift-config
EOF

echo "Certificates appended successfully to $output_file."
