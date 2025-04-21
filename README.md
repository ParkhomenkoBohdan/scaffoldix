# Scaffoldix 🚀

A powerful project management tool for developers.

## Installation

### Quick Install (Recommended)

```bash
# Clone the repository
git clone https://github.com/yourusername/scaffoldix.git
cd scaffoldix

# Run the installation script
./install.sh

# If you're using zsh (default on macOS), source your config
source ~/.zshrc
```

The installation script will:
1. Install scaffoldix to `~/.local/bin`
2. Add `~/.local/bin` to your PATH if needed
3. Make PATH changes persistent across terminal sessions

### Manual Install

1. Clone the repository:
```bash
git clone https://github.com/yourusername/scaffoldix.git
```

2. Add the script to your PATH:
```bash
# For system-wide installation (requires sudo)
sudo ln -s "$(pwd)/src/index.sh" /usr/local/bin/scaffoldix

# For user-only installation
mkdir -p ~/.local/bin
ln -s "$(pwd)/src/index.sh" ~/.local/bin/scaffoldix

# Add to PATH if not already there
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Usage

```bash
# Show help
scaffoldix help

# Initialize a new project
scaffoldix init my-project

# Source environment setup
scaffoldix env
```

## Troubleshooting

If `scaffoldix` command is not found after installation:
1. Make sure `~/.local/bin` is in your PATH
2. Run `source ~/.zshrc` (or `source ~/.bashrc` if using bash)
3. Try restarting your terminal

## Features

- 🎯 Project initialization
- 🔧 Environment setup
- 🚀 Quick start templates
- 🎨 Beautiful CLI interface

## License

MIT License - see [LICENSE](LICENSE) for details 