# AI³ CLI - Complete Implementation

## Overview

AI³ is a comprehensive command-line interface built in Ruby that implements advanced cognitive load management principles based on the 7±2 working memory framework. The system provides multi-LLM integration, retrieval-augmented generation (RAG), web scraping, and intelligent session management.

## Features

### 🧠 Cognitive Framework Integration
- **7±2 Working Memory Management**: Commands and interactions are designed around cognitive load principles
- **Flow State Monitoring**: Real-time tracking of user cognitive state
- **Circuit Breaker Patterns**: Automatic cognitive overload protection
- **Context-Aware Session Management**: Intelligent session handling with cognitive load awareness

### 🤖 Multi-LLM Support
- **X.AI/Grok Integration**: Primary LLM provider with advanced reasoning
- **Anthropic/Claude Support**: High-quality conversational AI
- **OpenAI Integration**: GPT models with fallback support
- **Ollama Local Models**: Privacy-focused local LLM support
- **Automatic Fallback**: Seamless switching between providers

### 📚 Knowledge Management
- **RAG (Retrieval-Augmented Generation)**: Context-aware responses using stored knowledge
- **Vector Database**: Efficient similarity search and storage
- **Web Scraping**: Automated content extraction with screenshot capture
- **Document Processing**: Intelligent chunking and indexing

### 🔧 CLI Architecture
- **Thor Framework**: Professional CLI structure with comprehensive help
- **Interactive Mode**: TTY-based interface with cognitive load indicators
- **Command Validation**: Input sanitization and security checks
- **Error Handling**: Graceful error management with detailed logging

### 🔒 Security Features
- **Zero-Trust Principles**: All inputs validated and sanitized
- **Input Validation**: Protection against injection attacks
- **Secure Credential Management**: Encrypted API key storage
- **Session Encryption**: Secure session data handling

## Installation

### Prerequisites
- Ruby 3.0+
- Bundler (installed automatically)
- Optional: API keys for LLM providers

### Quick Install
```bash
git clone <repository>
cd ai3
chmod +x install.sh
./install.sh
```

### Manual Installation
```bash
# Install dependencies
bundle install

# Setup directories
mkdir -p data logs tmp config screenshots

# Configure API keys (optional)
cp config/config.yml.example config/config.yml
# Edit config/config.yml with your settings

# Test installation
bundle exec ruby ai3_cli.rb version
```

## Usage

### Command Structure
The CLI follows 7±2 cognitive chunking principles with 8 main commands:

```bash
ai3 help                    # Show all commands
ai3 interactive             # Start interactive mode
ai3 chat "message"          # Chat with AI assistant
ai3 rag "query"             # Search knowledge base
ai3 scrape "url"            # Scrape web content
ai3 list [type]             # List resources
ai3 status                  # Show system status
ai3 switch provider         # Switch LLM provider
ai3 config                  # Configure settings
ai3 version                 # Show version info
```

### Interactive Mode
```bash
ai3 interactive
# or just
ai3
```

This starts an interactive session with:
- Real-time cognitive load monitoring
- Flow state indicators
- Context-aware prompting
- Automatic circuit breaker protection

### Examples

#### Basic Chat
```bash
ai3 chat "Explain quantum computing in simple terms"
```

#### Knowledge Search
```bash
ai3 rag "What are the latest developments in AI?"
```

#### Web Scraping
```bash
ai3 scrape "https://example.com/article"
```

#### System Status
```bash
ai3 status
```

#### List Resources
```bash
ai3 list assistants
ai3 list providers
ai3 list tools
```

### Configuration

#### Main Configuration (`config/config.yml`)
```yaml
# LLM Configuration
llm:
  primary: "xai"
  fallback_enabled: true
  temperature: 0.7
  max_tokens: 1000

# Cognitive Framework
cognitive:
  max_working_memory: 7
  circuit_breaker_threshold: 8
  flow_state_monitoring: true

# RAG Configuration
rag:
  enabled: true
  vector_db_path: "data/vector_store.db"
  max_results: 5

# Security Settings
security:
  file_access_restricted: true
  command_execution_enabled: false
```

#### API Keys (`~/.ai3_keys`)
```bash
XAI_API_KEY=your_xai_key_here
ANTHROPIC_API_KEY=your_anthropic_key_here
OPENAI_API_KEY=your_openai_key_here
REPLICATE_API_KEY=your_replicate_key_here
```

## Architecture

### Core Components

#### 1. Cognitive Orchestrator (`lib/cognitive_orchestrator.rb`)
- Implements 7±2 working memory management
- Monitors cognitive load and flow state
- Provides circuit breaker protection
- Tracks context switches and complexity

#### 2. Multi-LLM Manager (`lib/multi_llm_manager.rb`)
- Manages multiple LLM providers
- Implements fallback chains
- Handles API rate limiting
- Provides unified query interface

#### 3. Enhanced Session Manager (`lib/enhanced_session_manager.rb`)
- Cognitive load-aware session handling
- Encrypted session storage
- Automatic cleanup and eviction
- Context preservation

#### 4. RAG Engine (`lib/rag_engine.rb`)
- Vector-based similarity search
- Document chunking and indexing
- Context-aware retrieval
- Knowledge base management

#### 5. Universal Scraper (`lib/universal_scraper.rb`)
- Web content extraction
- Screenshot capture
- Link analysis
- Content preprocessing

#### 6. Assistant Registry (`lib/assistant_registry.rb`)
- Specialized AI assistants
- Role-based capabilities
- Load balancing
- Cognitive profiling

### CLI Structure

#### Thor Framework Integration
- Professional command structure
- Comprehensive help system
- Option parsing and validation
- Error handling and logging

#### Cognitive Load Management
- Real-time load monitoring
- Visual indicators in prompts
- Automatic circuit breakers
- Context switch tracking

#### Security Implementation
- Input validation and sanitization
- URL validation for scraping
- API key encryption
- Session security

## Testing

### Test Suite
```bash
# Run all tests
bundle exec ruby -Itest test/ai3_cli_test.rb

# Run specific test
bundle exec ruby -Itest -e "require 'test/ai3_cli_test.rb'; AI3CLITest.new.test_input_validation"
```

### Test Coverage
- ✅ CLI initialization and configuration
- ✅ Input validation and security
- ✅ URL validation for scraping
- ✅ Environment variable substitution
- ✅ Directory setup and structure
- ✅ Command structure validation
- ✅ Error handling and logging
- ✅ Help system accessibility

### Quality Assurance
- **Master.json Compliance**: Double-quote formatting, 2-space indentation
- **Cognitive Framework**: 7±2 command chunking, flow state preservation
- **Security**: Zero-trust principles, input sanitization
- **Accessibility**: Clear help documentation, Strunk & White style

## Development

### Project Structure
```
ai3/
├── ai3_cli.rb              # Main CLI application
├── config/
│   ├── config.yml          # Main configuration
│   └── locales/en.yml      # Localization
├── lib/
│   ├── cognitive_orchestrator.rb
│   ├── multi_llm_manager.rb
│   ├── enhanced_session_manager.rb
│   ├── rag_engine.rb
│   ├── universal_scraper.rb
│   └── assistant_registry.rb
├── test/
│   └── ai3_cli_test.rb     # Test suite
├── data/                   # Databases and cache
├── logs/                   # Application logs
├── tmp/                    # Temporary files
├── install.sh              # Installation script
├── Gemfile                 # Ruby dependencies
└── README.md               # This file
```

### Key Design Principles

#### 1. Cognitive Load Management
- Maximum 7±2 concepts in working memory
- Progressive disclosure of complexity
- Context switching minimization
- Flow state protection

#### 2. Security First
- Zero-trust architecture
- Input validation at all levels
- Secure credential management
- Session encryption

#### 3. Accessibility
- Clear, concise help documentation
- Strunk & White writing style
- Comprehensive error messages
- Visual status indicators

#### 4. Modularity
- Separation of concerns
- Pluggable components
- Extensible architecture
- Clean interfaces

## License

MIT License - see LICENSE file for details

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes following the cognitive framework principles
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## Support

For issues and questions:
- Check the logs: `logs/ai3.log`
- Run diagnostics: `ai3 status`
- Review configuration: `config/config.yml`
- Check API keys: `~/.ai3_keys`

## Version

Current version: 12.3.0

## Changelog

### v12.3.0 (Current)
- ✅ Complete Thor-based CLI implementation
- ✅ Comprehensive cognitive framework integration
- ✅ Multi-LLM support with fallback chains
- ✅ RAG engine with vector search
- ✅ Universal web scraping
- ✅ Security hardening and input validation
- ✅ Comprehensive test suite
- ✅ Professional installation script
- ✅ Master.json compliance (double quotes, 2-space indentation)
- ✅ Accessibility-focused help system