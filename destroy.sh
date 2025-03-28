#!/bin/bash

BASE_DIR=$(pwd)
TF_FOLDER="$BASE_DIR/Sun/Terraform"
terraform -chdir="$TF_FOLDER" destroy -auto-approve