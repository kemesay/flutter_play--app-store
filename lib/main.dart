import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/date_utils.dart';
import 'core/config/square_runtime_config.dart';
import 'core/config/side_detour_settings_provider.dart';
import 'core/referral/pending_referral_store.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/social_media_provider.dart';
import 'providers/support_provider.dart';
import 'ui/screens/auth/auth_screen.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/screens/driver/driver_home_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent huge error dumps from blowing up layout (cascade overflow).
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    const maxLen = 400;
    final short =
        message.length <= maxLen ? message : '${message.substring(0, maxLen)}…';
    return Material(
      color: Colors.red.shade900,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            short,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.yellow, fontSize: 13),
          ),
        ),
      ),
    );
  };

  // Initialize timezone data for Pacific timezone formatting
  initializeTimezones();

  // Fire-and-forget: nothing needs a pending referral code before the user
  // reaches a booking form, so this never delays app startup.
  unawaited(PendingReferralStore.captureOnFirstLaunch());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = buildAppTheme();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SquareRuntimeConfig()..load()),
        ChangeNotifierProvider(create: (_) => SideDetourSettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(
            create: (_) => SocialMediaProvider()..loadSocialMedias()),
        ChangeNotifierProvider(create: (_) => SupportProvider()),
      ],
      child: MaterialApp(
        title: 'ODA Black Car Service',
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
          final role = authProvider.currentUser?.role;
          if (role == 'driver') {
            return const DriverHomeScreen();
          }
          return const HomeScreen();
        }
        return const AuthScreen();
      },
    );
  }
}
