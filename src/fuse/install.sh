#!/bin/sh
# DeclareData Fuse Installer
# https://declaredata.com
# Version: 0.0.1 WIP

set -eu

APP_VERSION="1.0.0"
APP_NAME="fuse"
INSTALL_DIR="${HOME}/.local/${APP_NAME}"
CONFIG_DIR="${HOME}/.config/fuse"
DEFAULT_PORT=8080
DOWNLOAD_URL="${INSTALLER_DOWNLOAD_URL:-https://releases.declaredata.com/fuse/1.0.0}"

# some helpers
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    RESET='\033[0m'
    BOLD='\033[1m'
else
    RED=''
    GREEN=''
    BLUE=''
    RESET=''
    BOLD=''
fi

error() {
    echo "${RED}Error: $1${RESET}" >&2
    exit 1
}

status() {
    echo "${BLUE}=>${RESET} $1"
}

success() {
    echo "${GREEN}✓${RESET} $1"
}

# simple spinner
spin() {
    msg=$1
    pid=$2
    spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r${BLUE}%s${RESET} %s" "${spin:$i:1}" "$msg"
        sleep 0.1
    done
    wait $pid
    if [ $? -eq 0 ]; then
        printf "\r${GREEN}✓${RESET} %s\n" "$msg"
    else
        printf "\r${RED}✗${RESET} %s\n" "$msg"
        return 1
    fi
}

prompt_port() {
    printf "Select Fuse Server Port [%s]: " "$DEFAULT_PORT" >/dev/tty
    if port=$(head -n1 </dev/tty 2>/dev/null); then
        if [ -z "$port" ]; then
            success "Using default: $DEFAULT_PORT"
            echo "$DEFAULT_PORT"
            return
        fi
        case "$port" in
            *[!0-9]*)
                echo "Invalid port, using default: $DEFAULT_PORT"
                echo "$DEFAULT_PORT"
                ;;
            *)
                if [ "$port" -gt 0 ] && [ "$port" -lt 65536 ]; then
                    success "Using port: $port"
                    echo "$port"
                else
                    echo "Port out of range, using default: $DEFAULT_PORT"
                    echo "$DEFAULT_PORT"
                fi
                ;;
        esac
    else
        success "Using default: $DEFAULT_PORT"
        echo "$DEFAULT_PORT"
    fi
}

get_platform() {
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)
    
    case "$arch" in
        x86_64|amd64) arch="x86_64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) error "Unsupported architecture: $arch" ;;
    esac
    
    case "$os" in
        linux|darwin) ;;
        *) error "Unsupported operating system: $os" ;;
    esac
    
    echo "${arch}-${os}"
}

install_fuse() {
    local platform=$1
    local port=$2
    local tmpdir
    
    # create temp directory
    tmpdir=$(mktemp -d) || error "Failed to create temp directory"
    trap 'rm -rf "$tmpdir"' EXIT
    
    # download and install
    local archive="fuse-${platform}-latest.tar.gz"
    local download_url="${DOWNLOAD_URL}/${archive}"
    local archive_path="${tmpdir}/${archive}"
    
    status "Downloading package..."
    (
        if command -v curl >/dev/null 2>&1; then
            if ! curl -fsSL "$download_url" -o "$archive_path"; then
                exit 1
            fi
        elif command -v wget >/dev/null 2>&1; then
            if ! wget -q "$download_url" -O "$archive_path"; then
                exit 1
            fi
        else
            error "Either curl or wget is required"
        fi
    ) & spin "Downloading Fuse package" $! || error "Download failed"
    
    status "Installing..."
    (
        # extract archive
        cd "$tmpdir" && \
        if ! tar xzf "$archive"; then
            exit 1
        fi && \
        
        # create install directory
        mkdir -p "$INSTALL_DIR" && \
        
        # install binary
        if [ -d "fuse-dist/bin" ]; then
            cp -f fuse-dist/bin/* "$INSTALL_DIR/" || exit 1
            chmod +x "$INSTALL_DIR/fuse" || exit 1
        else
            exit 1
        fi && \
        
        # install client libraries
        if [ -d "fuse-dist/lib" ]; then
            mkdir -p "$INSTALL_DIR/../lib" && \
            cp -rf fuse-dist/lib/* "$INSTALL_DIR/../lib/" || exit 1
        fi
    ) & spin "Installing Fuse" $! || error "Installation failed"
    
    status "Creating configuration..."
    (
        # create config directory
        mkdir -p "$CONFIG_DIR" && \
        
        # config
        cat > "$CONFIG_DIR/fuse.toml" << EOF || exit 1
[server]
port = $port
host = "0.0.0.0"

[logging]
level = "info"
file = "fuse.log"
EOF
        
        # create data directory
        mkdir -p "${HOME}/.local/share/fuse/data"
    ) & spin "Creating configuration" $! || error "Configuration failed"
    
    # verify installation
    if [ ! -x "$INSTALL_DIR/fuse" ]; then
        error "Installation verification failed"
    fi
}

main() {
    echo "${BOLD}DeclareData Fuse Installer ($APP_VERSION)${RESET}"
    echo "----------------------------------------"
    echo
    
    # check dependencies
    for cmd in tar gzip; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "$cmd is required but not installed"
        fi
    done
    
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        error "Either curl or wget is required"
    fi
    
    # get platform
    status "Detecting platform..."
    PLATFORM=$(get_platform)
    ARCHIVE_URL="${DOWNLOAD_URL}/fuse-${PLATFORM}-latest.tar.gz"
    INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
    success "Platform detected: $PLATFORM"
    success "Package URL: $ARCHIVE_URL"
    success "Install directory: $INSTALL_DIR"
    echo
    
    # prompt for port
    status "Configuring Fuse server..."
    if [ -t 0 ] && [ -t 1 ]; then
        # Interactive mode
        PORT=$(prompt_port)
    else
        # Non-interactive mode
        success "Using default port in non-interactive mode: $DEFAULT_PORT"
        PORT=$DEFAULT_PORT
    fi
    echo
    
    # install fuse
    install_fuse "$PLATFORM" "$PORT"
    
    # check if path needs to be updated
    if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
        echo
        status "PATH Configuration Required"
        echo "Add Fuse to your PATH by running:"
        echo "    export PATH=\"\$PATH:$INSTALL_DIR\""
        echo
        echo "To make this permanent, add this line to your shell's config file"
        echo "(~/.bashrc, ~/.zshrc, or similar)"
    fi
    
    # completion message
    echo
    success "Installation Complete!"
    echo
    echo "${BOLD}To start using Fuse:${RESET}"
    echo "Start the server:"
    echo "   ${BLUE}fuse start${RESET}"
    echo
    echo "View status:"
    echo "   ${BLUE}fuse status${RESET}"
    echo
    echo "${BOLD}Getting started:${RESET} https://declaredata.com/resources/playground"
}

main "$@"
