import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/utils/date_utils.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/social_media_provider.dart';
import 'providers/support_provider.dart';
import 'ui/screens/auth/auth_screen.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'utils/custom_route.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize timezone data for Pacific timezone formatting
  initializeTimezones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Company brand color: #03930a
    const brandColor = Color(0xFF03930A);
    const brandLight = Color(0xFF4CB051);
    const brandDark = Color(0xFF2C8A90);

    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandColor,
        brightness: Brightness.light,
        primary: brandColor,
        onPrimary: Colors.white,
        primaryContainer: brandLight,
        onPrimaryContainer: brandDark,
        secondary: brandColor,
        onSecondary: Colors.white,
        tertiary: brandLight,
      ),
      useMaterial3: true,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CustomPageTransitionBuilder(),
          TargetPlatform.android: CustomPageTransitionBuilder(),
        },
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(
            create: (_) => SocialMediaProvider()..loadSocialMedias()),
        ChangeNotifierProvider(create: (_) => SupportProvider()),
      ],
      child: MaterialApp(
        title: 'ODA Transportation',
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const _AppEntryPoint(),
      ),
    );
  }
}

class _AppEntryPoint extends StatelessWidget {
  const _AppEntryPoint();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.initialized) {
          return const SplashScreen();
        }
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }
        return const AuthScreen();
      },
    );
  }
}
