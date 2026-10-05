import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/studio_workboard_screen.dart';
import 'screens/hours_report_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudioTrackApp());
}

class StudioTrackApp extends StatefulWidget {
  const StudioTrackApp({super.key});

  @override
  State<StudioTrackApp> createState() => _StudioTrackAppState();
}

class _StudioTrackAppState extends State<StudioTrackApp> {
  int _currentTabIndex = 0; // 0: Workboard, 1: Hours Report

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudioTrack',
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
        body: _currentTabIndex == 0
            ? StudioWorkboardScreen(
                onNavigateToHoursReport: () {
                  setState(() => _currentTabIndex = 1);
                },
              )
            : HoursReportScreen(
                onNavigateToWorkboard: () {
                  setState(() => _currentTabIndex = 0);
                },
              ),
      ),
    );
  }
}
