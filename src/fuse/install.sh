#!/bin/sh
# DeclareData Fuse Installer
# https://declaredata.com
# Version: 0.0.1

set -eu

APP_VERSION="1.0.0"
APP_NAME="fuse"
INSTALL_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config/${APP_NAME}"
DEFAULT_PORT=8080
DOWNLOAD_URL="${INSTALLER_DOWNLOAD_URL:-https://releases.declaredata.com/fuse/1.0.0}"

#  colors
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[0;33m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED='' GREEN='' BLUE='' YELLOW='' BOLD='' RESET=''
fi

error()   { echo "${RED}Error: $1${RESET}" >&2; exit 1; }
status()  { echo "${BLUE}=>${RESET} $1"; }
success() { echo "${GREEN}✓${RESET} $1"; }
debug()   { [ "${DEBUG:-0}" = "1" ] && echo "${YELLOW}DEBUG:${RESET} $1" >&2; }

# spinner
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
        return 0
    else
        printf "\r${RED}✗${RESET} %s\n" "$msg"
        return 1
    fi
}

# port selection
prompt_port() {
    printf "Select Fuse Server Port ${BOLD}[%s]${RESET}: " "$DEFAULT_PORT" >/dev/tty
    if port=$(head -n1 </dev/tty 2>/dev/null); then
        if [ -z "$port" ]; then
            port=$DEFAULT_PORT
        else
            case "$port" in
                *[!0-9]*) 
                    port=$DEFAULT_PORT
                    ;;
                *)
                    if [ "$port" -gt 0 ] && [ "$port" -lt 65536 ]; then
                        : # Port is valid
                    else
                        port=$DEFAULT_PORT
                    fi
                    ;;
            esac
        fi
    else
        port=$DEFAULT_PORT
    fi
    
    if [ "$port" = "$DEFAULT_PORT" ]; then
        success "Using default port: $port"
    else
        success "Using port: $port"
    fi
    
    echo "$port"
}

# platform detection
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

# install
install_fuse() {
    local platform=$1
    local port=$2
    local tmpdir
    
    tmpdir=$(mktemp -d)
    if [ ! -d "$tmpdir" ]; then
        error "Failed to create temp directory"
    fi
    
    export FUSE_TMPDIR="$tmpdir"
    export FUSE_PORT="$port"
    
    trap 'rm -rf "$FUSE_TMPDIR"' EXIT
    
    # download package
    local archive="fuse-${platform}-latest.tar.gz"
    local download_url="${DOWNLOAD_URL}/${archive}"
    local archive_path="${FUSE_TMPDIR}/${archive}"
    
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
        cd "$FUSE_TMPDIR" && \
        if ! tar xzf "$archive"; then
            exit 1
        fi && \
        
        mkdir -p "$INSTALL_DIR" && \
        
        if [ -d "fuse-dist/bin" ]; then
            cp -f fuse-dist/bin/* "$INSTALL_DIR/" || exit 1
            chmod +x "$INSTALL_DIR/fuse" || exit 1
        else
            exit 1
        fi && \
        
        if [ -d "fuse-dist/lib" ]; then
            mkdir -p "$INSTALL_DIR/../lib" && \
            cp -rf fuse-dist/lib/* "$INSTALL_DIR/../lib/" || exit 1
        fi
    ) & spin "Installing Fuse" $! || error "Installation failed"
    
    status "Creating configuration..."
    (
        mkdir -p "$CONFIG_DIR" && \
        
        cat > "$CONFIG_DIR/fuse.toml" << EOF || exit 1
[server]
port = $FUSE_PORT
host = "0.0.0.0"

[logging]
level = "info"
file = "fuse.log"
EOF
        
        mkdir -p "${HOME}/.local/share/fuse/data"
    ) & spin "Creating configuration" $! || error "Configuration failed"
    
    if [ ! -x "$INSTALL_DIR/fuse" ]; then
        error "Installation verification failed"
    fi
}

main() {
    echo "${BOLD}DeclareData Fuse Installer ($APP_VERSION)${RESET}"
    echo "----------------------------------------"
    echo
    
    # Check dependencies
    for cmd in tar gzip; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "$cmd is required but not installed"
        fi
    done
    
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        error "Either curl or wget is required"
    fi
    
    # identify platform
    status "Detecting platform..."
    PLATFORM=$(get_platform)
    ARCHIVE_URL="${DOWNLOAD_URL}/fuse-${PLATFORM}-latest.tar.gz"
    success "Platform detected: $PLATFORM"
    success "Package URL: $ARCHIVE_URL"
    success "Install directory: $INSTALL_DIR"
    success "Config directory: $CONFIG_DIR"
    echo
    
    # port
    status "Configuring Fuse server..."
    if [ -t 0 ] && [ -t 1 ]; then
        PORT=$(prompt_port)
    else
        success "Using default port in non-interactive mode: $DEFAULT_PORT"
        PORT=$DEFAULT_PORT
    fi
    echo
    
    # install
    install_fuse "$PLATFORM" "$PORT"
    
    # check PATH
    if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
        echo
        status "PATH Configuration Required"
        echo "Add Fuse to your PATH by running:"
        echo "    export PATH=\"\$PATH:$INSTALL_DIR\""
        echo
        echo "To make this permanent, add this line to your shell's config file"
        echo "(~/.bashrc, ~/.zshrc, or similar)"
    fi
    
    # done
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
