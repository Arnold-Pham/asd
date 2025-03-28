#!/bin/bash

BASE_DIR=$(pwd)
TF_FOLDER="$BASE_DIR/Sun/Terra"
terraform -chdir="$TF_FOLDER" destroy