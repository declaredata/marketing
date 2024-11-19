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
    _msg=$1
    _pid=$2
    _chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 "$_pid" 2>/dev/null; do
        _c=1
        while [ "$_c" -le 10 ]; do
            _ch=$(printf "%s" "$_chars" | cut -c "$_c")
            printf "\r${BLUE}%s${RESET} %s" "$_ch" "$_msg"
            sleep 0.1
            _c=$(( _c + 1 ))
        done
    done
    wait "$_pid"
    if [ $? -eq 0 ]; then
        printf "\r${GREEN}✓${RESET} %s\n" "$_msg"
        return 0
    else
        printf "\r${RED}✗${RESET} %s\n" "$_msg"
        return 1
    fi
}

# port selection
prompt_port() {
    _port=""
    printf "Select Fuse Server Port ${BOLD}[%s]${RESET}: " "$DEFAULT_PORT" >/dev/tty
    if read _port </dev/tty 2>/dev/null; then
        if [ -z "$_port" ]; then
            _port=$DEFAULT_PORT
        else
            case "$_port" in
                *[!0-9]*) 
                    _port=$DEFAULT_PORT
                    ;;
                *)
                    if [ "$_port" -gt 0 ] && [ "$_port" -lt 65536 ]; then
                        : # Port is valid
                    else
                        _port=$DEFAULT_PORT
                    fi
                    ;;
            esac
        fi
    else
        _port=$DEFAULT_PORT
    fi
    
    if [ "$_port" = "$DEFAULT_PORT" ]; then
        success "Using default port: $_port"
    else
        success "Using port: $_port"
    fi
    
    echo "$_port"
}

# platform detection
get_platform() {
    _os=$(uname -s | tr '[:upper:]' '[:lower:]')
    _arch=$(uname -m)
    
    case "$_arch" in
        x86_64|amd64) _arch="x86_64" ;;
        aarch64|arm64) _arch="arm64" ;;
        *) error "Unsupported architecture: $_arch" ;;
    esac
    
    case "$_os" in
        linux|darwin) ;;
        *) error "Unsupported operating system: $_os" ;;
    esac
    
    echo "${_arch}-${_os}"
}

# install
install_fuse() {
    _platform=$1
    _port=$2
    
    _tmpdir=$(mktemp -d)
    if [ ! -d "$_tmpdir" ]; then
        error "Failed to create temp directory"
    fi
    
    export FUSE_TMPDIR="$_tmpdir"
    export FUSE_PORT="$_port"
    
    trap 'rm -rf "$FUSE_TMPDIR"' EXIT
    
    # download package
    _archive="fuse-${_platform}-latest.tar.gz"
    _download_url="${DOWNLOAD_URL}/${_archive}"
    _archive_path="${FUSE_TMPDIR}/${_archive}"
    
    status "Downloading package..."
    (
        if command -v curl >/dev/null 2>&1; then
            if ! curl -fsSL "$_download_url" -o "$_archive_path"; then
                exit 1
            fi
        elif command -v wget >/dev/null 2>&1; then
            if ! wget -q "$_download_url" -O "$_archive_path"; then
                exit 1
            fi
        else
            error "Either curl or wget is required"
        fi
    ) & spin "Downloaded Fuse package!" $! || error "Download failed"
    
    status "Installing..."
    (
        cd "$FUSE_TMPDIR" && \
        if ! tar xzf "$_archive"; then
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
    ) & spin "Installed Fuse!" $! || error "Installation failed"
    
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
    ) & spin "Created config toml here: ${CONFIG_DIR}" $! || error "Configuration failed"
    
    if [ ! -x "$INSTALL_DIR/fuse" ]; then
        error "Installation verification failed"
    fi
}

main() {
    echo "${BOLD}DeclareData Fuse Installer ($APP_VERSION)${RESET}"
    echo "----------------------------------------"
    echo
    
    # Check dependencies
    for _cmd in tar gzip; do
        if ! command -v "$_cmd" >/dev/null 2>&1; then
            error "$_cmd is required but not installed"
        fi
    done
    
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        error "Either curl or wget is required"
    fi
    
    # identify platform
    status "Detecting platform..."
    _platform=$(get_platform)
    _archive_url="${DOWNLOAD_URL}/fuse-${_platform}-latest.tar.gz"
    success "Platform detected: $_platform"
    success "Package URL: $_archive_url"
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
    install_fuse "$_platform" "$PORT"
    
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
    echo "${BOLD}Start Fuse:${RESET}"
    echo "${BLUE}fuse start${RESET}"
    echo
    echo "${BOLD}Check Fuse:${RESET}"
    echo "${BLUE}fuse status${RESET}"
    echo
    echo "${BOLD}Use Fuse with your existing PySpark code:${RESET}"
    echo "${BLUE}from fuse_python.session import session${RESET}"
    echo "${BLUE}import fuse_python.functions as F${RESET}"
    echo
    echo "${BOLD}See also:${RESET} https://declaredata.com/resources/playground"
}

main "$@"
