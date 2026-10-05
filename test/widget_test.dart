import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_track/main.dart';

void main() {
  testWidgets('StudioTrackApp smoke test and navigation between screens', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // 1. Build app and verify Workboard is displayed
    await tester.pumpWidget(const StudioTrackApp());
    await tester.pumpAndSettle();

    expect(find.text('Studio Workboard'), findsOneWidget);
    expect(find.text('Team Capacity Matrix'), findsOneWidget);

    // 2. Tap on "Hours Report" in the navigation bar
    final hoursReportTab = find.text('Hours Report').first;
    await tester.tap(hoursReportTab);
    await tester.pumpAndSettle();

    // 3. Verify Hours & Output Report is displayed
    expect(find.text('Hours & Output Report'), findsOneWidget);
    expect(find.text('Team Allocation & Capacity'), findsOneWidget);
    expect(find.text('Hours by Work Type'), findsOneWidget);
    expect(find.text('Detailed Daily Hours Log'), findsOneWidget);

    // 4. Tap back on "Workboard" in the navigation bar
    final workboardTab = find.text('Workboard').first;
    await tester.tap(workboardTab);
    await tester.pumpAndSettle();

    expect(find.text('Studio Workboard'), findsOneWidget);
  });
}
