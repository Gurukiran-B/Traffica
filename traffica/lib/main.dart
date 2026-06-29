import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/map_screen.dart';
import 'screens/navigation_screen.dart';
import 'screens/prediction_screen.dart';
import 'screens/fleet_screen.dart';
import 'screens/delivery_search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/upload_photo_screen.dart';
import 'screens/community_feed_screen.dart';
import 'theme/app_theme.dart';
import 'services/route_provider.dart';
import 'services/auth_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(TrafficaApp(initialRoute: '/splash'));
}

class TrafficaApp extends StatelessWidget {
  final String initialRoute;
  final FirebaseStorage storage;
  final FirebaseFirestore firestore;

  TrafficaApp({super.key, required this.initialRoute})
      : storage = FirebaseStorage.instance,
        firestore = FirebaseFirestore.instance;


  @override
  Widget build(BuildContext context) {
    // Example usage of Firestore:
    void exampleFirestoreUsage() async {
      try {
        // Reference to a Firestore collection
        CollectionReference users = firestore.collection('users');
        // Adding a document
        await users.add({'name': 'John Doe', 'email': 'johndoe@example.com'});
        print('User added to Firestore');
      } catch (e) {
        print('Failed to add user: $e');
      }
    }
    
    // Call exampleFirestoreUsage() once when widget builds to test connection
    exampleFirestoreUsage(); 
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RouteProvider()),
      ],
      child: AdaptiveTheme(
        light: AppTheme.light(),
        dark: AppTheme.light().copyWith(brightness: Brightness.dark),
        initial: AdaptiveThemeMode.light,
        builder: (theme, darkTheme) => MaterialApp(
          title: 'Traffica',
          debugShowCheckedModeBanner: false,
          theme: theme,
          darkTheme: darkTheme,
          initialRoute: initialRoute,
          routes: {
            '/splash': (context) => SplashScreen(),
            '/login': (context) => LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/dashboard': (context) => DashboardScreen(),
            '/map': (context) => MapScreen(),
            '/navigation': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
              final sourceCoords = args?['sourceCoords'] as LatLng?;
              final destCoords = args?['coords'] as LatLng?;
              
              return NavigationScreen(
                startLat: sourceCoords?.latitude,
                startLng: sourceCoords?.longitude,
                endLat: destCoords?.latitude,
                endLng: destCoords?.longitude,
                startLabel: args?['source'] as String?,
                endLabel: args?['destination'] as String?,
              );
            },
            '/prediction': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
              return PredictionScreen(
                source: args?['source'] ?? '',
                destination: args?['destination'] ?? '',
              );
            },
            '/fleet': (context) => FleetScreen(),
            '/delivery_search': (context) => DeliverySearchScreen(),
            '/profile': (context) => ProfileScreen(),
            '/notifications': (context) => NotificationsScreen(),
            '/upload_photo': (context) => const UploadPhotoScreen(),
            '/community_feed': (context) => const CommunityFeedScreen(),
          },
        ),
      ),
    );
  }
}
