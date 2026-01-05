# Mirai - CS Career & Learning Hub

<div align="center">
  <img src="assets/images/logo.png" alt="Mirai Logo" width="200">

  **A comprehensive Flutter app designed for Computer Science students and IT professionals**

  *Your single hub for jobs, internships, courses, roadmaps, and career opportunities*

  [![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue.svg)](https://flutter.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)](https://flutter.dev/multi-platform)
</div>

## 🌟 Overview

Mirai is a modern, feature-rich mobile application built with Flutter and Firebase that serves as a comprehensive platform for CS/IT students and professionals. The app provides a centralized location for discovering job opportunities, internships, educational resources, career roadmaps, and GSoC organizations.

### 🎯 Core Mission
- **Simplify** the job and internship search process for CS students
- **Centralize** learning resources and career guidance in one platform
- **Connect** students with opportunities that match their skills and interests
- **Accelerate** career growth through curated content and personalized recommendations

## ✨ Key Features

### 📱 **Modern User Experience**
- **Dark Theme Design** with premium UI/UX (AppTheme: #1C1C1E, #2C2C2E)
- **Bottom Navigation** with 5 main sections + **Sidebar Drawer**
- **Clean Architecture** without traditional AppBar for modern look
- **Responsive Design** optimized for mobile devices

### 🔐 **Authentication & Onboarding**
- **Google Sign-In** integration with Firebase Auth
- **Smart Onboarding** flow with location-based college selection
- **Profile Management** with graduating year, state, city, and college info
- **Automatic User Creation** with FCM token registration

### 💼 **Job & Internship Platform**
- **Real-time Listings** from Firestore with live updates
- **Advanced Filtering** by location, company, tags, and requirements
- **Smart Recommendations** based on user profile and preferences
- **Save & Share** functionality for opportunities
- **Apply Integration** with direct links to company application pages

### 🎓 **Learning Resources**
- **Course Catalog** with online learning opportunities
- **Career Roadmaps** for different tech specializations
- **GSoC Integration** with organization listings and opportunities
- **Guide Section** with development tutorials and best practices

### 🔔 **Push Notifications & Deep Linking**
- **FCM Integration** with foreground, background, and terminated state handling
- **Deep Linking** to 12+ different screens with parameter passing
- **Smart Routing** with fallback handling for graceful navigation
- **Local Notifications** for enhanced user engagement

### 📊 **Analytics & Performance**
- **Firebase Analytics** with comprehensive event tracking
- **Performance Optimizations** including image caching and smart loading
- **Offline Support** with Firestore persistence and unlimited cache
- **Error Handling** with user-friendly feedback

## 🏗️ Technical Architecture

### **Tech Stack**
```yaml
Frontend: Flutter 3.0+ (Dart)
Backend: Firebase (Firestore, Auth, Analytics, FCM)
State Management: Provider Pattern
Navigation: Flutter Navigation 2.0
Caching: CachedNetworkImage with optimized parameters
Notifications: firebase_messaging + flutter_local_notifications
```

### **Project Structure**
```
lib/
├── main.dart                    # App entry point with Firebase initialization
├── screens/                    # All app screens (widget-only, no Scaffold)
│   ├── main_navigation.dart     # Bottom nav + drawer container
│   ├── home_screen.dart         # Dashboard with carousels
│   ├── jobs_screen.dart         # Job listings with filters
│   ├── internships_screen.dart  # Optimized internship platform
│   ├── learning_resources_screen.dart # Courses and educational content
│   ├── gsoc_screen.dart         # GSoC organizations and info
│   ├── login_screen.dart        # Google Sign-In interface
│   ├── onboarding_screen.dart   # Profile setup flow
│   └── profile_screen.dart      # User profile management
├── widgets/                     # Reusable UI components
│   ├── internship_card.dart     # Optimized job/internship cards
│   ├── filter_chips.dart        # Advanced filtering component
│   ├── horizontal_carousel.dart  # Home screen carousels
│   └── dashboard_card.dart      # Home dashboard cards
├── services/                    # Business logic layer
│   ├── auth_service.dart        # Google Sign-In & user management
│   ├── firebase_service.dart    # Firestore operations
│   ├── notification_service.dart # FCM implementation
│   ├── notification_navigator.dart # Deep linking logic
│   └── analytics_service.dart   # Event tracking
├── models/                      # Data models
│   ├── job.dart                 # Unified job/internship model
│   ├── notification_data.dart   # FCM payload structure
│   ├── saved_item.dart          # User saves model
│   └── profile.dart             # User profile model
└── utils/                       # Utilities and helpers
    ├── theme.dart               # App-wide theme definitions
    ├── constants.dart           # Configuration constants
    └── url_launcher_helper.dart # External link handling
```

### **Navigation System**
The app uses a sophisticated navigation architecture:
- **MainNavigation**: Container with bottom navigation and sidebar drawer
- **AuthWrapper**: Handles authentication state and routing
- **Deep Linking**: FCM-powered navigation to specific screens with parameters
- **Tab Switching**: Programmatic navigation between main sections

## 🚀 Getting Started

### **Prerequisites**
- Flutter 3.0+ installed
- Android Studio / VS Code with Flutter extensions
- Firebase project setup
- Android device/emulator for testing

### **Quick Setup (5 minutes)**

1. **Clone the repository**
```bash
git clone <repository-url>
cd mirai
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Firebase Configuration** (REQUIRED)

**Add SHA-1 Certificate:**
1. Open [Firebase Console](https://console.firebase.google.com) → Your Project → Settings
2. Under "Your apps", click your Android app
3. Add SHA-1 fingerprint: `6E:84:95:A3:F0:F9:DB:76:CD:EF:E0:85:86:F6:D0:33:1E:CD:38:19`
4. Download updated `google-services.json` → Place in `android/app/`

**Enable Google Sign-In:**
- Firebase Console → Authentication → Sign-in method → Enable "Google"

4. **Deploy Firestore Security Rules** (CRITICAL)
```javascript
// Copy this to Firebase Console → Firestore → Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /saved_items/{itemId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    match /colleges/{collegeId} {
      allow read: if request.auth != null;
    }
    match /{collection}/{document=**} {
      allow read: if request.auth != null;
    }
  }
}
```

5. **Add Sample Data to Firestore**
Create these collections with sample documents:
- `jobs` - Job listings
- `internships` - Internship opportunities
- `courses` - Online courses
- `roadmaps` - Learning paths
- `colleges` - College database
- `guide` - Development guides

6. **Create Required Firestore Index**
- **Collection:** `colleges`
- **Fields:** `state` ↑, `name` ↑
(Click error link in app to auto-create)

7. **Run the app**
```bash
flutter run
```

## 📊 Data Schema

### **User Profile** (`users/{uid}`)
```json
{
  "email": "user@example.com",
  "displayName": "User Name",
  "photoURL": "https://...",
  "fcmToken": "device_fcm_token",
  "createdAt": 1735467890123,
  "lastLoginAt": 1735467890123,
  "hasCompletedOnboarding": true,
  "profile": {
    "graduatingYear": "2026",
    "state": "Punjab",
    "city": "Amritsar",
    "collegeName": "College Name",
    "collegeId": "COLLEGE_ID"
  }
}
```

### **Internship/Job** (`internships/{id}` or `jobs/{id}`)
```json
{
  "title": "Software Engineer, Intern",
  "company": "Stripe",
  "companyLogo": "https://stripe.com/logo.png",
  "description": "Join our engineering team...",
  "location": "Bengaluru",
  "locationType": "onsite",
  "applyLink": "https://stripe.com/jobs/listing/...",
  "tags": ["software engineering", "internship"],
  "skills": ["Java", "JavaScript", "Go"],
  "requirements": ["Strong CS fundamentals"],
  "deadline": 1768247752276,
  "startDate": null,
  "stipend": null,
  "isActive": true
}
```

## 🔔 Push Notifications & Deep Linking

The app includes a comprehensive FCM implementation supporting:

### **Notification States**
- ✅ **Foreground** (app open) - Local notifications
- ✅ **Background** (app minimized) - System notifications
- ✅ **Terminated** (app closed) - System notifications with launch

### **Deep Link Targets**
| Screen | Description | Parameters |
|--------|-------------|------------|
| `home` | Dashboard overview | None |
| `jobs` | Job listings | None |
| `job_details` | Specific job | `jobId` |
| `internships` | Internship listings | None |
| `internship_details` | Specific internship | `internshipId` |
| `gsoc` | GSoC section | None |
| `profile` | User profile | None |
| `webview` | External URL | `url` |

### **FCM Message Format**
```json
{
  "notification": {
    "title": "New Job Alert!",
    "body": "Google is hiring Software Engineers",
    "image": "https://example.com/logo.png"
  },
  "data": {
    "screen": "job_details",
    "jobId": "google_swe_2024",
    "notificationId": "notif_12345"
  }
}
```

## 🎨 UI/UX Design

### **Design System**
- **Primary Color:** Custom blue accent (#4A90E2)
- **Background:** Dark theme (#1C1C1E)
- **Surface:** Secondary dark (#2C2C2E)
- **Text:** White primary, gray secondary
- **Cards:** Elevated design with subtle shadows

### **Navigation Pattern**
- **Bottom Navigation:** 5 main sections (Home, Jobs, Internships, Learning, GSoC)
- **Sidebar Drawer:** Profile, saved items, settings, support
- **No AppBar:** Clean, modern header-less design
- **Centered Logo:** Mirai branding in top navigation

### **Performance Optimizations**
- **ListView Caching:** 500px cache extent for smooth scrolling
- **Image Optimization:** CachedNetworkImage with size limits
- **Smart Loading:** Shimmer effects and loading states
- **Error Handling:** Retry buttons and user-friendly messages

## 🧪 Testing & Development

### **FCM Testing**
The app includes `FCMTestScreen` for development testing:
```dart
// Add to your settings screen
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const FCMTestScreen()
));
```

### **Analytics Events**
Key tracked events:
- `app_open` - App launch
- `homepage_view` - Dashboard visits
- `job_applied` - Job application clicks
- `internship_saved` - Save interactions
- `filter_used` - Filter usage patterns

### **Common Commands**
```bash
# Clean build
flutter clean && flutter pub get

# Build release APK
flutter build apk --release

# Check for updates
flutter doctor

# Generate SHA-1
cd android && ./gradlew signingReport
```

## 🛠️ Configuration

### **Key Dependencies**
```yaml
dependencies:
  firebase_core: ^4.3.0
  cloud_firestore: ^6.1.1
  firebase_auth: ^6.1.3
  firebase_messaging: ^16.1.0
  google_sign_in: ^6.2.1  # v6.x for stability
  provider: ^6.1.1
  cached_network_image: ^3.3.1
  flutter_local_notifications: ^19.5.0
```

### **Firebase Settings**
- **Region:** asia-south2
- **Persistence:** Enabled with unlimited cache
- **Analytics:** Comprehensive event tracking
- **Security Rules:** User-scoped with authentication required

## 🚧 Troubleshooting

### **Common Issues & Solutions**

| Issue | Cause | Solution |
|-------|--------|----------|
| "No content available" | Empty Firestore collections | Add sample data to collections |
| "Permission denied" | Security rules not deployed | Deploy Firestore rules from setup |
| Login fails | SHA-1 not configured | Add SHA-1 to Firebase project |
| Index error | Missing Firestore index | Click error link to auto-create |
| Notifications not working | FCM not configured | Verify google-services.json placement |

### **Verification Checklist**
- ✓ Firebase project configured with SHA-1
- ✓ google-services.json in android/app/
- ✓ Firestore security rules deployed
- ✓ Sample data added to all collections
- ✓ Required indexes created
- ✓ FCM token generated and saved

## 🤝 Contributing

### **Development Guidelines**
1. Follow existing code patterns and naming conventions
2. Use Provider for state management
3. Implement proper error handling with user feedback
4. Add analytics tracking for new features
5. Test on both Android and iOS devices
6. Update documentation for new features

### **Pull Request Process**
1. Fork the repository
2. Create a feature branch
3. Implement changes with proper testing
4. Update documentation if needed
5. Submit PR with detailed description

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team** for the excellent cross-platform framework
- **Firebase Team** for comprehensive backend services
- **Open Source Community** for valuable packages and resources
- **CS Students** who inspired this project's creation

## 📞 Support & Contact

- **Documentation:** See CLAUDE.md for detailed setup instructions
- **Issues:** Open a GitHub issue for bug reports
- **Feature Requests:** Use GitHub discussions
- **Email:** support@mirai.app (coming soon)

---

<div align="center">

  **Built with ❤️ for CS students and professionals**

  *Accelerating careers through technology*

  [🌟 Star this repo](/) | [🐛 Report Bug](/) | [💡 Request Feature](/)

</div>