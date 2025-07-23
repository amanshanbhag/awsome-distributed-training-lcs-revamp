#!/bin/bash

set -ex

LOG_FILE="/var/log/provision/provisioning.log"
mkdir -p "/var/log/provision"
touch $LOG_FILE

# Function to log messages
logger() {
  echo "$@" | tee -a $LOG_FILE
}

PROVISIONING_PARAMETERS_PATH="provisioning_parameters.json"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ANSIBLE_DIR="${SCRIPT_DIR}/ansible"

# Adding to give systemd-resolved (DNS service) enough time to get rebooted (by HostAgent) so that network is available during LCS execution
sleep 30

if [[ -z "$SAGEMAKER_RESOURCE_CONFIG_PATH" ]]; then
  logger "Env var SAGEMAKER_RESOURCE_CONFIG_PATH is unset, trying to read from default location path"
  SAGEMAKER_RESOURCE_CONFIG_PATH="/opt/ml/config/resource_config.json"

  if [[ ! -f $SAGEMAKER_RESOURCE_CONFIG_PATH ]]; then
    logger "Env var SAGEMAKER_RESOURCE_CONFIG_PATH is unset and file does not exist: $SAGEMAKER_RESOURCE_CONFIG_PATH"
    logger "Assume vanilla cluster setup, no scripts to run. Exiting."
    exit 0
  fi
else
  logger "env var SAGEMAKER_RESOURCE_CONFIG_PATH is set to: $SAGEMAKER_RESOURCE_CONFIG_PATH"
  if [[ ! -f $SAGEMAKER_RESOURCE_CONFIG_PATH ]]; then
    logger "Env var SAGEMAKER_RESOURCE_CONFIG_PATH is set and file does not exist: $SAGEMAKER_RESOURCE_CONFIG_PATH"
    exit 1
  fi
fi

# Step 1: Install Ansible using the original script
logger "Installing Ansible..."
sudo bash "${SCRIPT_DIR}/utils/install_ansible.sh" >  >(tee -a $LOG_FILE) 2>&1

# Step 2: Copy provisioning parameters to the Ansible directory
logger "Copying provisioning parameters to Ansible directory..."
mkdir -p "${ANSIBLE_DIR}/vars"
cp "$PROVISIONING_PARAMETERS_PATH" "${ANSIBLE_DIR}/vars/provisioning_parameters.json"

# Step 3: Run the Ansible playbook
logger "Running Ansible playbook..."
cd "${ANSIBLE_DIR}"
ansible-playbook playbooks/playbook.yml -v >  >(tee -a $LOG_FILE) 2>&1
ansible_exit_code=$?

if [ $ansible_exit_code -ne 0 ]; then
  logger "Ansible playbook execution failed with exit code $ansible_exit_code"
  exit $ansible_exit_code
fi

# After running the Ansible playbook, extract facts from Ansible
logger "Extracting Ansible facts..."
cd "${ANSIBLE_DIR}"
ansible localhost -m setup > /tmp/ansible_facts.json 2>/dev/null || true

# Extract node IP and role from Ansible facts if available
if [ -f /tmp/ansible_facts.json ]; then
  export ANSIBLE_NODE_IP=$(grep -o '"self_ip": "[^"]*' /tmp/ansible_facts.json | cut -d'"' -f4)
  export ANSIBLE_NODE_ROLE=$(grep -o '"node_role": "[^"]*' /tmp/ansible_facts.json | cut -d'"' -f4)
  logger "Ansible facts: Node IP=${ANSIBLE_NODE_IP}, Node Role=${ANSIBLE_NODE_ROLE}"
fi

# Step 4: Continue with original script for parts not yet converted
logger "Running remaining original scripts..."
cd "${SCRIPT_DIR}"
logger "Running lifecycle_script.py with resourceConfig: $SAGEMAKER_RESOURCE_CONFIG_PATH, provisioning_parameters: $PROVISIONING_PARAMETERS_PATH"

python3 -u lifecycle_script.py \
  -rc $SAGEMAKER_RESOURCE_CONFIG_PATH \
  -pp $PROVISIONING_PARAMETERS_PATH >  >(tee -a $LOG_FILE) 2>&1

exit_code=$?

exit $exit_code
