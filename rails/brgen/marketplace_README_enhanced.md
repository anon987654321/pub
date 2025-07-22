# Brgen Marketplace - Enhanced E-commerce Platform

## Overview
Brgen Marketplace is a community-driven e-commerce platform with advanced analytics, karma/reputation system, and enhanced social features. Built on Rails 8 with modern web technologies.

## Features

### Core Marketplace Features
- 🛒 **Product Management**: Create and manage product listings with multiple photos
- 💳 **Order System**: Complete order processing from listing to delivery
- ⭐ **Reviews & Ratings**: Community-driven rating system for products and sellers
- ❤️ **Favorites**: Save favorite products for later
- 🔍 **Advanced Search**: Live search with category and condition filters
- 📱 **PWA Support**: Installable web app with offline support

### Enhanced Social Features
- 👍 **Karma System**: Reputation points for selling, reviews, and community engagement
- 🗳️ **Voting**: Upvote/downvote products and reviews
- 💬 **Q&A System**: Product questions and answers
- 📈 **Analytics**: Track views, engagement, and sales behavior
- 🏆 **Seller Levels**: Progress through seller levels based on karma
- 🔥 **Trending**: Discover trending products

### E-commerce Features
- 📦 **Multi-Category Support**: Electronics, clothing, home & garden, and more
- 🏷️ **Condition Tracking**: New, like-new, good, fair, poor conditions
- 💰 **Flexible Pricing**: Support for various pricing strategies
- 🚚 **Order Management**: Track orders from placement to completion
- 📊 **Sales Analytics**: Comprehensive seller dashboards
- 🔒 **Secure Transactions**: Built-in fraud protection

### SEO & Performance
- 🔗 **SEO-Friendly URLs**: Slug-based URLs with FriendlyId
- 🗺️ **Sitemap Generation**: Automatic sitemap updates
- 🚀 **Caching**: Redis-based caching for performance
- 📊 **Analytics**: Comprehensive tracking with Ahoy Matey
- 📱 **Mobile-First**: Responsive design optimized for mobile shopping

### Technical Features
- ⚡ **Rails 8**: Latest Rails with modern features
- 🔄 **StimulusReflex**: Real-time updates without page refresh
- 🏢 **Multi-Tenancy**: City-based marketplace isolation
- 📂 **File Uploads**: Active Storage for product photos
- 🔐 **Authentication**: Devise with Vipps integration

## User Reputation System

### Karma Points
- **Product Listing**: +10 points for creating products
- **Successful Sale**: +5 points for completed sales
- **Product Reviews**: +1 point for writing reviews
- **Helpful Q&A**: +2 points for answering questions
- **Upvotes Received**: +3 points per upvote
- **Downvotes Received**: -1 point per downvote
- **Favorites Received**: +1 point per favorite

### Seller Levels
1. **New Seller** (0-24 karma): Basic listing features
2. **Casual Trader** (25-74 karma): Enhanced listing options
3. **Active Seller** (75-149 karma): Featured listing privileges
4. **Marketplace Pro** (150-299 karma): Advanced seller tools
5. **Trusted Vendor** (300-499 karma): Premium seller badges
6. **Marketplace Master** (500+ karma): All features unlocked

## Product Categories

### Available Categories
- **Electronics**: Phones, computers, gadgets
- **Clothing**: Fashion, accessories, shoes
- **Home & Garden**: Furniture, appliances, decor
- **Books & Media**: Books, movies, music
- **Sports & Outdoors**: Equipment, clothing, gear
- **Automotive**: Parts, accessories, tools
- **Toys & Games**: Children's toys, board games
- **Health & Beauty**: Cosmetics, wellness products
- **Tools & DIY**: Hardware, power tools, supplies
- **Collectibles**: Antiques, coins, memorabilia
- **Baby & Kids**: Clothing, toys, equipment

### Condition Ratings
- **New**: Brand new, never used
- **Like New**: Barely used, excellent condition
- **Good**: Used but well-maintained
- **Fair**: Used with some wear
- **Poor**: Heavily used, functional issues

## Analytics Dashboard

### Tracked Metrics
- Product views and engagement
- Sales conversion rates
- User behavior patterns
- Category popularity trends
- Seller performance metrics
- Market demand analysis

### Available Reports
- Sales performance analysis
- Product popularity trends
- User engagement metrics
- Market health indicators
- Revenue analytics

## Order Management

### Order Statuses
- **Pending**: Order placed, awaiting seller confirmation
- **Confirmed**: Seller confirmed, preparing for shipment
- **Shipped**: Item shipped, tracking available
- **Delivered**: Item delivered to buyer
- **Completed**: Transaction completed successfully
- **Cancelled**: Order cancelled by buyer or seller
- **Disputed**: Issue reported, under review

### Payment Integration
- Secure payment processing
- Multiple payment methods
- Automatic seller payouts
- Transaction fee handling
- Dispute resolution system

## SEO Optimization

### Automated SEO Features
- Dynamic meta tags for all products
- Schema.org structured data for products
- Automatic sitemap generation
- SEO-friendly URL structure
- Open Graph tags for social sharing
- Rich snippets for search results

## Installation

Run the setup script:
```bash
chmod +x marketplace.sh
./marketplace.sh
```

## Database Models

### Core Models
- **Product**: Product listings with photos, pricing, and metadata
- **Order**: Purchase orders with status tracking
- **ProductReview**: User reviews with ratings
- **ProductFavorite**: User saved products
- **ProductQuestion**: Q&A system for products

### Social Models
- **MarketplaceKarma**: Track user karma and seller levels
- **KarmaAction**: Log all karma-affecting actions
- **Vote**: Handle upvotes/downvotes (via acts_as_votable)

### Analytics Models
- **Ahoy::Visit**: Track user visits
- **Ahoy::Event**: Track user events and interactions

## API Endpoints

### Products
- `GET /products` - List all available products with pagination
- `GET /products/:id` - Product details with reviews and Q&A
- `POST /products` - Create new product listing (authenticated)
- `PATCH /products/:id` - Update product (owner only)
- `DELETE /products/:id` - Delete product (owner only)
- `POST /products/:id/mark_sold` - Mark product as sold

### Orders
- `GET /orders` - List user orders
- `GET /orders/:id` - Order details
- `POST /products/:id/orders` - Place order
- `PATCH /orders/:id` - Update order details
- `POST /orders/:id/cancel` - Cancel order

### Social Features
- `POST /products/:id/favorite` - Add/remove from favorites
- `POST /products/:id/vote` - Vote on product
- `POST /products/:id/questions` - Ask product question

### Analytics
- `GET /analytics/dashboard` - View analytics (admin only)
- `GET /blazer` - SQL analytics dashboard

## Real-time Features

### StimulusReflex
- Live search results with filters
- Real-time voting updates  
- Infinite scroll pagination
- Live favorite count updates
- Real-time order status updates

### WebSocket Events
- Vote updates
- New product notifications
- Order status changes
- Q&A updates
- Favorite notifications

## Caching Strategy

### Cache Layers
- **Redis**: Primary cache store
- **Fragment Caching**: Product and review partials
- **Model Caching**: Database queries
- **CDN**: Product images and static assets

### Cache Keys
- `product/{id}` - Individual product data
- `product/count` - Total product count
- `marketplace_karma/{user_id}` - User karma data
- `product/{id}/reviews` - Product review list
- `category/{name}/products` - Category product list

## Security Features

### Transaction Security
- Payment processing integration
- Fraud detection algorithms
- Secure file uploads
- Input validation and sanitization
- Rate limiting on sensitive endpoints

### Privacy Protection
- User data anonymization options
- GDPR compliance features
- Secure image handling
- Personal information protection

## Mobile Experience

### Mobile-First Design
- Touch-optimized interface
- Swipe gestures for photo galleries
- Mobile payment integration
- Push notifications (PWA)
- Offline product browsing

### Performance Optimization
- Image lazy loading
- Progressive image loading
- Mobile-optimized caching
- Fast mobile checkout flow

## Deployment

### Requirements
- Ruby 3.3.0+
- Rails 8.0+
- PostgreSQL 13+
- Redis 6.0+
- Node.js 20+
- Image processing capabilities

### Production Setup
1. Set environment variables
2. Run database migrations
3. Precompile assets
4. Configure image processing
5. Start background jobs
6. Generate initial sitemap
7. Configure payment processing

### Environment Variables
- `STRIPE_PUBLISHABLE_KEY` - Stripe payment integration
- `STRIPE_SECRET_KEY` - Stripe API secret
- `VIPPS_CLIENT_ID` - Vipps payment integration
- `IMAGE_PROCESSING_SERVICE` - Image optimization service

## Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new features
4. Submit pull request
5. Maintain code quality standards

## License

This project is part of the Brgen platform ecosystem.