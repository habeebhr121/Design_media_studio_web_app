import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/studio_workboard_screen.dart';
import 'screens/hours_report_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  runApp(const StudioTrackApp());
}

class StudioTrackApp extends StatefulWidget {
  const StudioTrackApp({super.key});

  @override
  State<StudioTrackApp> createState() => _StudioTrackAppState();
}

class _StudioTrackAppState extends State<StudioTrackApp> {
  int _currentTabIndex = 0; // 0: Workboard, 1: Hours Report, 2: Login

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Design Media Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF25206A),
          primary: const Color(0xFF25206A),
          surface: Colors.white,
        ),
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      home: Scaffold(
        body: _buildCurrentScreen(),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentTabIndex) {
      case 0:
        return StudioWorkboardScreen(
          onNavigateToHoursReport: () {
            setState(() => _currentTabIndex = 1);
          },
          onNavigateToLogin: () {
            setState(() => _currentTabIndex = 2);
          },
        );
      case 1:
        return HoursReportScreen(
          onNavigateToWorkboard: () {
            setState(() => _currentTabIndex = 0);
          },
          onNavigateToLogin: () {
            setState(() => _currentTabIndex = 2);
          },
        );
      case 2:
      default:
        return LoginScreen(
          onLoginSuccess: () {
            setState(() => _currentTabIndex = 0);
          },
          onNavigateToWorkboard: () {
            setState(() => _currentTabIndex = 0);
          },
        );
    }
  }
}

