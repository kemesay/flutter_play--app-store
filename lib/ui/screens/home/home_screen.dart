import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/catalog_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../widgets/app_error_banner.dart';
import 'pages/book_ride/book_ride_page.dart';
import 'pages/my_account_page.dart';
import 'pages/trips_page.dart';
import 'pages/support_page.dart';
import 'widgets/creative_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    BookRidePage(),
    TripsPage(),
    SupportPage(),
    MyAccountPage(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<CatalogProvider>().initialize();
      context.read<BookingProvider>().refreshBookings();
      context.read<PaymentProvider>().loadCards();
    });
  }

  // Helper method to get time-aware greeting
  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else {
      return 'Good afternoon';
    }
  }

  // Helper method to extract first name from full name
  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return 'Guest';
    final names = fullName.split(' ');
    return names.isNotEmpty ? names[0] : fullName;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final errorBanner = context.watch<CatalogProvider>().errorMessage ??
        context.watch<BookingProvider>().errorMessage;
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_getTimeGreeting()}, ${_getFirstName(user?.fullName ?? 'Guest')}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color:
                Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      body: Column(
        children: [
          if (errorBanner != null)
            AppErrorBanner(
              message: errorBanner,
              onRetry: () {
                context.read<CatalogProvider>().refreshCatalog();
              },
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: CreativeBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
