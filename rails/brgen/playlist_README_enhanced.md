# Brgen Playlist - Enhanced Music Platform

## Overview
Brgen Playlist is a community-driven music sharing platform with advanced analytics, karma/reputation system, and enhanced social features. Built on Rails 8 with modern web technologies.

## Features

### Core Music Features
- 🎵 **Playlist Management**: Create and manage music playlists with track ordering
- 🎶 **Music Integration**: Support for Spotify and YouTube links
- ⭐ **Ratings & Reviews**: Community-driven rating system for playlists
- 👥 **Follow System**: Follow other users' playlists
- 🔍 **Advanced Search**: Live search with StimulusReflex
- 📱 **PWA Support**: Installable web app with offline support

### Enhanced Social Features
- 👍 **Karma System**: Reputation points for content creation and community engagement
- 🗳️ **Voting**: Upvote/downvote playlists and comments
- 💬 **Comments**: Discussion system for playlists
- 📈 **Analytics**: Track plays, engagement, and user behavior
- 🏆 **User Levels**: Progress through community levels based on karma
- 👑 **Trending**: Discover trending playlists

### Music Player Features
- ▶️ **Web Player**: Built-in music player for supported platforms
- 📊 **Play Tracking**: Track play counts and listening analytics
- 🔄 **Shuffle & Repeat**: Advanced playback controls
- 📱 **Mobile Optimized**: Touch-friendly mobile controls

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
- 📂 **File Uploads**: Active Storage for playlist artwork
- 🔐 **Authentication**: Devise with Vipps integration

## User Reputation System

### Karma Points
- **Playlist Creation**: +10 points for creating playlists
- **Track Addition**: +2 points for adding tracks
- **Comments**: +1 point for writing comments
- **Follows Received**: +2 points per follow
- **Upvotes Received**: +3 points per upvote
- **Downvotes Received**: -1 point per downvote

### User Levels
1. **Music Listener** (0-49 karma): Basic access
2. **Playlist Creator** (50-149 karma): Enhanced playlist features
3. **Music Curator** (150-299 karma): Advanced curation tools
4. **Community DJ** (300-499 karma): Promotion features
5. **Music Influencer** (500-999 karma): Moderation tools
6. **Music Master** (1000+ karma): All features unlocked

## Analytics Dashboard

### Tracked Metrics
- Playlist plays and user engagement
- Track popularity and skip rates
- User behavior patterns
- Content creation trends
- Community growth metrics
- Follow relationships

### Available Reports
- Popular playlists analysis
- User engagement trends
- Music genre preferences
- Community health metrics

## Music Integration

### Supported Platforms
- **Spotify**: Direct playlist and track linking
- **YouTube**: Music video integration
- **SoundCloud**: Audio track embedding (planned)
- **Apple Music**: Deep linking support (planned)

### Player Features
- Cross-platform playback support
- Automatic track progression
- Play count tracking
- User listening history
- Offline playlist caching (PWA)

## SEO Optimization

### Automated SEO Features
- Dynamic meta tags for all playlists
- Schema.org structured data for music
- Automatic sitemap generation
- SEO-friendly URL structure
- Open Graph tags for social sharing
- Rich snippets for search results

## Installation

Run the setup script:
```bash
chmod +x playlist.sh
./playlist.sh
```

## Database Models

### Core Models
- **Playlist**: Music playlists with tracks, ratings, and karma
- **Track**: Individual songs with platform URLs and metadata
- **Comment**: User discussions on playlists
- **PlaylistFollow**: User following relationships
- **PlaylistRating**: User ratings for playlists

### Social Models
- **PlaylistKarma**: Track user karma and levels for music features
- **KarmaAction**: Log all karma-affecting actions
- **Vote**: Handle upvotes/downvotes (via acts_as_votable)

### Analytics Models
- **Ahoy::Visit**: Track user visits
- **Ahoy::Event**: Track user events and interactions

## API Endpoints

### Playlists
- `GET /playlists` - List all public playlists with pagination
- `GET /playlists/:id` - Playlist details with tracks
- `POST /playlists` - Create new playlist (authenticated)
- `PATCH /playlists/:id` - Update playlist (owner only)
- `DELETE /playlists/:id` - Delete playlist (owner only)
- `POST /playlists/:id/play` - Get playlist data for player

### Tracks
- `GET /playlists/:playlist_id/tracks` - List tracks in order
- `POST /playlists/:playlist_id/tracks` - Add track to playlist
- `PATCH /tracks/:id` - Update track details
- `DELETE /tracks/:id` - Remove track from playlist
- `POST /tracks/:id/move_up` - Move track up in playlist
- `POST /tracks/:id/move_down` - Move track down in playlist

### Social Features
- `POST /playlists/:id/follow` - Follow/unfollow playlist
- `POST /playlists/:id/vote` - Vote on playlist
- `GET /playlists/:id/followers` - List followers

### Analytics
- `GET /analytics/dashboard` - View analytics (admin only)
- `GET /blazer` - SQL analytics dashboard

## Real-time Features

### StimulusReflex
- Live search results
- Real-time voting updates  
- Infinite scroll pagination
- Live follower count updates
- Real-time play count tracking

### WebSocket Events
- Vote updates
- New playlist notifications
- Follow notifications
- Live play tracking

## Caching Strategy

### Cache Layers
- **Redis**: Primary cache store
- **Fragment Caching**: Playlist and track partials
- **Model Caching**: Database queries
- **CDN**: Static assets and audio files (production)

### Cache Keys
- `playlist/{id}` - Individual playlist data
- `playlist/count` - Total playlist count
- `track/{id}` - Track data
- `playlist_karma/{user_id}` - User karma data
- `playlist/{id}/tracks` - Playlist track list

## Music Player

### Client-Side Player
- HTML5 Audio API integration
- Playlist queue management
- Shuffle and repeat modes
- Volume control
- Progress tracking
- Cross-fade between tracks (planned)

### Analytics Integration
- Track completion rates
- Skip patterns
- Popular track segments
- User listening habits
- Device usage statistics

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
6. Configure CDN for audio files

### Environment Variables
- `SPOTIFY_CLIENT_ID` - Spotify API integration
- `SPOTIFY_CLIENT_SECRET` - Spotify API secret
- `YOUTUBE_API_KEY` - YouTube Data API key

## Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new features
4. Submit pull request
5. Maintain code quality standards

## License

This project is part of the Brgen platform ecosystem.