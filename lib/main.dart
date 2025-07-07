import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/sleep_diary/screens/sleep_diary_entry_screen.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/auth/screens/auth_screen.dart' show LandingScreen;
import 'firebase_options.dart';
import 'core/services/system_service.dart';
import 'core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =============================================
//  Initialization Flow for Firebase (Web & App)
// 1. Ensure Flutter bindings are initialized.
// 2. Call Firebase.initializeApp() with options.
// 3. Only run app logic after Firebase is ready.
// 4. All Firebase services must be used after init.
// =============================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('[main] Ensured Flutter bindings initialized');

  // Initialize date formatting for all locales
  await initializeDateFormatting();
  print('[main] Initialized date formatting');

  try {
    print('[main] Calling Firebase.initializeApp...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('[main] Firebase.initializeApp completed successfully');
  } catch (e, stack) {
    // If Firebase throws (e.g. already initialized on hot restart), print it and keep going.
    print('[main] Firebase initialization skipped: $e');
    print('[main] Stack trace: $stack');
  }

  print('[main] Running MyApp...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'dCBT-i',
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
      ),
      home: AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;
  String? _error;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    print('[AppInitializer] initState called');
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('[AppInitializer] Starting initialization');

      // No longer auto sign-in anonymously. Wait for user action on landing page.

      // Initialize system configuration and sample content
      final systemService = SystemService();
      await systemService.initializeSystemConfig();
      print('[AppInitializer] System config initialized');
      await systemService.initializeSampleEducationalContent();
      print('[AppInitializer] Sample educational content initialized');
      print('[AppInitializer] System services initialized');

      if (mounted) {
        setState(() {
          _initialized = true;
        });
        print(
            '[AppInitializer] Initialization complete, setState(_initialized = true)');
      }
    } catch (e, stack) {
      print('[AppInitializer] Error during initialization: $e');
      print('[AppInitializer] Stack trace: $stack');
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Error'),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    color: CupertinoColors.systemRed,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to initialize app',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CupertinoColors.systemGrey),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: _initializeApp,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return const CupertinoPageScaffold(
        child: Center(
          child: CupertinoActivityIndicator(radius: 16),
        ),
      );
    }

    // Listen to auth state changes and rebuild when auth state changes
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CupertinoPageScaffold(
            child: Center(
              child: CupertinoActivityIndicator(radius: 16),
            ),
          );
        }

        // If we have a user (anonymous or otherwise), show the main app
        if (snapshot.hasData) {
          return const HomePage();
        }

        // If we don't have a user, show the landing screen
        return const LandingScreen();
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();

  Future<void> _signInAsNewUser() async {
    await _authService.signOut(); // Sign out current user
    await _authService.signInAnonymously(); // Sign in as new anonymous user
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'dCBT-i',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _authService.signOut,
          child: const Text('登出'),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Text(
              '歡迎使用 dCBT-i',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '數位認知行為治療失眠',
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 17,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 16),
            // Display current User info
            if (currentUser != null) ...[
              Text(
                currentUser.isAnonymous
                    ? '訪客用戶'
                    : currentUser.email ?? currentUser.displayName ?? '',
                style: const TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 15,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'User ID: ${currentUser.uid}',
                style: const TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 13,
                  color: CupertinoColors.systemGrey2,
                ),
              ),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildFeatureButton(
                    context,
                    icon: CupertinoIcons.moon_stars,
                    label: '睡眠日記',
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const SleepDiaryEntryScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureButton(
                    context,
                    icon: CupertinoIcons.chart_bar,
                    label: '睡眠分析',
                    onPressed: () {
                      // TODO: Implement sleep analysis navigation
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureButton(
                    context,
                    icon: CupertinoIcons.book,
                    label: '教育內容',
                    onPressed: () {
                      // TODO: Implement education content navigation
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.systemGrey5,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Material(
              type: MaterialType.transparency,
              child: Icon(
                icon,
                color: CupertinoTheme.of(context).primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label,
              ),
            ),
            const Spacer(),
            const Material(
              type: MaterialType.transparency,
              child: Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
