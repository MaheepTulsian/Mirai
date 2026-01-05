import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'services/firebase_service.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/main_navigation.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'utils/theme.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Background message received: ${message.messageId}");
  debugPrint("  Title: ${message.notification?.title}");
  debugPrint("  Body: ${message.notification?.body}");
  debugPrint("  Data: ${message.data}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (uses google-services.json configuration)
  await Firebase.initializeApp();

  // Enable Firestore offline persistence and caching
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize FCM background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MiraiApp());
}

class MiraiApp extends StatefulWidget {
  const MiraiApp({super.key});

  @override
  State<MiraiApp> createState() => _MiraiAppState();
}

class _MiraiAppState extends State<MiraiApp> {
  final NotificationService _notificationService = NotificationService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Initialize Notification Service after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.initialize(_navigatorKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
        ),
        Provider<AnalyticsService>(
          create: (_) => AnalyticsService(),
        ),
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<NotificationService>(
          create: (_) => _notificationService,
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Mirai',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is not logged in
        if (snapshot.data == null) {
          return const LoginScreen();
        }

        // User is logged in, check if profile exists
        return FutureBuilder<bool>(
          future: authService.hasProfile(snapshot.data!.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Profile doesn't exist, show onboarding
            if (profileSnapshot.data == false) {
              return const OnboardingScreen();
            }

            // Profile exists, show main navigation
            return const MainNavigation();
          },
        );
      },
    );
  }
}
