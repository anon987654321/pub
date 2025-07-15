#!/usr/bin/env bash
#
# AI³ CLI Installation Script
# Complete installation and setup for the AI³ CLI tool
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/logs/install.log"

# Ensure log directory exists
mkdir -p "${SCRIPT_DIR}/logs"

# Logging function
log() {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1" | tee -a "${LOG_FILE}"
}

# Error handling
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    log "ERROR: $1"
    exit 1
}

# Success message
success() {
    echo -e "${GREEN}✅ $1${NC}"
    log "SUCCESS: $1"
}

# Info message
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    log "INFO: $1"
}

# Warning message
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log "WARNING: $1"
}

# Banner
echo -e "${BLUE}"
cat << "EOF"
   ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄       ▄▄▄▄▄▄▄▄▄▄▄ 
  ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░░░░░░░░░░░▌
  ▐░█▀▀▀▀▀▀▀█░▌ ▀▀▀▀█░█▀▀▀▀       ▀▀▀▀▀▀▀▀▀█░▌
  ▐░▌       ▐░▌     ▐░▌                    ▐░▌
  ▐░█▄▄▄▄▄▄▄█░▌     ▐░▌           ▄▄▄▄▄▄▄▄▄█░▌
  ▐░░░░░░░░░░░▌     ▐░▌          ▐░░░░░░░░░░░▌
  ▐░█▀▀▀▀▀▀▀█░▌     ▐░▌           ▀▀▀▀▀▀▀▀▀█░▌
  ▐░▌       ▐░▌     ▐░▌                    ▐░▌
  ▐░▌       ▐░▌ ▄▄▄▄█░█▄▄▄▄       ▄▄▄▄▄▄▄▄▄█░▌
  ▐░▌       ▐░▌▐░░░░░░░░░░░▌     ▐░░░░░░░░░░░▌
   ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀▀▀▀▀▀▀▀▀▀▀ 
                                               
EOF
echo -e "${NC}"

info "AI³ CLI Installation Script v1.0"
info "Installing comprehensive command-line interface for AI³"
echo ""

# Check prerequisites
info "Checking prerequisites..."

# Check Ruby version
if ! command -v ruby &> /dev/null; then
    error_exit "Ruby is not installed. Please install Ruby 3.0+ first."
fi

RUBY_VERSION=$(ruby -e "puts RUBY_VERSION")
if ! ruby -e "exit(RUBY_VERSION >= '3.0' ? 0 : 1)" 2>/dev/null; then
    error_exit "Ruby 3.0+ is required. Current version: ${RUBY_VERSION}"
fi

success "Ruby ${RUBY_VERSION} is installed"

# Check for gem command
if ! command -v gem &> /dev/null; then
    error_exit "RubyGems is not installed"
fi

success "RubyGems is available"

# Install bundler if not present
if ! command -v bundle &> /dev/null; then
    info "Installing bundler..."
    gem install --user-install bundler || error_exit "Failed to install bundler"
    
    # Add to PATH if needed
    if ! command -v bundle &> /dev/null; then
        export PATH="$(ruby -e 'puts Gem.user_dir')/bin:$PATH"
        
        # Add to shell profile
        SHELL_PROFILE=""
        if [[ "$SHELL" == *"zsh"* ]]; then
            SHELL_PROFILE="$HOME/.zshrc"
        elif [[ "$SHELL" == *"bash"* ]]; then
            SHELL_PROFILE="$HOME/.bashrc"
        fi
        
        if [[ -n "$SHELL_PROFILE" ]]; then
            echo "export PATH=\"\$(ruby -e 'puts Gem.user_dir')/bin:\$PATH\"" >> "$SHELL_PROFILE"
            info "Added bundler to PATH in $SHELL_PROFILE"
        fi
    fi
fi

success "Bundler is available"

# Setup directories
info "Setting up directories..."

REQUIRED_DIRS=(
    "data"
    "data/screenshots"
    "data/vector_db"
    "logs"
    "tmp"
    "tmp/cache"
    "config"
    "config/locales"
    "test"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || error_exit "Failed to create directory: $dir"
        log "Created directory: $dir"
    fi
done

success "Directory structure created"

# Install Ruby dependencies
info "Installing Ruby dependencies..."
if [[ -f "Gemfile" ]]; then
    bundle install || error_exit "Failed to install Ruby dependencies"
    success "Ruby dependencies installed"
else
    error_exit "Gemfile not found. Please ensure you're in the AI³ directory"
fi

# Validate configuration
info "Validating configuration..."
if [[ -f "config/config.yml" ]]; then
    success "Configuration file found"
else
    error_exit "Configuration file not found at config/config.yml"
fi

if [[ -f "config/locales/en.yml" ]]; then
    success "Localization file found"
else
    error_exit "Localization file not found at config/locales/en.yml"
fi

# Test the installation
info "Testing installation..."
if bundle exec ruby ai3_cli.rb version &> /dev/null; then
    success "AI³ CLI is working correctly"
else
    error_exit "AI³ CLI test failed"
fi

# Run comprehensive tests
info "Running comprehensive tests..."
if bundle exec ruby -Itest test/ai3_cli_test.rb &> /dev/null; then
    success "All tests passed"
else
    warning "Some tests failed. Check logs for details."
fi

# Setup API keys (optional)
info "Setting up API keys..."
API_KEY_FILE="$HOME/.ai3_keys"

if [[ ! -f "$API_KEY_FILE" ]]; then
    cat > "$API_KEY_FILE" << 'EOF'
# AI³ API Keys Configuration
# Set your API keys here (optional)

# X.AI/Grok API Key
XAI_API_KEY=your_xai_api_key_here

# Anthropic/Claude API Key
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# OpenAI API Key
OPENAI_API_KEY=your_openai_api_key_here

# Replicate API Key (for multimedia features)
REPLICATE_API_KEY=your_replicate_api_key_here
EOF
    
    info "Created API key template at $API_KEY_FILE"
    info "Edit this file to add your API keys"
else
    info "API key file already exists at $API_KEY_FILE"
fi

# Make CLI executable
info "Making CLI executable..."
chmod +x ai3_cli.rb || error_exit "Failed to make CLI executable"
success "CLI is executable"

# Create symlink for global access (optional)
read -p "Do you want to install AI³ CLI globally? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
    
    ln -sf "$SCRIPT_DIR/ai3_cli.rb" "$BIN_DIR/ai3" || error_exit "Failed to create global symlink"
    
    # Add to PATH if needed
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        SHELL_PROFILE=""
        if [[ "$SHELL" == *"zsh"* ]]; then
            SHELL_PROFILE="$HOME/.zshrc"
        elif [[ "$SHELL" == *"bash"* ]]; then
            SHELL_PROFILE="$HOME/.bashrc"
        fi
        
        if [[ -n "$SHELL_PROFILE" ]]; then
            echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_PROFILE"
            info "Added $BIN_DIR to PATH in $SHELL_PROFILE"
        fi
    fi
    
    success "AI³ CLI installed globally as 'ai3'"
    info "You can now run 'ai3' from anywhere"
else
    info "AI³ CLI can be run locally with: bundle exec ruby ai3_cli.rb"
fi

# Print usage information
echo ""
info "Installation complete! 🎉"
echo ""
echo -e "${GREEN}Usage Examples:${NC}"
echo "  ai3 help                    # Show all commands"
echo "  ai3 interactive             # Start interactive mode"
echo "  ai3 chat 'Hello, AI!'       # Chat with AI"
echo "  ai3 rag 'search query'      # Search knowledge base"
echo "  ai3 scrape 'https://...'    # Scrape web content"
echo "  ai3 status                  # Show system status"
echo "  ai3 list assistants         # List available assistants"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Edit $API_KEY_FILE to add your API keys"
echo "2. Run 'ai3 help' to see all available commands"
echo "3. Start with 'ai3 interactive' for an interactive session"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo "- Configuration: config/config.yml"
echo "- Logs: logs/ai3.log"
echo "- Tests: test/ai3_cli_test.rb"
echo ""

success "AI³ CLI installation completed successfully!"