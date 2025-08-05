**Critical Architecture Requirements for BRGEN Restoration:**

🏗️ **Core Multi-tenancy Architecture:**
- **acts_as_tenant** for multisite/multidomain functionality (CENTRAL requirement)
- **devise** for user authentication 
- **devise-guests** for anonymous functionality
- **omniauth strategies** specifically for www.vipps.no integration

🎯 **BRGEN Platform Features (Bergen, Norway):**
Modern reinterpretation combining:
- **Reddit-style** discussions and voting
- **Craigslist-style** classified postings  
- **X.com (Twitter)-style** social feeds
- **TikTok-style** short-form content
- **Snapchat-style** messaging (brgen messenger)

✨ **UX/Design Principles:**
- **Anonymous posting** capability
- **Anonymous live chat** functionality
- **Excellent usability** focus
- **Ultraminimalistic design** approach
- **Modern web development** techniques

🔧 **Technical Priorities:**
1. Preserve acts_as_tenant multisite configuration
2. Maintain devise + devise-guests setup
3. Keep Vipps.no omniauth integration
4. Ensure anonymous functionality works
5. Preserve live chat system
6. Maintain minimalistic UI/UX patterns

Please prioritize these requirements during the Rails application restoration process.