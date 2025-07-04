import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/sleep_diary/screens/sleep_diary_entry_screen.dart';
import 'firebase_options.dart';

void main() async {
  try {
    print('[main] Starting app initialization');
    WidgetsFlutterBinding.ensureInitialized();
    print('[main] Flutter binding initialized');

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('[main] Firebase initialized successfully');
    } catch (e) {
      print('[main] Firebase initialization failed: $e');
      // Continue without Firebase for now
    }

    try {
      await initializeDateFormatting('zh_TW', null);
      print('[main] Date formatting initialized');
    } catch (e) {
      print('[main] Date formatting initialization failed: $e');
      // Continue without localization for now
    }

    print('[main] Running app');
    runApp(const MyApp());
  } catch (e) {
    print('[main] Fatal error during initialization: $e');
    // Show some UI even if initialization fails
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // [MyApp.build] Building app with proper Material and Cupertino support
    return MaterialApp(
      title: 'Digital CBT-i',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // This ensures Material icons are available
        iconTheme: const IconThemeData(
          color: CupertinoColors.systemBlue,
        ),
      ),
      home: CupertinoApp(
        theme: const CupertinoThemeData(
          primaryColor: CupertinoColors.systemBlue,
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(
              fontFamily: 'SF Pro Text',
            ),
          ),
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // [HomePage.build] Home page with navigation to features
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'dCBT-i',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w600,
          ),
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
            Material(
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
