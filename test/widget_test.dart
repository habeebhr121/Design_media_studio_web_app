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
    expect(find.text('Browse Files from Desktop / Device'), findsOneWidget);
    expect(find.text('Browse Desktop'), findsOneWidget);
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
    expect(find.text('FAST DISPATCH'), findsOneWidget);

    // Initial default: Today (Oct 24, 2024)
    expect(find.text('Brand Identity Overhaul'), findsWidgets);

    // Switch to Yesterday (Oct 23, 2024)
    await tester.tap(find.text('Yesterday'));
    await tester.pumpAndSettle();
    expect(find.text('Kiosk Touch UI Prototype'), findsOneWidget);
    expect(find.text('Packaging 3D Render Shaders'), findsOneWidget);

    // Switch to Last 7 Days
    await tester.tap(find.text('Last 7 Days'));
    await tester.pumpAndSettle();
    expect(find.text('Brand Identity Overhaul'), findsWidgets);
    expect(find.text('Design System Typography Tokens'), findsOneWidget);

    // Switch to Last 14 Days
    await tester.tap(find.text('Last 14 Days'));
    await tester.pumpAndSettle();
    expect(find.text('Brand Identity Overhaul'), findsWidgets);
    expect(find.text('Iconography Suite (48 Icons)'), findsOneWidget);

    // Switch back to Today
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('Brand Identity Overhaul'), findsWidgets);

    // 5. Test Status filters showing active tasks across 7/14 days
    // Click 'Pending' - should show active pending tasks across 14 days
    final pendingChip = find.widgetWithText(InkWell, 'Pending').first;
    await tester.tap(pendingChip);
    await tester.pumpAndSettle();
    expect(find.text('Kiosk Touch UI Prototype'), findsOneWidget);
    expect(find.text('Global Conference Badge Kit'), findsOneWidget);

    // Click 'In Progress' - should show In Progress tasks across 14 days
    final inProgressChip = find.widgetWithText(InkWell, 'In Progress').first;
    await tester.tap(inProgressChip);
    await tester.pumpAndSettle();
    expect(find.text('Brand Identity Overhaul'), findsWidgets);
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

    // 7. Test Login Screen navigation, quick switcher, and sign in
    final loginTab = find.text('Login').first;
    await tester.tap(loginTab);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('STUDIO ACCESS'), findsOneWidget);
    expect(find.text('v1.1.0'), findsOneWidget);
    expect(find.text('Quick switch team member'), findsOneWidget);
    expect(find.text('Jawad'), findsOneWidget);
    expect(find.text('Sabith'), findsOneWidget);
    expect(find.text('Nizam'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('2FA Ready'), findsOneWidget);
    expect(find.text('Sign In to StudioTrack'), findsOneWidget);

    // Quick switch to Sabith
    await tester.tap(find.text('Sabith'));
    await tester.pumpAndSettle();

    // Click Sign In button to enter Workboard
    await tester.tap(find.text('Sign In to StudioTrack'));
    await tester.pumpAndSettle();
    expect(find.text('Studio Workboard'), findsOneWidget);

    // 8. Test "Assign Work Task" dialog with Pending Task Selection (Deduplication) & Priority toggle
    final addWorkBtn = find.text('Add New Work');
    await tester.tap(addWorkBtn);
    await tester.pumpAndSettle();

    expect(find.text('Assign Work Task'), findsOneWidget);
    expect(find.text('SELECT PENDING TASK FOR TODAY'), findsOneWidget);
    expect(find.text('Mark Priority'), findsOneWidget);

    // Toggle priority to High Priority
    await tester.tap(find.text('Mark Priority'));
    await tester.pumpAndSettle();
    expect(find.text('High Priority'), findsOneWidget);

    // Click on a deduplicated pending task chip
    final pendingChipInDialog = find.text('Kiosk Touch UI Prototype');
    expect(pendingChipInDialog, findsWidgets);
    await tester.tap(pendingChipInDialog.first);
    await tester.pumpAndSettle();

    // Verify confirmation text is displayed
    expect(find.text('Prefilled from pending queue. Adjust details if needed.'), findsOneWidget);

    // Click Create Entry to add as today's new work
    await tester.tap(find.text('Create Entry'));
    await tester.pumpAndSettle();

    // Verify dialog closed and today's work board now contains the created task
    expect(find.text('Assign Work Task'), findsNothing);
    expect(find.text('Kiosk Touch UI Prototype'), findsWidgets);

    // 9. Test that new task has '---' in time window and 'In progress'
    expect(find.textContaining('---'), findsWidgets);
    expect(find.text('In progress'), findsWidgets);

    // 10. Test Updating Status from In Progress to Completed with End Time & Automatic Hours Calculation
    final moreVertIcons = find.byIcon(Icons.more_vert);
    await tester.tap(moreVertIcons.first);
    await tester.pumpAndSettle();

    final updateStatusOption = find.text('Update Status');
    await tester.tap(updateStatusOption);
    await tester.pumpAndSettle();

    expect(find.text('Update Task Status'), findsOneWidget);
    expect(find.text('Active In Progress Session'), findsOneWidget);

    // Tap 'Completed' status inside the dialog
    final completedChoice = find.descendant(
      of: find.byType(Dialog),
      matching: find.text('Completed'),
    );
    await tester.tap(completedChoice);
    await tester.pumpAndSettle();

    // Verify 'WORK TIME & END TIME ENTRY' and automatic total logged calculation appear
    expect(find.text('WORK TIME & END TIME ENTRY'), findsOneWidget);
    expect(find.text('END TIME'), findsOneWidget);
    expect(find.textContaining('Total Logged:'), findsOneWidget);

    // Tap '+2h' preset
    await tester.tap(find.text('+2h'));
    await tester.pumpAndSettle();

    // Tap Save Status
    await tester.tap(find.text('Save Status'));
    await tester.pumpAndSettle();

    // Verify dialog is dismissed and status is updated
    expect(find.text('Update Task Status'), findsNothing);

    // 11. Verify that the previous pending task of "Kiosk Touch UI Prototype" was automatically updated to 'Progressed'
    await tester.tap(find.text('Last 14 Days'));
    await tester.pumpAndSettle();
    expect(find.text('Progressed'), findsWidgets);
  });
}
