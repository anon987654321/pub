# AI³ (AI Cubed) - Advanced Intelligent Integration Interface

AI³ is a sophisticated multi-agent AI assistant platform built in Ruby, featuring swarm intelligence, multi-LLM integration, vector-powered memory, and specialized assistants for complex problem-solving across multiple domains.

## 🚀 Core Features

### **Multi-Agent Swarm Architecture**
- **10+ Autonomous Agents**: Each assistant can deploy specialized autonomous agents
- **Task Distribution**: Intelligent task allocation across agent capabilities  
- **Report Consolidation**: Unified results from multiple agent perspectives
- **Cross-Domain Collaboration**: Agents can collaborate across specializations

### **Advanced Assistant Ecosystem**
- **Multi-Assistant Chat**: Legal, Architect, Music, Manufacturing specialists
- **Social Media Bots**: Discord, SnapChat, Tinder integration with AI-powered automation
- **Security Analysis**: Ethical hacking with swarm-based penetration testing
- **Specialized Domains**: Healthcare, urban planning, scientific research applications

### **Intelligent Memory & Context**
- **Weaviate Vector Database**: Advanced vector search and similarity matching
- **LRU Session Management**: Efficient context persistence with eviction strategies
- **Long-term Memory**: Automatic context cleanup and recall capabilities
- **URL-based Data Sources**: Intelligent scraping and indexing patterns

### **Multi-LLM Integration**
- **Provider Support**: OpenAI, Anthropic, Ollama with intelligent routing
- **Cognitive Orchestration**: Load-aware processing and model selection
- **Rate Limiting**: Smart quota management across providers
- **Fallback Strategies**: Automatic failover between LLM providers

### **Security & Execution**
- **OpenBSD Integration**: Secure execution with pledge/unveil support
- **Safe Ruby Execution**: Sandboxed code execution for file operations
- **Encrypted Sessions**: Secure session management and storage
- **Access Control**: Granular permissions for system operations

### **Data Processing & Scraping**
- **Universal Scraper**: Ferrum-based web scraping with cognitive load awareness
- **Dynamic CSS Detection**: AI-powered element detection for social media automation
- **Screenshot Capabilities**: Visual analysis and automated interaction
- **Batch Processing**: Efficient data ingestion and indexing

### **Interactive Interface**
- **TTY-Based CLI**: Rich terminal interface with AI³> prompt
- **Session Persistence**: Context-aware conversations across sessions
- **Dynamic Suggestions**: AI-powered next-step recommendations
- **Multi-Language Support**: I18n localization framework

## 🤖 Specialized Assistants

### **Core Assistants**
- **CasualAssistant**: General-purpose conversational AI
- **MultiAssistantChat**: Session management across specialized roles
- **SwarmOrchestrator**: Coordinates multiple autonomous agents

### **Professional Specialists**
- **LawyerAssistant**: Legal research and document analysis
- **ArchitectAssistant**: Building design and urban planning
- **MedicalAssistant**: Healthcare analysis and research
- **InvestmentBanker**: Financial analysis and market research

### **Technical Specialists**  
- **HackerPenTester**: Ethical hacking with 10-agent security swarm
- **WebDeveloper**: Full-stack development assistance
- **SysAdmin**: System administration and infrastructure
- **SecuritySpecialist**: Advanced cybersecurity analysis

### **Creative & Specialized**
- **Musician**: Music creation with genre-specialized agent swarm
- **MaterialRepurposing**: Sustainability and circular economy analysis  
- **RocketScientist**: Aerospace engineering and propulsion systems
- **NeuroScientist**: Neuroscience research and analysis

### **Social Media Automation**
- **ChatbotDiscord**: Discord integration with dynamic CSS detection
- **ChatbotSnapchat**: SnapChat automation and engagement
- **TinderAssistant**: AI-powered matching and conversation starters

## 📁 Architecture Overview

```
ai3/
├── ai3.rb                    # Main CLI executable with TTY interface
├── config.yml               # Consolidated configuration
├── Gemfile                   # Dependencies
├── lib/                      # Core library components
│   ├── swarm_agent.rb       # Multi-agent coordination system
│   ├── session_manager.rb   # LRU session management
│   ├── weaviate_helper.rb   # Direct Weaviate API integration
│   ├── universal_scraper.rb # Advanced web scraping
│   ├── multi_llm_manager.rb # Provider management
│   ├── cognitive_orchestrator.rb # Load-aware processing
│   ├── memory_manager.rb    # Vector-powered memory
│   ├── tool_manager.rb      # Dynamic tool loading
│   └── ...                  # Additional core components
├── assistants/              # Specialized AI assistants
│   ├── assistant_chat.rb    # Multi-assistant session management
│   ├── hacker_pen_tester.rb # Security swarm analysis
│   ├── chatbot_tinder.rb    # Dating app automation
│   ├── musicians.rb         # Music creation with agent swarm
│   ├── chatbots/           # Social media bot framework
│   └── ...                  # Additional specialists
├── config/                  # Configuration files
└── spec/                   # Test suites
```

## 🛠 Installation

### Prerequisites
- **Ruby 3.2+** with bundler
- **OpenBSD** (recommended for security features)
- **Optional**: Weaviate instance for vector database
- **Optional**: API keys for OpenAI, Anthropic, etc.

### Quick Start
```bash
# Clone the repository
git clone <repository_url>
cd ai3

# Install dependencies
bundle install

# Configure environment (optional)
cp .env.example .env
# Edit .env with your API keys

# Start AI³ interactive session
ruby ai3.rb
```

### Configuration
Edit `config.yml` to customize:
- LLM providers and models
- Weaviate connection settings  
- Scraper configuration
- Swarm agent limits
- Security settings

## 🚦 Usage Examples

### Interactive CLI
```bash
$ ruby ai3.rb
Welcome to AI³ (AI Cubed) - Advanced Intelligent Integration Interface
AI³> help
Available commands: assistants, swarm, scrape, session, config, exit
AI³> assistants
Available assistants: casual, lawyer, hacker, musician, architect...
AI³> load hacker
HackerPenTester loaded with 10-agent security swarm
```

### Multi-Assistant Chat
```ruby
require_relative 'assistants/assistant_chat'
chat = MultiAssistantChat.new
chat.start
# Interact with legal, architect, music, manufacturing specialists
```

### Swarm Agent Analysis
```ruby
require_relative 'lib/swarm_agent'

# Create specialized swarm
music_agents = [
  { name: 'electronic', genre: 'edm', skills: ['synthesis', 'beat_programming'] },
  { name: 'classical', genre: 'orchestral', skills: ['composition', 'arrangement'] },
  { name: 'jazz', genre: 'fusion', skills: ['improvisation', 'harmony'] }
]

swarm = SwarmAgent.new(music_agents)
result = swarm.execute_swarm_analysis({
  type: 'music_composition',
  requirements: ['modern', 'innovative', 'danceable']
})
```

### Social Media Automation
```ruby
# Tinder bot with AI matching
tinder = Assistants::TinderAssistant.new(api_key)
tinder.engage_with_new_friends
# AI analyzes profiles and starts conversations

# Discord bot with dynamic CSS detection  
discord = Assistants::ChatbotDiscord.new(token)
discord.monitor_and_engage
```

## 🔧 Development

### Adding New Assistants
1. Create assistant file in `assistants/`
2. Inherit from `BaseAssistant` 
3. Implement specialized functionality
4. Add to assistant registry

### Extending Swarm Capabilities
1. Define agent specializations
2. Use `SwarmAgent.new(specializations)`
3. Implement domain-specific analysis
4. Leverage cross-agent collaboration

### Custom Tool Integration
1. Add tool to `lib/` directory
2. Update `tool_manager.rb` 
3. Implement tool interface
4. Test with main CLI

## 📊 Performance & Monitoring

- **Swarm Status**: Real-time agent performance metrics
- **Session Analytics**: Usage patterns and success rates  
- **Memory Efficiency**: LRU eviction and cleanup monitoring
- **LLM Usage**: Token consumption and rate limiting
- **Vector Search**: Query performance and similarity scores

## 🔒 Security Features

- **OpenBSD pledge/unveil**: System call restrictions
- **Safe Ruby execution**: Sandboxed code evaluation
- **Encrypted sessions**: Secure context storage
- **Access control**: Granular file and network permissions
- **Audit logging**: Comprehensive activity tracking

## 🌍 Use Cases

- **Healthcare**: Medical research with specialized swarms
- **Urban Planning**: Multi-perspective city design analysis  
- **Scientific Research**: Cross-disciplinary investigation
- **Creative Industries**: Music, art, and content creation
- **Security Analysis**: Comprehensive penetration testing
- **Social Automation**: Intelligent engagement across platforms

---

**AI³ transforms traditional AI assistants into a coordinated intelligence network, enabling sophisticated multi-agent analysis and automation across diverse domains.**



Usage
Launch the interactive CLI with ruby ai3.rb. Available commands:

chat <query>: Chat with an assistant (e.g., chat What is AI?).
task <name> [args]: Run a task (e.g., task analyze_market Bitcoin).
rag <query>: Perform a RAG query (e.g., rag Norwegian laws).
list: List available assistants.
help: Show help.
exit: Exit the CLI.

Assistants



Assistant
Role
Example Command



General
General-purpose queries
chat Explain quantum computing


OffensiveOps
Sentiment trend analysis
chat Analyze news sentiment


Influencer
Social media content curation
chat Curate Instagram posts


Lawyer
Legal research
rag Norwegian data privacy laws


Trader
Cryptocurrency analysis
task analyze_market Ethereum


Architect
Parametric design
chat Explore sustainable designs


Hacker
Ethical hacking
chat Find Apache vulnerabilities


ChatbotSnapchat
Snapchat engagement
chat Engage Snapchat users


ChatbotOnlyfans
OnlyFans engagement
chat Engage OnlyFans users


Personal
Task management
chat Schedule my day


Music
Music creation
chat Compose a jazz track


MaterialRepurposing
Repurposing ideas
chat Repurpose plastic bottles


SEO
Web optimization
chat Optimize blog for SEO


Medical
Medical research
rag Latest on Alzheimer’s


PropulsionEngineer
Propulsion analysis
chat Analyze rocket engines


LinuxOpenbsdDriverTranslator
Driver translation
chat Translate Linux driver


Advanced Features

UniversalScraper: Uses Ferrum to scrape web content, capturing page source and screenshots to determine depth.
Multimedia: Combines Replicate.com’s AI models for TV/news broadcasting (e.g., real-time visuals, automated scripts).
FileUtils: Allows LLMs to:
Execute system commands (e.g., doas su for root access).
Browse the internet via UniversalScraper.
Complete projects (e.g., generate code, manage files).
Speculative: Orchestrate 3D printing of exoskeletons.



Configuration
Edit config.yml to customize:

LLM Settings: Primary/secondary LLMs, temperature, max tokens.
RAG: Weaviate host, index name, sources.
Scraper: Max depth, timeout, screenshot directory.
Multimedia: Model cache, output directory.
FileUtils: Root access, command timeout, max file size.
Assistants: Tools, URLs, default goals.

Example:
llm:
  primary: "xai"
  temperature: 0.6
scraper:
  max_depth: 2
  timeout: 30
multimedia:
  output_dir: "data/models/multimedia"
assistants:
  general:
    role: "General-purpose assistant"
    default_goal: "Explore diverse topics"

Development
Dependencies
Install gems via Gemfile:
bundle install

Directory Structure
ai3/
├── ai3.rb                # Interactive CLI
├── assistants/           # Assistant Ruby files
├── config/
│   ├── config.yml        # Configuration
│   └── locales/en.yml    # Localization
├── lib/
│   ├── cognitive.rb      # Shared logic
│   ├── multimedia.rb     # Replicate model management
│   ├── scraper.rb        # UniversalScraper
│   ├── mock_classes.rb   # Mock dependencies
│   └── utils/
│       ├── config.rb     # Config loader
│       ├── file.rb       # File and system operations
│       └── llm.rb        # LLM utilities
├── data/                 # Cache, vector DB, models, screenshots
├── logs/                 # Logs
├── tmp/                  # Temporary files
├── install.sh            # Core installer
├── install_ass.sh        # Assistants installer
├── Gemfile               # Dependencies
└── README.md             # Documentation

Adding Assistants

Create a new Ruby file in assistants/ (e.g., new_assistant.rb):# frozen_string_literal: true

require_relative "base_assistant"
require_relative "../lib/cognitive"

class NewAssistant < BaseAssistant
  include Cognitive

  def initialize
    super("new_assistant")
    set_goal(AI3::Config.instance["assistants"]["new_assistant"]["default_goal"])
  end

  def respond(input)
    decrypted_input = AI3.session_manager.decrypt(input)
    pursue_goal if rand < 0.2
    AI3.with_retry do
      response = @agent.run(decrypted_input)
      AI3.session_manager.encrypt(AI3.summarize(response))
    end
  end
end


Update config.yml:assistants:
  new_assistant:
    role: "New assistant role"
    llm: "grok"
    tools: ["SystemTool"]
    urls: ["https://example.com"]
    default_goal: "Explore new topics"


Run install_ass.sh to regenerate assistants.

Security

OpenBSD: Uses pledge/unveil to restrict system calls and file access.
Root Access: Enabled via doas for network diagnostics, system modifications.
Encryption: Session data encrypted via SessionManager.
Ethics: Input checked for unethical content.

Troubleshooting

LLM Errors: Ensure API keys are set in ~/.ai3_keys.
Weaviate Issues: Verify Weaviate is running at the configured host.
Scraper Issues: Check Ferrum installation and network connectivity.
Logs: Check logs/ai3.log for errors.

License
MIT License. See LICENSE for details.
Contact
For support, contact the AI^3 team at support@ai3.example.com.