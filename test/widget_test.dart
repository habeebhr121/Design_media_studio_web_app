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

    // 4. Test tab switching to Hours Report and back
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
