import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_track/main.dart';

void main() {
  testWidgets('StudioTrackApp smoke test and task actions test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // 1. Build app and verify Workboard is displayed
    await tester.pumpWidget(const StudioTrackApp());
    await tester.pumpAndSettle();

    expect(find.text('Studio Workboard'), findsOneWidget);
    expect(find.text('Team Capacity Matrix'), findsOneWidget);

    // 2. Verify attachment badges exist
    expect(find.text('2 files'), findsOneWidget);
    expect(find.text('+ Attach'), findsWidgets);

    // 3. Test clicking an attachment button to open gallery
    await tester.tap(find.text('2 files').first);
    await tester.pumpAndSettle();

    expect(find.text('Task Attachments & Deliverables'), findsOneWidget);
    expect(find.text('Quick Attach Studio Presets:'), findsOneWidget);

    // Close attachment dialog
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // 4. Test Day filter switching (Today / Yesterday / Last 7 Days / Last 14 Days / Custom Date)
    expect(find.text('DAY:'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Last 7 Days'), findsOneWidget);
    expect(find.text('Last 14 Days'), findsOneWidget);
    expect(find.text('Custom Date'), findsOneWidget);

    // Initial default: Today (Oct 24, 2024)
    expect(find.text('Brand Identity Overhaul'), findsOneWidget);

    // Switch to Yesterday (Oct 23, 2024)
    await tester.tap(find.text('Yesterday'));
    await tester.pumpAndSettle();
    expect(find.text('Kiosk Touch UI Prototype'), findsOneWidget);
    expect(find.text('Packaging 3D Render Shaders'), findsOneWidget);

    // Switch to Last 7 Days
    await tester.tap(find.text('Last 7 Days'));
    await tester.pumpAndSettle();
    expect(find.text('Brand Identity Overhaul'), findsOneWidget);
    expect(find.text('Design System Typography Tokens'), findsOneWidget);

    // Switch to Last 14 Days
    await tester.tap(find.text('Last 14 Days'));
    await tester.pumpAndSettle();
    expect(find.text('Brand Identity Overhaul'), findsOneWidget);
    expect(find.text('Iconography Suite (48 Icons)'), findsOneWidget);

    // Switch back to Today
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('Brand Identity Overhaul'), findsOneWidget);

    // 5. Test Status filters showing active tasks across 7/14 days
    // Click 'Pending' - should show active pending tasks across 14 days
    final pendingChip = find.widgetWithText(InkWell, 'Pending').first;
    await tester.tap(pendingChip);
    await tester.pumpAndSettle();
    expect(find.text('Kiosk Touch UI Prototype'), findsOneWidget);
    expect(find.text('Global Conference Badge Kit'), findsOneWidget);

    // Click 'In Review' - should show In Review tasks across 14 days
    final inReviewChip = find.widgetWithText(InkWell, 'In Review').first;
    await tester.tap(inReviewChip);
    await tester.pumpAndSettle();
    expect(find.text('Product Reel 3D'), findsOneWidget);
    expect(find.text('Packaging 3D Render Shaders'), findsOneWidget);
    expect(find.text('Dynamic Title Animation Loop'), findsOneWidget);

    // Click 'In Progress' - should show In Progress tasks across 14 days
    final inProgressChip = find.widgetWithText(InkWell, 'In Progress').first;
    await tester.tap(inProgressChip);
    await tester.pumpAndSettle();
    expect(find.text('Brand Identity Overhaul'), findsOneWidget);
    expect(find.text('Editorial Magazine Spread Grading'), findsOneWidget);

    // Reset status to 'All'
    final allStatusChip = find.widgetWithText(InkWell, 'All').first;
    await tester.tap(allStatusChip);
    await tester.pumpAndSettle();

    // 6. Test tab switching to Hours Report and back
    final hoursReportTab = find.text('Hours Report').first;
    await tester.tap(hoursReportTab);
    await tester.pumpAndSettle();
    expect(find.text('Hours & Output Report'), findsOneWidget);

    final workboardTab = find.text('Workboard').first;
    await tester.tap(workboardTab);
    await tester.pumpAndSettle();
    expect(find.text('Studio Workboard'), findsOneWidget);
  });
}
