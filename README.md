# 🚀 Ideaxy

**AI-Powered Social Media Content Generator & Calendar Management**

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-blue.svg)](https://flutter.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Supabase](https://img.shields.io/badge/Supabase-2.9.1+-green.svg)](https://supabase.com/)
[![Gemini AI](https://img.shields.io/badge/Gemini%20AI-0.4.6+-purple.svg)](https://ai.google.dev/)

## 📱 About

Ideaxy is a Flutter-based mobile application that revolutionizes social media content creation by leveraging AI to generate professional, platform-optimized content. Built with modern Flutter architecture and powered by Google's Gemini AI, it helps content creators, marketers, and social media managers streamline their content workflow.

## ✨ Features

### 🎯 **AI Content Generation**
- **Multi-Platform Support**: LinkedIn, X (Twitter), Instagram, TikTok, YouTube, Facebook
- **Niche-Specific Content**: Tailored content for 12+ niches including Tech, Fitness, Fashion, Business, and more
- **Smart Scheduling**: AI-optimized posting times for each platform
- **Complete Content**: Ready-to-publish posts with titles, descriptions, scripts, and hashtags

### 📅 **Content Management**
- **Calendar Integration**: Google Calendar sync for content scheduling
- **Content Planning**: 1-day, 4-day, and 7-day content plans
- **Profile Management**: Customizable niches and platform preferences
- **Content Library**: Save and organize generated content

### 🔐 **Authentication & Security**
- **Supabase Backend**: Secure user authentication and data storage
- **Google OAuth**: Seamless sign-in with Google accounts
- **Profile Customization**: User-specific content preferences and settings

### 🎨 **Modern UI/UX**
- **Dark Theme**: Elegant dark interface with gradient accents
- **Responsive Design**: Optimized for mobile devices
- **Smooth Animations**: Flutter animations for enhanced user experience
- **Native Splash**: Custom splash screen with Ideaxy branding

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.8.1+
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **AI**: Google Gemini AI (gemini-1.5-flash)
- **Authentication**: Supabase Auth + Google OAuth
- **State Management**: Flutter built-in state management
- **Routing**: GoRouter for navigation
- **Environment**: flutter_dotenv for configuration

## 🚀 Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) 3.8.1 or higher
- [Dart](https://dart.dev/get-dart) 3.0.0 or higher
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- [Git](https://git-scm.com/)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Nannoy/Ideaxy.git
   cd Ideaxy
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Setup** (see section below)

4. **Run the app**
   ```bash
   flutter run
   ```

## 🔐 Environment Configuration

### Required Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key

# Google Gemini AI
GEMINI_API_KEY=your_gemini_api_key
```

### Alternative: Build-time Configuration

You can also set these variables during build time using `--dart-define`:

```bash
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key --dart-define=GEMINI_API_KEY=your_key
```

### Setting Up Supabase

1. **Create a Supabase Project**
   - Go to [supabase.com](https://supabase.com)
   - Create a new project
   - Note your project URL and anon key

2. **Database Schema**
   The app expects the following table structure:
   ```sql
   -- Users table (handled by Supabase Auth)
   -- Profiles table for user preferences
   CREATE TABLE profiles (
     id UUID REFERENCES auth.users(id) PRIMARY KEY,
     niches TEXT[],
     platforms TEXT[],
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

### Setting Up Google Gemini AI

1. **Get API Key**
   - Visit [Google AI Studio](https://aistudio.google.com/)
   - Create a new API key
   - Add it to your `.env` file

2. **Enable Gemini API**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Enable the Gemini API for your project

### Google Calendar Integration

1. **Google Cloud Project Setup**
   - Create a project in [Google Cloud Console](https://console.cloud.google.com/)
   - Enable Google Calendar API
   - Create OAuth 2.0 credentials

2. **OAuth Configuration**
   - Add your OAuth client ID to the app
   - Configure redirect URIs for your app

## 📱 App Structure

```
lib/
├── main.dart                 # App entry point
├── router.dart              # Navigation configuration
├── theme.dart               # App theming
├── models/                  # Data models
│   └── content_models.dart
├── screens/                 # UI screens
│   ├── auth/               # Authentication screens
│   ├── onboarding/         # User onboarding
│   ├── generator_screen.dart
│   ├── calendar_screen.dart
│   └── profile_setup_screen.dart
├── services/                # Business logic
│   ├── gemini_service.dart
│   ├── supabase_auth_service.dart
│   ├── profile_service.dart
│   └── google_calendar_service.dart
└── widgets/                 # Reusable components
    └── full_screen_loader.dart
```

## 🔧 Configuration

### Platform-Specific Setup

#### Android
- Minimum SDK: 21
- Custom launcher icons configured
- Native splash screen implementation

#### iOS
- Custom launch images
- Native splash screen
- Adaptive icons support

### Build Configuration

The app includes pre-configured:
- Flutter launcher icons
- Native splash screen
- Platform-specific assets

## 📊 Content Generation

### Supported Niches
- 💻 Tech
- 🏋️ Fitness
- 👗 Fashion
- 🎬 Entertainment
- 📚 Education
- 🍳 Food
- ✈️ Travel
- 💼 Business
- 🎨 Design
- 📈 Marketing
- 🧠 Self-Improvement
- 🧪 Science

### Platform Optimization
Each platform receives content optimized for:
- **LinkedIn**: Professional, long-form content
- **X (Twitter)**: Short, viral, hook-based posts
- **Instagram**: Visual-first with emotional hooks
- **TikTok**: Script-led viral content
- **YouTube**: Video-focused content planning
- **Facebook**: Community-engaged posts

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter best practices
- Maintain consistent code style
- Add tests for new features
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev/) for the amazing framework
- [Supabase](https://supabase.com/) for the backend infrastructure
- [Google Gemini AI](https://ai.google.dev/) for AI-powered content generation
- [Flutter Community](https://flutter.dev/community) for packages and support

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Nannoy/Ideaxy/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Nannoy/Ideaxy/discussions)
- **Email**: [Your Email]

## 🔮 Roadmap

- [ ] Multi-language support
- [ ] Advanced analytics dashboard
- [ ] Team collaboration features
- [ ] Content performance tracking
- [ ] AI-powered hashtag optimization
- [ ] Bulk content scheduling
- [ ] Integration with more social platforms

---

**Made with ❤️ by [Nannoy](https://github.com/Nannoy)**

*Transform your social media presence with AI-powered content generation.*
