import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fryd/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('shows the Create Order workspace', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();
    expect(find.text('FRYD'), findsOneWidget);
    expect(find.text('Create order'), findsOneWidget);
    expect(find.text('Your order is empty'), findsOneWidget);
    expect(find.text('Paneer Tikka'), findsNothing);
  });

  testWidgets('opens the reports destination', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    expect(find.text('Reload reports'), findsOneWidget);
  });
}
