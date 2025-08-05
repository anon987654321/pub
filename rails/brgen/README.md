# Brgen - Hyper-Local Multi-Tenant Social Platform

### Framework v35.3.8 Compliant | Rails 8.0 | OpenBSD 7.5 | Production Ready

**Brgen** redefines the concept of a social network, leveraging AI to create a hyper-localized platform tailored to major cities around the globe. Built with Rails 8.0 and modern web technologies, Brgen seamlessly integrates multiple sub-applications with comprehensive security, accessibility, and performance optimizations.

## 🏗️ Architecture Overview

Brgen is a **multi-tenant Rails 8 application** featuring:

- **Online Marketplace**: Local buying and selling platform
- **Dating Service**: Hyper-localized dating with geolocation
- **Music Sharing Platform**: Collaborative music discovery
- **Record Label**: Local talent promotion
- **Television Channel**: City-specific content delivery
- **Street Food Delivery**: Local vendor network

## 🚀 Quick Start

### Prerequisites

**System Requirements (OpenBSD 7.5)**:
- Ruby 3.3.0+
- Node.js 20+
- PostgreSQL 15+
- Redis 7+
- Git

```bash
# Install system dependencies on OpenBSD 7.5
pkg_add ruby-3.3.0 node-20 postgresql-server redis git

# Start required services
rcctl enable postgresql redis
rcctl start postgresql redis
```

### Installation

1. **Clone and Setup**:
```bash
git clone https://github.com/your-org/brgen.git
cd brgen/rails/brgen
chmod +x brgen.sh
```

2. **Run Setup Script**:
```bash
./brgen.sh
```

This will automatically:
- Create Rails 8 application with modern stack
- Configure Solid Queue & Solid Cache
- Setup multi-tenant architecture
- Install security enhancements
- Configure accessibility features
- Setup database optimizations

3. **Environment Configuration**:
```bash
# Copy and configure environment
cp .env.example .env

# Edit with your configuration
nano .env
```

### Environment Variables

**Required**:
```env
DATABASE_URL=postgresql://user:password@localhost/brgen_production
REDIS_URL=redis://localhost:6379/1

# API Keys
MAPBOX_ACCESS_TOKEN=pk.your_mapbox_token
STRIPE_SECRET_KEY=sk_your_stripe_key
VIPPS_CLIENT_ID=your_vipps_id
VIPPS_CLIENT_SECRET=your_vipps_secret

# Security
SECRET_KEY_BASE=your_secret_key
```

**Optional**:
```env
# Performance
RAILS_MAX_THREADS=25
WEB_CONCURRENCY=4

# Monitoring
SENTRY_DSN=your_sentry_dsn
```

## 🌍 Supported Cities

Brgen operates in **45+ major cities** across multiple regions:

### Nordic Region
- **Norway**: Bergen (brgen.no), Oslo (oshlo.no), Trondheim (trndheim.no), Stavanger (stvanger.no), Tromsø (trmso.no), Longyearbyen (longyearbyn.no)
- **Iceland**: Reykjavik (reykjavk.is)
- **Denmark**: Copenhagen (kobenhvn.dk)
- **Sweden**: Stockholm (stholm.se), Gothenburg (gtebrg.se), Malmö (mlmoe.se)
- **Finland**: Helsinki (hlsinki.fi)

### United Kingdom
- **England**: London (lndon.uk), Manchester (mnchester.uk), Birmingham (brmingham.uk), Liverpool (lverpool.uk)
- **Wales**: Cardiff (cardff.uk)
- **Scotland**: Edinburgh (edinbrgh.uk), Glasgow (glasgw.uk)

### Europe
- **Netherlands**: Amsterdam (amstrdam.nl), Rotterdam (rottrdam.nl), Utrecht (utrcht.nl)
- **Belgium**: Brussels (brssels.be)
- **Switzerland**: Zurich (zrich.ch)
- **Germany**: Frankfurt (frankfrt.de)
- **Poland**: Warsaw (wrsawa.pl), Gdansk (gdnsk.pl)
- **France**: Bordeaux (brdeaux.fr), Marseille (mrseille.fr)
- **Italy**: Milan (mlan.it)
- **Portugal**: Lisbon (lsbon.pt)

### United States
- **Major Cities**: Los Angeles (lsangeles.com), New York (newyrk.us), Chicago (chcago.us), Houston (houstn.us), Dallas (dllas.us), Austin (austn.us), Portland (prtland.com), Minneapolis (mnneapolis.com)

## 🏛️ Technical Stack

### Backend
- **Rails 8.0** with Solid Queue & Solid Cache
- **PostgreSQL 15+** with optimized indexing
- **Redis 7+** for caching and real-time features
- **Falcon** web server for production

### Frontend
- **Hotwire/Turbo** for SPA-like experience
- **Stimulus** controllers with accessibility features
- **Modern JavaScript (ES6+)** with performance optimizations
- **SCSS** with design system variables

### Security & Performance
- **Multi-tenant isolation** with ActsAsTenant
- **WCAG 2.1 AA compliance** throughout
- **Rate limiting** and security headers
- **Database optimizations** with concurrent indexing
- **Full-text search** with PostgreSQL GIN indexes

## 🛠️ Development

### Local Development Setup

1. **Database Setup**:
```bash
# Create databases
createdb brgen_development
createdb brgen_test

# Run migrations
bin/rails db:migrate
bin/rails db:seed
```

2. **Start Development Server**:
```bash
# With Falcon (recommended)
bin/falcon-host

# Or with Rails server
bin/rails server
```

3. **Run Tests**:
```bash
# Full test suite
bin/rails test

# Specific tests
bin/rails test test/models/
bin/rails test test/controllers/
```

### Database Optimizations

The application includes comprehensive database optimizations:

- **Concurrent indexing** for zero-downtime deployments
- **Full-text search indexes** for posts and listings
- **Optimized connection pooling** for high concurrency
- **Query performance monitoring** in development

### Multi-Tenant Configuration

Each city operates as an isolated tenant:

```ruby
# Set tenant programmatically
ActsAsTenant.current_tenant = City.find_by(subdomain: 'brgen')

# In controllers (automatic via middleware)
@current_tenant # => Current city tenant
```

## 🔐 Security Features

### Framework v35.3.8 Security Compliance

- **Tenant isolation** with security middleware
- **Rate limiting** per tenant and IP
- **CSRF protection** with enhanced tokens
- **Input validation** and XSS prevention
- **API security** with webhook signature verification
- **Audit logging** for security events

### Authentication & Authorization

- **Devise** with enhanced security features
- **Vipps OAuth** integration for Nordic users
- **Account locking** after failed attempts
- **Session timeout** for security
- **Guest user** support with limitations

## ♿ Accessibility Features

### WCAG 2.1 AA Compliance

- **Keyboard navigation** for all interactive elements
- **Screen reader support** with ARIA labels
- **High contrast** design system
- **Focus management** and visual indicators
- **Alternative text** for images and icons
- **Semantic HTML** structure throughout

### Accessibility Testing

```bash
# Run accessibility tests
bin/rails test:accessibility

# Lighthouse audit
npm run lighthouse

# WAVE validator integration
curl -X POST "https://wave.webaim.org/api/request" -d "url=http://localhost:3000"
```

## 📊 Performance Monitoring

### Built-in Optimizations

- **Solid Queue** for background job processing
- **Solid Cache** for intelligent caching
- **Pagy pagination** with countless mode
- **Image optimization** with Active Storage variants
- **CDN integration** ready
- **Database query optimization** with includes and select

### Monitoring Setup

```bash
# Performance profiling
bin/rails performance:profile

# Memory usage analysis
bin/rails performance:memory

# Database query analysis
bin/rails db:analyze
```

## 🚀 Deployment

### OpenBSD 7.5 Production Setup

1. **System Preparation**:
```bash
# Install production dependencies
pkg_add ruby-3.3.0 node-20 postgresql-server redis nginx

# Configure services
rcctl enable postgresql redis nginx falcon
```

2. **Application Deployment**:
```bash
# Clone to production directory
git clone https://github.com/your-org/brgen.git /var/www/brgen

# Install dependencies
cd /var/www/brgen
bundle install --deployment --without development test
yarn install --production

# Precompile assets
RAILS_ENV=production bin/rails assets:precompile

# Run migrations
RAILS_ENV=production bin/rails db:migrate
```

3. **Service Configuration**:
```bash
# Falcon configuration
cp config/falcon.rb.example config/falcon.rb

# Start services
rcctl start postgresql redis nginx
bin/falcon-host
```

### Docker Deployment

```dockerfile
# Use official Ruby image
FROM ruby:3.3.0-alpine

# Install dependencies
RUN apk add --no-cache postgresql-dev nodejs yarn

# Setup application
WORKDIR /app
COPY . .
RUN bundle install --deployment
RUN yarn install --production

# Expose port
EXPOSE 3000

# Start application
CMD ["bin/falcon-host"]
```

## 🧪 Testing

### Test Suite

```bash
# Run all tests
bin/rails test

# Model tests
bin/rails test test/models/

# Controller tests
bin/rails test test/controllers/

# Integration tests
bin/rails test test/integration/

# System tests (with browser)
bin/rails test:system
```

### Performance Testing

```bash
# Load testing with Apache Bench
ab -n 1000 -c 10 http://localhost:3000/

# Memory profiling
bin/rails performance:memory_profiler

# Database performance
bin/rails db:performance_test
```

## 📝 API Documentation

### REST API Endpoints

- `GET /api/v1/posts` - List posts for current tenant
- `POST /api/v1/posts` - Create new post
- `GET /api/v1/listings` - List marketplace items
- `POST /api/v1/listings` - Create marketplace listing
- `GET /api/v1/profiles` - List dating profiles
- `POST /stripe/webhook` - Stripe webhook handler

### WebSocket Channels

- `ChatChannel` - Real-time messaging
- `NotificationChannel` - Live notifications
- `ActivityChannel` - Live activity updates

## 🔧 Troubleshooting

### Common Issues

**Database Connection Errors**:
```bash
# Check PostgreSQL status
rcctl check postgresql

# Test connection
psql -h localhost -U brgen_user -d brgen_production
```

**Redis Connection Issues**:
```bash
# Check Redis status
rcctl check redis

# Test connection
redis-cli ping
```

**Asset Pipeline Issues**:
```bash
# Clear cache and recompile
bin/rails assets:clobber
bin/rails assets:precompile
```

### Performance Issues

**Slow Database Queries**:
```bash
# Analyze slow queries
bin/rails db:analyze_slow_queries

# Check index usage
bin/rails db:index_usage
```

**Memory Issues**:
```bash
# Memory profiling
bin/rails performance:memory_profile

# Garbage collection tuning
export RUBY_GC_HEAP_INIT_SLOTS=1000000
```

## 📚 Additional Resources

### Documentation

- [Rails 8 Upgrade Guide](docs/rails-8-upgrade.md)
- [Multi-Tenant Setup](docs/multi-tenant-guide.md)
- [Security Best Practices](docs/security-guide.md)
- [Accessibility Guidelines](docs/accessibility-guide.md)
- [Performance Optimization](docs/performance-guide.md)

### Community

- **GitHub Issues**: Bug reports and feature requests
- **Discord**: Real-time community support
- **Wiki**: Community-driven documentation

### License

MIT License - see [LICENSE](LICENSE) for details.

---

**Built with ❤️ using Framework v35.3.8 on OpenBSD 7.5**
  - **Illinois**: Chicago (chcago.us)
  - **Texas**: Houston (houstn.us), Dallas (dllas.us), Austin (austn.us)
  - **Oregon**: Portland (prtland.com)
  - **Minnesota**: Minneapolis (mnneapolis.com)

### Monetization Strategies

Brgen harnesses sophisticated monetization strategies, including:

- **SEO Strategies**: Leveraging search engine optimization for visibility.
- **Pay-per-click Advertising**: Generating revenue through targeted ads.
- **Affiliate Marketing**: Partnering with local and global brands.
- **Subscription Models**: Offering premium features for users.

### Key Features

- **Hyper-localized Content**: Custom content for each city.
- **AI-driven Insights**: Personalized user experience using advanced AI models.
- **Integrated Services**: All services are tightly integrated, providing a seamless user experience.

### Summary

Brgen is designed to bring communities together,
making each city feel like a closely-knit hub. It leverages AI and innovative monetization strategies to support local businesses and provide a unique social experience.