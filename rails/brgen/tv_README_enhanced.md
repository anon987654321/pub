# Brgen TV - Enhanced Streaming Platform

## Overview
Brgen TV is a community-driven streaming platform with advanced analytics, karma/reputation system, and enhanced social features. Built on Rails 8 with modern web technologies.

## Features

### Core TV Features
- 📺 **Show Management**: Create and manage TV shows with episodes
- 🎬 **Episode Streaming**: Stream episodes with progress tracking
- ⭐ **Ratings & Reviews**: Community-driven rating system
- 🔍 **Advanced Search**: Live search with StimulusReflex
- 📱 **PWA Support**: Installable web app with offline support

### Enhanced Social Features
- 👍 **Karma System**: Reputation points for content creation and community engagement
- 🗳️ **Voting**: Upvote/downvote shows and episodes
- 💬 **Reviews**: Detailed show reviews with helpfulness voting
- 📈 **Analytics**: Track views, engagement, and user behavior
- 🏆 **User Levels**: Progress through community levels based on karma

### SEO & Performance
- 🔗 **SEO-Friendly URLs**: Slug-based URLs with FriendlyId
- 🗺️ **Sitemap Generation**: Automatic sitemap updates
- 🚀 **Caching**: Redis-based caching for performance
- 📊 **Analytics**: Comprehensive tracking with Ahoy Matey
- 📱 **Mobile-First**: Responsive design

### Technical Features
- ⚡ **Rails 8**: Latest Rails with modern features
- 🔄 **StimulusReflex**: Real-time updates without page refresh
- 🏢 **Multi-Tenancy**: City-based content isolation
- 📂 **File Uploads**: Active Storage for posters and videos
- 🔐 **Authentication**: Devise with Vipps integration

## User Reputation System

### Karma Points
- **Content Creation**: +10 points for creating shows
- **Episode Creation**: +5 points for adding episodes
- **Reviews**: +3 points for writing reviews
- **Upvotes Received**: +5 points per upvote
- **Downvotes Received**: -2 points per downvote

### User Levels
1. **Newcomer** (0-99 karma): Basic access
2. **Regular Viewer** (100-499 karma): Enhanced features
3. **TV Enthusiast** (500-999 karma): Advanced features
4. **Content Creator** (1000-2499 karma): Creator tools
5. **Community Leader** (2500-4999 karma): Moderation tools
6. **TV Master** (5000+ karma): All features unlocked

## Analytics Dashboard

### Tracked Metrics
- Page views and user engagement
- Show and episode popularity
- User behavior patterns
- Content creation trends
- Community growth metrics

### Available Reports
- Popular content analysis
- User engagement trends
- Content creation statistics
- Community health metrics

## SEO Optimization

### Automated SEO Features
- Dynamic meta tags for all pages
- Schema.org structured data
- Automatic sitemap generation
- SEO-friendly URL structure
- Open Graph tags for social sharing

## Installation

Run the setup script:
```bash
chmod +x tv.sh
./tv.sh
```

## Database Models

### Core Models
- **Show**: TV series with episodes, ratings, and karma
- **Episode**: Individual episodes with streaming support
- **ShowReview**: User reviews with ratings
- **Viewing**: Track user viewing progress

### Social Models
- **UserReputation**: Track user karma and levels
- **KarmaAction**: Log all karma-affecting actions
- **Vote**: Handle upvotes/downvotes (via acts_as_votable)

### Analytics Models
- **Ahoy::Visit**: Track user visits
- **Ahoy::Event**: Track user events and interactions

## API Endpoints

### Shows
- `GET /shows` - List all shows with pagination
- `GET /shows/:id` - Show details with episodes
- `POST /shows` - Create new show (authenticated)
- `PATCH /shows/:id` - Update show (owner only)
- `DELETE /shows/:id` - Delete show (owner only)

### Episodes
- `GET /shows/:show_id/episodes` - List episodes
- `GET /shows/:show_id/episodes/:id` - Episode details
- `POST /shows/:show_id/episodes` - Create episode
- `PATCH /episodes/:id` - Update episode
- `DELETE /episodes/:id` - Delete episode

### Analytics
- `GET /analytics/dashboard` - View analytics (admin only)
- `GET /blazer` - SQL analytics dashboard

## Real-time Features

### StimulusReflex
- Live search results
- Real-time voting updates  
- Infinite scroll pagination
- Live view count updates

### WebSocket Events
- Vote updates
- New content notifications
- Real-time user presence
- Live chat integration

## Caching Strategy

### Cache Layers
- **Redis**: Primary cache store
- **Fragment Caching**: View partials
- **Model Caching**: Database queries
- **CDN**: Static assets (production)

### Cache Keys
- `show/{id}` - Individual show data
- `show/count` - Total show count
- `episode/{id}` - Episode data
- `user_reputation/{user_id}` - User karma data

## Deployment

### Requirements
- Ruby 3.3.0+
- Rails 8.0+
- PostgreSQL 13+
- Redis 6.0+
- Node.js 20+

### Production Setup
1. Set environment variables
2. Run database migrations
3. Precompile assets
4. Start background jobs
5. Generate initial sitemap

## Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new features
4. Submit pull request
5. Maintain code quality standards

## License

This project is part of the Brgen platform ecosystem.