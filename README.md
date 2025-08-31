# Habit Tracker App

A comprehensive Flutter application for tracking daily habits, monitoring progress, and staying motivated through inspirational quotes. Built with Firebase backend for data synchronization and offline support.

## 🚀 Features

### Core Functionality
- **User Authentication**: Secure registration and login with Firebase Auth
- **Habit Management**: Create, edit, and delete habits with categories
- **Progress Tracking**: Monitor completion rates and streaks
- **Motivational Quotes**: Daily inspirational quotes with favorites system
- **Theme Support**: Light and dark mode with system preference detection

### Habit Features
- **Categories**: Health, Study, Fitness, Productivity, Mental Health, and Others
- **Frequency**: Daily or weekly habit tracking
- **Streak Calculation**: Automatic streak counting with smart reset logic
- **Notes**: Add detailed descriptions and notes to habits
- **Start Dates**: Optional start dates for habit scheduling

### User Experience
- **Modern UI**: Material Design 3 with custom components
- **Responsive Design**: Works on all screen sizes
- **Pull-to-Refresh**: Refresh data with intuitive gestures
- **Search & Filter**: Find habits and quotes quickly
- **Offline Support**: Works without internet connection

## 🛠️ Technical Stack

- **Frontend**: Flutter 3.8+
- **Backend**: Firebase (Auth, Firestore)
- **State Management**: Provider pattern
- **Charts**: FL Chart for progress visualization
- **Local Storage**: Shared Preferences for offline data
- **HTTP**: For external quotes API integration

## 📱 Screenshots

The app includes the following main screens:
- **Splash Screen**: Animated welcome screen
- **Authentication**: Login and registration with validation
- **Home**: Dashboard with today's habits and quick stats
- **Habits**: Full habit management with filtering
- **Progress**: Analytics and progress charts
- **Quotes**: Motivational quotes with favorites
- **Profile**: User settings and profile management

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.8.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Firebase project

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/tusharsinha08/habittracker.git
   cd habittracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the respective platform directories

4. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Configuration

1. **Authentication**
   - Enable Email/Password sign-in method
   - Set up password reset emails

2. **Firestore Rules**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users can only access their own data
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
         
         // Habits subcollection
         match /habits/{habitId} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
         
         // Favorites subcollection
         match /favorites/quotes/{quoteId} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
         
         // Daily quotes subcollection
         match /daily_quotes/{date} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
       }
     }
   }
   ```

## 📁 Project Structure

```
lib/
├── models/           # Data models
│   ├── user_model.dart
│   ├── habit_model.dart
│   └── quote_model.dart
├── services/         # Firebase and API services
│   ├── auth_service.dart
│   ├── habit_service.dart
│   └── quote_service.dart
├── providers/        # State management
│   ├── auth_provider.dart
│   ├── habit_provider.dart
│   ├── quote_provider.dart
│   └── theme_provider.dart
├── screens/          # UI screens
│   ├── auth/
│   ├── home/
│   ├── habits/
│   ├── progress/
│   ├── quotes/
│   └── profile/
├── widgets/          # Reusable UI components
│   ├── custom_text_field.dart
│   ├── custom_button.dart
│   ├── habit_card.dart
│   ├── quote_card.dart
│   └── stats_card.dart
└── main.dart         # App entry point
```

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:
```env
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

### Dependencies
Key dependencies in `pubspec.yaml`:
- `firebase_core`: Firebase initialization
- `firebase_auth`: User authentication
- `cloud_firestore`: Database operations
- `provider`: State management
- `fl_chart`: Progress visualization
- `shared_preferences`: Local storage
- `http`: External API calls

## 📊 Data Models

### User Model
```dart
class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? gender;
  final DateTime? dateOfBirth;
  final double? height;
  final Map<String, dynamic>? otherDetails;
  final bool isDarkMode;
}
```

### Habit Model
```dart
class HabitModel {
  final String id;
  final String title;
  final HabitCategory category;
  final HabitFrequency frequency;
  final DateTime? startDate;
  final String? notes;
  final int currentStreak;
  final List<DateTime> completionHistory;
}
```

### Quote Model
```dart
class QuoteModel {
  final String id;
  final String text;
  final String author;
  final String? category;
  final bool isFavorite;
}
```

## 🎯 Usage

### Creating Habits
1. Navigate to the Habits tab
2. Tap the floating action button
3. Fill in habit details (title, category, frequency)
4. Set optional start date and notes
5. Save the habit

### Tracking Progress
- Mark habits as complete by tapping the completion toggle
- View progress charts in the Progress tab
- Monitor streaks and completion rates

### Managing Quotes
- View daily motivational quotes on the home screen
- Add quotes to favorites
- Copy quotes to clipboard
- Refresh for new quotes

### Profile Management
- Edit personal information
- Toggle between light and dark themes
- Change password
- View account statistics

## 🔒 Security Features

- **Authentication**: Secure user login with Firebase Auth
- **Data Isolation**: Users can only access their own data
- **Input Validation**: Comprehensive form validation
- **Error Handling**: Graceful error handling and user feedback

## 🚀 Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- FL Chart for progress visualization
- Material Design for UI inspiration

## 📞 Support

For support and questions:
- Create an issue in the GitHub repository
- Contact the development team
- Check the documentation

## 🔮 Future Enhancements

- **Social Features**: Share habits with friends
- **Advanced Analytics**: More detailed progress insights
- **Habit Templates**: Pre-built habit suggestions
- **Notifications**: Reminder system for habits
- **Data Export**: Export progress data
- **Multi-language Support**: Internationalization
- **Voice Commands**: Voice-based habit tracking

---

**Built with ❤️ using Flutter and Firebase**
