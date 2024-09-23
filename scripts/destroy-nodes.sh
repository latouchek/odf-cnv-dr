#!/bin/bash

# List of Terraform directories
directories=("terraform-cluster1" "terraform-cluster2" "terraform-sno-hub")

# Loop through each directory and destroy Terraform resources
for dir in "${directories[@]}"; do
  if [ -d "$dir" ]; then
    echo "Destroying Terraform resources in directory: $dir"
    terraform -chdir="$dir" destroy -auto-approve
    if [ $? -eq 0 ]; then
      echo "Successfully destroyed resources in $dir."
    else
      echo "Failed to destroy resources in $dir." >&2
    fi
  else
    echo "Directory $dir does not exist. Skipping."
  fi
done

echo "Terraform destruction process completed."
