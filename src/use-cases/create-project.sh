#!/usr/bin/env bash
#
# Script for automatic project creation in ~/my-projects.
#
# This script creates a new project with a predefined directory structure,
# a minimal .envrc file (linking to the common environment script),
# generates an SSH key (with an option for password protection),
# and saves the Git identity (user name and email) for the project.
#
# Dependencies: ssh-keygen, direnv, git
#
# Usage:
#   ./create_project.sh project_name
#

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

# Function to print user prompt
print_prompt() {
  echo -e "${CYAN}[?]${NC} $1"
}

# Function to check dependencies
check_dependencies() {
  print_section "Checking Dependencies"
  local missing_deps=()
  local deps=("ssh-keygen" "direnv" "git")
  
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      missing_deps+=("$dep")
    fi
  done
  
  if [ ${#missing_deps[@]} -ne 0 ]; then
    print_error "The following dependencies are missing:"
    for dep in "${missing_deps[@]}"; do
      case "$dep" in
        "ssh-keygen")
          echo "  - ssh-keygen (part of openssh-client package)"
          echo "    Installation:"
          echo "      macOS: brew install openssh"
          ;;
        "direnv")
          echo "  - direnv"
          echo "    Installation:"
          echo "      macOS: brew install direnv"
          ;;
        "git")
          echo "  - git"
          echo "    Installation:"
          echo "      macOS: brew install git"
          ;;
      esac
    done
    exit 1
  else
    print_status "All required dependencies are installed"
  fi
}

# Function to display SSH key type menu
display_key_menu() {
  echo "Available key types:"
  echo "1) Ed25519 (recommended) - Fast and secure"
  echo "2) RSA (2048 bit) - Widely compatible"
  echo "3) ECDSA (nistp256) - Good balance of security and performance"
}

# Function to get SSH key type
get_key_type() {
  local temp_file
  temp_file=$(mktemp)
  
  # Display menu
  display_key_menu >&2
  
  # Get user input
  while true; do
    read -r -p "Enter your choice [1-3]: " key_type >&2
    
    case $key_type in
      1) echo "ed25519" > "$temp_file"; break ;;
      2) echo "rsa" > "$temp_file"; break ;;
      3) echo "ecdsa" > "$temp_file"; break ;;
      *) echo "Invalid choice. Please enter 1, 2, or 3." >&2 ;;
    esac
  done
  
  # Read and return the selected type
  cat "$temp_file"
  rm "$temp_file"
}

# Function to get password
get_password() {
  local password1 password2
  while true; do
    print_prompt "Enter password for SSH key: "
    read -r -s password1
    echo
    if [ -z "$password1" ]; then
      print_warning "Password cannot be empty. Please try again."
      continue
    fi
    
    print_prompt "Repeat password: "
    read -r -s password2
    echo
    
    if [ "$password1" = "$password2" ]; then
      echo "$password1"
      return 0
    else
      print_warning "Passwords do not match. Please try again."
    fi
  done
}

# Function to update project registry
update_registry() {
  local project_name="$1"
  local project_dir="$2"
  local key_type="$3"
  local git_name="$4"
  local git_email="$5"
  
  # Get the scaffoldix project directory
  local scaffoldix_dir
  scaffoldix_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  
  local registry_file="${scaffoldix_dir}/projects_registry.txt"
  local temp_file="${registry_file}.tmp"
  
  # Create registry if it doesn't exist
  if [ ! -f "$registry_file" ]; then
    touch "$registry_file"
  fi
  
  # Remove existing entry if it exists
  if grep -q "^${project_name}|" "$registry_file"; then
    grep -v "^${project_name}|" "$registry_file" > "$temp_file"
    mv "$temp_file" "$registry_file"
  fi
  
  # Add new entry with proper formatting
  printf "%s|%s|%s|%s|%s|%s\n" \
    "$project_name" \
    "$project_dir" \
    "$key_type" \
    "$git_name" \
    "$git_email" \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$registry_file"
}

# Check dependencies
check_dependencies

# Get project name from arguments
PROJECT_NAME="$1"

# Validate project name
if [ -z "$PROJECT_NAME" ]; then
  print_error "Project name is required"
  exit 1
fi

# Create project directory
print_section "Creating project directory"
if [ -d "$PROJECT_NAME" ]; then
  print_error "Directory $PROJECT_NAME already exists"
  exit 1
fi

mkdir -p "$PROJECT_NAME"
print_status "Created directory $PROJECT_NAME"

# Initialize git repository
print_section "Initializing git repository"
cd "$PROJECT_NAME" || exit 1
git init
print_status "Initialized git repository"

# Create basic directory structure
print_section "Creating project directory structure..."
mkdir -p "repos"
mkdir -p ".ssh"
mkdir -p "docs"
print_status "Directory structure created"

# Create README files
print_section "Creating documentation files..."

# Create project README
cat > "docs/README.md" << EOF
# ${PROJECT_NAME}

## Project Overview
This directory contains project documentation and resources.

## Directory Structure
- \`repos/\` - Contains all project repositories
- \`docs/\` - Project documentation and resources
- \`.ssh/\` - SSH keys and Git identity configuration

## Setup Instructions
1. Navigate to the project directory
2. Run \`direnv allow\` to load the environment
3. Follow the documentation in each subdirectory

## Usage Guidelines
- Keep documentation up to date
- Store all project-related repositories in \`repos/\`
- Maintain SSH keys and Git identity in \`.ssh/\`
EOF
print_status "Created project documentation"

# Create repos README
cat > "repos/README.md" << EOF
# Repositories

This directory contains all project-related repositories.

## Adding a New Repository
1. Clone the repository into this directory
2. The repository will automatically use project-specific:
   - SSH keys
   - Git identity
   - Environment settings

## Repository Management
- Each repository should be a subdirectory
- Use meaningful names for repositories
- Keep repository documentation up to date
- Follow project-specific Git workflows

## Current Repositories
- (Add repository names and descriptions here)
EOF
print_status "Created repository documentation"

# Create minimal .envrc
print_section "Creating .envrc"
ENVRC_FILE=".envrc"
# Get the scaffoldix project directory
SCAFFOLDIX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cat > "$ENVRC_FILE" << EOF
# Load common environment
source "${SCAFFOLDIX_DIR}/src/use-cases/common-envrc.sh"
EOF
print_status "Created .envrc file"

# Generate SSH key
print_section "SSH Key Configuration"
print_info "Please select the type of SSH key to generate"
print_info "Ed25519 is recommended for most users"

# Get key type using the new function
KEY_TYPE=$(get_key_type)
KEY_FILE=".ssh/${KEY_TYPE}"

if [ ! -f "${KEY_FILE}" ]; then
  print_info "Generating new SSH key..."
  
  # Ask if password protection is needed
  print_prompt "Do you want to protect the key with a password? (y/n): "
  read -r use_password
  if [[ $use_password =~ ^[Yy]$ ]]; then
    print_info "You will be prompted to enter a password for the SSH key"
    PASSWORD=$(get_password)
  else
    PASSWORD=""
    print_warning "SSH key will be created without password protection"
  fi
  
  case $KEY_TYPE in
    "ed25519")
      ssh-keygen -t ed25519 -f "${KEY_FILE}" -q -N "$PASSWORD"
      ;;
    "rsa")
      ssh-keygen -t rsa -b 2048 -f "${KEY_FILE}" -q -N "$PASSWORD"
      ;;
    "ecdsa")
      ssh-keygen -t ecdsa -b 256 -f "${KEY_FILE}" -q -N "$PASSWORD"
      ;;
  esac
  
  # Clear password variable
  unset PASSWORD
  
  if [ $? -eq 0 ]; then
    print_status "SSH key successfully created: ${KEY_FILE}"
    chmod 600 "${KEY_FILE}"
  else
    print_error "Failed to generate SSH key"
  fi
else
  print_warning "SSH key already exists: ${KEY_FILE}"
fi

# Save Git identity
print_section "Git Configuration"
IDENTITY_FILE=".ssh/git_identity"
if [ ! -f "${IDENTITY_FILE}" ]; then
  print_info "Please enter your Git identity for this project"
  print_prompt "Enter Git username: "
  read -r GIT_NAME
  print_prompt "Enter Git email: "
  read -r GIT_EMAIL
  echo "${GIT_NAME}" > "${IDENTITY_FILE}"
  echo "${GIT_EMAIL}" >> "${IDENTITY_FILE}"
  print_status "Git identity saved"
  
  # Update registry with project information
  update_registry "$PROJECT_NAME" "$(pwd)" "$KEY_TYPE" "$GIT_NAME" "$GIT_EMAIL"
else
  print_warning "Git identity already exists"
  # Read existing Git identity for registry update
  GIT_NAME=$(head -n 1 "${IDENTITY_FILE}")
  GIT_EMAIL=$(head -n 2 "${IDENTITY_FILE}" | tail -n 1)
  update_registry "$PROJECT_NAME" "$(pwd)" "$KEY_TYPE" "$GIT_NAME" "$GIT_EMAIL"
fi

# Automatically allow .envrc
print_info "Allowing .envrc for the project..."
if [ -f ".envrc" ]; then
  direnv allow
  print_status ".envrc allowed"
else
  print_error "Could not allow .envrc - file not found"
fi

print_section "Project Setup Complete"
print_status "Your new project '$PROJECT_NAME' is ready!"
print_info "Next steps:"
print_info "1. cd $PROJECT_NAME"
print_info "2. Start coding!"
