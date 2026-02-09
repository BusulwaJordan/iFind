# iFind - Local Business Connection Platform

**AI-ready mobile application connecting customers to businesses in Uganda**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Free-3ECF8E?logo=supabase)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🎯 Mission

iFind is a production-ready MVP that connects customers to local businesses with a special focus on stores and arcades in Uganda. Built with zero-cost infrastructure and world-class engineering, it's designed to scale to millions of users.

## ✨ Features

### Core Functionality
- **Multi-Role Authentication** - Customer, Business Owner, Manager roles
- **Business Discovery** - Category and distance-based search with maps
- **Virtual Arcades** - Stores with multiple independent shops
- **Product Listings** - Full product management for businesses
- **Realtime Chat** - In-app messaging between customers and businesses
- **Reviews & Ratings** - Customer feedback system
- **Analytics Dashboard** - Business performance insights
- **AI-Ready Recommendations** - Heuristic-based MVP, ML-ready architecture

### Security
- Supabase Row Level Security (RLS)
- Secure session handling
- Input validation
- Role-based permissions
- No secrets in client code

### UI/UX
- **Green & White Theme** - Clean, modern Material 3 design
- **Glassmorphism Effects** - Premium visual aesthetics
- **Smooth Animations** - 60fps interactions
- **Responsive Layout** - Works on all screen sizes

## 🏗️ Architecture

### Clean Architecture
```
lib/
├── core/               # Shared utilities, theme, errors
├── features/
│   ├── auth/          # Authentication feature
│   │   ├── data/      # Data sources, models, repositories
│   │   ├── domain/    # Entities, use cases, repository contracts
│   │   └── presentation/  # UI, providers, widgets
│   ├── business/      # Business management
│   ├── discovery/     # Business search & discovery
│   ├── chat/          # Realtime messaging
│   ├── products/      # Product management
│   ├── reviews/       # Ratings and reviews
│   ├── analytics/     # Business analytics
│   └── recommendations/  # AI recommendations
└── main.dart
```

### Tech Stack
- **Frontend**: Flutter 3.0+ (Dart)
- **State Management**: Riverpod
- **Backend**: Supabase (PostgreSQL + Auth + Realtime)
- **Maps**: OpenStreetMap (Flutter Map)
- **Design**: Material 3 + Google Fonts

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.2.0 or higher
- Dart SDK 3.0.0 or higher
- Supabase account (free tier)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/ifind.git
cd ifind
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Set up Supabase**
   - Create a new project at [supabase.com](https://supabase.com)
   - Run the SQL schema from `database/schema.sql` in the Supabase SQL Editor
   - Copy your project URL and anon key

4. **Configure environment**

Create a `.env` file:
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

Or update `lib/core/constants/api_constants.dart` directly (for development only)

5. **Run the app**
```bash
flutter run
```

### Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release
```

## 📊 Database Schema

The database includes:
- **users** - User profiles with role-based access
- **businesses** - Business listings with location data
- **arcades** - Virtual marketplace containers
- **shops** - Independent shops within arcades
- **products** - Product listings
- **chats** / **messages** - Realtime messaging
- **reviews** - Customer feedback
- **recommendations** - AI recommendation tracking

Full schema with RLS policies: See `database/schema.sql`

## 🔒 Security Features

1. **Row Level Security (RLS)**
   - All database tables protected
   - User can only access their own data
   - Public data properly filtered

2. **Authentication**
   - Supabase Auth with email/password
   - Secure session management
   - Auto token refresh

3. **Input Validation**
   - Client-side validation
   - Server-side validation via RLS
   - SQL injection prevention

## 🌍 Scaling Strategy

### Phase 1: MVP (0-1K users)
- **Cost**: $0/month
- **Infrastructure**: Supabase Free Tier
- **Features**: Core functionality

### Phase 2: Growth (1K-50K users)
- **Cost**: ~$25/month
- **Infrastructure**: Supabase Pro
- **New Features**:
  - Push notifications
  - Advanced search
  - Payment integration (Mobile Money)

### Phase 3: Scale (50K-500K users)
- **Cost**: ~$100-300/month
- **Infrastructure**: Supabase Team + CDN
- **New Features**:
  - ML-powered recommendations
  - Multi-language support
  - Advanced analytics

### Phase 4: Global (500K+ users)
- **Infrastructure**: Dedicated servers, microservices
- **Features**: Full AI suite, white-label solutions

## 🤖 AI Recommendation System

### Current (MVP)
Heuristic-based recommendations using:
- Distance from user
- Category popularity
- Business ratings
- Recent activity

### Future (ML-Powered)
- User behavior analysis
- Collaborative filtering
- Deep learning models
- Real-time personalization

Architecture is designed for easy swap between implementations via the `RecommendationService` interface.

## 📱 Supported Platforms

- ✅ Android 5.0+ (API 21+)
- 🔄 iOS (coming soon)
- 🔄 Web (coming soon)

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Integration tests
flutter test integration_test/
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

## 📞 Support

For support, email support@ifind.ug or join our community Discord.

## 🎉 Acknowledgments

- Built with [Flutter](https://flutter.dev)
- Powered by [Supabase](https://supabase.com)
- Maps by [OpenStreetMap](https://www.openstreetmap.org)
- Icons from [Material Design](https://material.io/icons)

---

**Built with ❤️ in Uganda 🇺🇬**

*From MVP to Global Platform - Zero cost to Multi-billion dollar potential*
