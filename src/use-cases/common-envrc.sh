#!/usr/bin/env bash
# Example of updating local Git configuration for a project

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print section header
print_section() {
  echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Function to print status message
print_status() {
  echo -e "${GREEN}[✓]${NC} $1"
}

# Function to print warning message
print_warning() {
  echo -e "${YELLOW}[!]${NC} $1"
}

# Function to print error message
print_error() {
  echo -e "${RED}[✗]${NC} $1"
}

# Function to print info message
print_info() {
  echo -e "${CYAN}[i]${NC} $1"
}

# Function to set Git identity
set_git_identity() {
  local git_name="$1"
  local git_email="$2"

  export GIT_AUTHOR_NAME="${git_name}"
  export GIT_COMMITTER_NAME="${git_name}"
  export GIT_AUTHOR_EMAIL="${git_email}"
  export GIT_COMMITTER_EMAIL="${git_email}"
  print_status "Git identity set: ${git_name} <${git_email}>"
}

# Function to update IDE Git settings
update_ide_git_settings() {
  if [ -d "${PROJECT_DIR}/repos" ]; then
    # Find SSH key type from available key files
    local key_type
    for key_file in "${PROJECT_DIR}/.ssh/"*; do
      if [ -f "$key_file" ] && [[ ! "$key_file" =~ \.pub$ ]] && [[ ! "$key_file" =~ git_identity$ ]]; then
        key_type=$(basename "$key_file")
        break
      fi
    done

    if [ -z "$key_type" ]; then
      print_warning "No SSH key found in ${PROJECT_DIR}/.ssh/"
      return 1
    fi

    for repo in "${PROJECT_DIR}"/repos/*/; do
      if [ -d "${repo}/.git" ]; then
        (cd "${repo}" && \
        git config --local user.name "${GIT_AUTHOR_NAME}" && \
        git config --local user.email "${GIT_AUTHOR_EMAIL}" && \
        git config --local core.sshCommand "ssh -i ${PROJECT_DIR}/.ssh/${key_type} -o IdentitiesOnly=yes -o PreferredAuthentications=publickey")
      fi
    done
    print_status "Local git config updated in all repositories."
  else
    print_warning "repos folder not found."
  fi
}

# Function to read data from registry
read_registry() {
  if [ -f "$REGISTRY_FILE" ]; then
    grep "^${PROJECT_NAME}|" "$REGISTRY_FILE" | head -n 1
  fi
}

print_section "Direnv Environment Setup"
print_info "Executing common script common_envrc.sh"

# Define the current project directory (where .envrc is located, e.g., in the project root)
PROJECT_DIR="$(pwd -P)"
print_info "Current project directory: ${PROJECT_DIR}"

# Get project name from path
PROJECT_NAME=$(basename "${PROJECT_DIR}")
BASE_DIR=$(dirname "${PROJECT_DIR}")
REGISTRY_FILE="${BASE_DIR}/projects_registry.txt"

# Try to read data from registry
REGISTRY_DATA=$(read_registry)

if [ -n "$REGISTRY_DATA" ]; then
  # Use data from registry
  IFS='|' read -r _ _ SSH_KEY_TYPE GIT_NAME GIT_EMAIL _ <<< "$REGISTRY_DATA"

  set_git_identity "$GIT_NAME" "$GIT_EMAIL"
  update_ide_git_settings

  SSH_KEY_PATH="${PROJECT_DIR}/.ssh/${SSH_KEY_TYPE}"
  if [ -f "$SSH_KEY_PATH" ]; then
  if command -v ssh-add >/dev/null; then
    ssh-add -D
    ssh-add "$SSH_KEY_PATH"
    print_status "ssh-agent сброшен и загружен ключ: ${SSH_KEY_PATH}"
  fi
    export GIT_SSH_COMMAND="ssh -i ${SSH_KEY_PATH} -o IdentitiesOnly=yes -o PreferredAuthentications=publickey"
    print_status "GIT_SSH_COMMAND установлен для ключа из реестра"
  else
    unset GIT_SSH_COMMAND
    print_warning "SSH key from registry not found: ${SSH_KEY_PATH}"
  fi
else
  # --- Git identity configuration ---
  IDENTITY_FILE="${PROJECT_DIR}/.ssh/git_identity"
  if [ -f "${IDENTITY_FILE}" ]; then
    GIT_NAME=$(head -n 1 "${IDENTITY_FILE}")
    GIT_EMAIL=$(head -n 2 "${IDENTITY_FILE}" | tail -n 1)
    set_git_identity "$GIT_NAME" "$GIT_EMAIL"
    update_ide_git_settings
  else
    print_warning "git_identity file not found. Using global Git configuration."
  fi

  # --- SSH key configuration ---
  if [ -d "${PROJECT_DIR}/.ssh" ]; then
    # Look for keys with and without 'id_' prefix
    POSSIBLE_KEYS=("ed25519" "rsa" "ecdsa" "id_ed25519" "id_rsa" "id_ecdsa")
    KEY_FOUND=""
    for key in "${POSSIBLE_KEYS[@]}"; do
      if [ -f "${PROJECT_DIR}/.ssh/${key}" ]; then
        KEY_FOUND="${PROJECT_DIR}/.ssh/${key}"
        break
      fi
    done
    if [ -n "$KEY_FOUND" ]; then
      if command -v ssh-add >/dev/null; then
        ssh-add -D
        ssh-add "$KEY_FOUND"
        print_status "ssh-agent сброшен и загружен локальный ключ: ${KEY_FOUND}"
      fi
      export GIT_SSH_COMMAND="ssh -i ${KEY_FOUND} -o IdentitiesOnly=yes -o PreferredAuthentications=publickey"
      print_status "GIT_SSH_COMMAND установлен для локального ключа"
    else
      unset GIT_SSH_COMMAND
      print_warning "ssh folder exists but key not found. Using global SSH."
    fi
  else
    unset GIT_SSH_COMMAND
    print_warning "ssh folder not found. Using global SSH."
  fi
fi
