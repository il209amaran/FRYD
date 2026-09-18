import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanakki/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('shows the Create Order workspace', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();
    expect(find.text('KANAKKI'), findsOneWidget);
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

  testWidgets('uses full-width panes on a phone and preserves rotation state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Current Order (0)'), findsOneWidget);
    expect(find.text('Create order'), findsOneWidget);
    expect(find.text('Your order is empty'), findsNothing);

    await tester.tap(find.text('Current Order (0)'));
    await tester.pump();
    expect(find.text('Your order is empty'), findsOneWidget);

    tester.view.physicalSize = const Size(844, 390);
    await tester.pump();
    expect(find.text('Current Order (0)'), findsOneWidget);
    expect(find.text('Your order is empty'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
