# 🔐 Environment Setup Guide

This guide will walk you through setting up all the required services and environment variables for Ideaxy.

## 📋 Prerequisites

Before you begin, ensure you have:
- A Google account
- A GitHub account
- Basic understanding of API keys and environment variables

## 🚀 Step-by-Step Setup

### 1. Supabase Setup

#### Create Supabase Project
1. Go to [supabase.com](https://supabase.com) and sign in
2. Click "New Project"
3. Choose your organization
4. Enter project details:
   - **Name**: `ideaxy` (or your preferred name)
   - **Database Password**: Generate a strong password
   - **Region**: Choose closest to your users
5. Click "Create new project"
6. Wait for the project to be ready (usually 2-3 minutes)

#### Get Project Credentials
1. In your project dashboard, go to **Settings** → **API**
2. Copy the following values:
   - **Project URL**: `https://your-project-id.supabase.co`
   - **Anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

#### Database Schema Setup
1. Go to **SQL Editor** in your Supabase dashboard
2. Run the following SQL to create the required tables:

```sql
-- Create profiles table for user preferences
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  niches TEXT[] DEFAULT '{}',
  platforms TEXT[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to read their own profile
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

-- Create policy to allow users to insert their own profile
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Create policy to allow users to update their own profile
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Create function to handle user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id)
  VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create profile on user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### 2. Google Gemini AI Setup

#### Get API Key
1. Visit [Google AI Studio](https://aistudio.google.com/)
2. Sign in with your Google account
3. Click "Get API key" in the top right
4. Choose "Create API key in new project" or select existing project
5. Copy the generated API key

#### Enable Gemini API (Alternative Method)
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the **Generative Language API**
4. Go to **APIs & Services** → **Credentials**
5. Create an API key

### 3. Google Calendar Integration Setup

#### Create Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the **Google Calendar API**
4. Go to **APIs & Services** → **OAuth consent screen**
5. Configure OAuth consent screen:
   - **User Type**: External
   - **App name**: `Ideaxy`
   - **User support email**: Your email
   - **Developer contact information**: Your email
   - **Scopes**: Add `https://www.googleapis.com/auth/calendar`

#### Create OAuth Credentials
1. Go to **APIs & Services** → **Credentials**
2. Click "Create Credentials" → "OAuth 2.0 Client IDs"
3. Choose **Android** as application type
4. Enter package name: `com.nannoy.ideaxy`
5. Generate SHA-1 fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
6. Copy the SHA-1 value and add it to the OAuth client
7. Download the `google-services.json` file

### 4. Environment Configuration

#### Create .env File
Create a `.env` file in your project root:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Google Gemini AI
GEMINI_API_KEY=your_gemini_api_key_here

# Google Calendar (if using OAuth)
GOOGLE_CLIENT_ID=your_oauth_client_id_here
```

#### Android Configuration
1. Place `google-services.json` in `android/app/`
2. Update `android/app/build.gradle.kts`:
   ```kotlin
   plugins {
       id("com.google.gms.google-services")
   }
   ```
3. Update `android/build.gradle.kts`:
   ```kotlin
   dependencies {
       classpath("com.google.gms:google-services:4.4.0")
   }
   ```

#### iOS Configuration
1. Add OAuth URL scheme to `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLName</key>
           <string>com.nannoy.ideaxy</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.nannoy.ideaxy</string>
           </array>
       </dict>
   </array>
   ```

### 5. Build Configuration

#### Using .env File (Recommended for Development)
```bash
flutter run
```

#### Using Build-time Variables (Recommended for Production)
```bash
flutter run --dart-define=SUPABASE_URL=your_url \
           --dart-define=SUPABASE_ANON_KEY=your_key \
           --dart-define=GEMINI_API_KEY=your_key
```

#### For Production Builds
```bash
flutter build apk --dart-define=SUPABASE_URL=your_url \
                 --dart-define=SUPABASE_ANON_KEY=your_key \
                 --dart-define=GEMINI_API_KEY=your_key
```

## 🔒 Security Best Practices

### Environment Variables
- **Never commit** `.env` files to version control
- Use different API keys for development and production
- Rotate API keys regularly
- Use environment-specific configurations

### API Key Management
- Store production keys securely (e.g., CI/CD secrets)
- Use least-privilege access for API keys
- Monitor API usage and set rate limits
- Implement proper error handling for missing keys

### Supabase Security
- Enable Row Level Security (RLS) on all tables
- Use parameterized queries
- Implement proper authentication checks
- Regular security audits

## 🧪 Testing Your Setup

### Verify Supabase Connection
1. Run the app
2. Try to sign up/sign in
3. Check Supabase dashboard for new users
4. Verify profile creation

### Verify Gemini AI
1. Go to content generation screen
2. Select a niche and platforms
3. Generate content
4. Check for AI-generated responses

### Verify Google Calendar
1. Sign in with Google account
2. Grant calendar permissions
3. Check calendar integration
4. Verify event creation

## 🚨 Troubleshooting

### Common Issues

#### Supabase Connection Failed
- Check project URL and anon key
- Verify project is active
- Check network connectivity
- Review Supabase logs

#### Gemini API Errors
- Verify API key is correct
- Check API quota and billing
- Ensure Gemini API is enabled
- Review API response errors

#### Google Calendar Issues
- Verify OAuth configuration
- Check package name matches
- Ensure proper scopes are added
- Review OAuth consent screen

#### Build Errors
- Check Flutter version compatibility
- Verify all dependencies are installed
- Clean and rebuild project
- Check platform-specific configurations

### Getting Help
- Check [Supabase Documentation](https://supabase.com/docs)
- Review [Google AI Documentation](https://ai.google.dev/docs)
- Consult [Flutter Documentation](https://flutter.dev/docs)
- Open issues on [GitHub](https://github.com/Nannoy/Ideaxy/issues)

## 📚 Additional Resources

- [Supabase Flutter Guide](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
- [Google AI Flutter Integration](https://ai.google.dev/docs/flutter_quickstart)
- [Flutter Environment Variables](https://flutter.dev/docs/deployment/environment-variables)
- [Google Calendar API Guide](https://developers.google.com/calendar/api/guides/overview)

---

**Need help?** Open an issue on GitHub or check the troubleshooting section above.
