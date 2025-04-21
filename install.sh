#!/usr/bin/env bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status message
print_status() {
  echo -e "${GREEN}[✓]${NC} $1"
}

# Function to print error message
print_error() {
  echo -e "${RED}[✗]${NC} $1"
}

# Function to print info message
print_info() {
  echo -e "${BLUE}[i]${NC} $1"
}

# Function to print warning message
print_warning() {
  echo -e "${YELLOW}[!]${NC} $1"
}

# Default installation directory
INSTALL_DIR="/usr/local/bin"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  print_info "Running as non-root user. Will install to ~/.local/bin instead."
  INSTALL_DIR="$HOME/.local/bin"
  mkdir -p "$INSTALL_DIR"
  
  # Check if ~/.local/bin is in PATH
  if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    print_info "Adding $INSTALL_DIR to PATH..."
    
    # Add to PATH for current session
    export PATH="$INSTALL_DIR:$PATH"
    
    # Add to shell config files
    for shell_config in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
      if [ -f "$shell_config" ]; then
        if ! grep -q "export PATH=\"$INSTALL_DIR:\$PATH\"" "$shell_config"; then
          echo "# Added by scaffoldix installer" >> "$shell_config"
          echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$shell_config"
          print_status "Added $INSTALL_DIR to $shell_config"
        fi
      fi
    done
    
    print_warning "Please restart your terminal or run 'export PATH=\"$INSTALL_DIR:\$PATH\"' to use scaffoldix immediately"
  fi
fi

# Make source file executable
print_info "Making source file executable..."
chmod +x "$(pwd)/src/index.sh"

# Create symbolic link
print_info "Installing scaffoldix to $INSTALL_DIR..."
if ln -sf "$(pwd)/src/index.sh" "$INSTALL_DIR/scaffoldix"; then
  print_status "Successfully installed scaffoldix!"
  print_info "You can now use 'scaffoldix' command from anywhere."
  print_info "Try running 'scaffoldix help' to see available commands."
else
  print_error "Failed to install scaffoldix. Please check permissions."
  exit 1
fi 