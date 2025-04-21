#!/usr/bin/env bash

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

# Get the directory where the script is located, resolving symlinks
SCRIPT_DIR="$( cd "$( dirname "$(readlink -f "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")" )" &> /dev/null && pwd )"

# Function to show help
show_help() {
  echo "Scaffoldix - Project Management Tool"
  echo ""
  echo "Usage:"
  echo "  scaffoldix [command] [options]"
  echo ""
  echo "Commands:"
  echo "  init <project_name>    Create a new project"
  echo "  env                   Source environment setup"
  echo "  help                  Show this help message"
}

# Function to run a use-case
run_use_case() {
  local use_case="$1"
  shift
  local script="$SCRIPT_DIR/use-cases/$use_case.sh"
  
  if [ ! -f "$script" ]; then
    echo "Error: Could not find use-case script: $use_case"
    exit 1
  fi
  
  # Make sure the script is executable
  chmod +x "$script"
  
  # Run the use-case with all remaining arguments
  "$script" "$@"
}

# Main command handling
case "$1" in
  init)
    if [ -z "$2" ]; then
      echo "Error: Project name is required"
      show_help
      exit 1
    fi
    run_use_case "create-project" "$2"
    ;;
  env)
    run_use_case "common-envrc"
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    if [ -z "$1" ]; then
      show_help
    else
      echo "Error: Unknown command: $1"
      show_help
      exit 1
    fi
    ;;
esac
