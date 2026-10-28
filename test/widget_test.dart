import 'package:sumadhura_project/repositories/local_visitor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumadhura_project/app.dart';

import 'package:sumadhura_project/providers/visitor_store.dart';

void main() {
  testWidgets(
    'registration validates and creates pass; check-in updates shared state',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final store = VisitorStore(
        LocalVisitorRepository(await SharedPreferences.getInstance()),
      );
      await store.load();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: store,
          child: const VisitorApp(isDemo: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Visitor desk'), findsOneWidget);
      await tester.tap(find.text('Register visitor'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Register & generate pass'));
      await tester.tap(find.text('Register & generate pass'));
      await tester.pumpAndSettle();
      expect(find.text('This field is required'), findsNWidgets(2));
      expect(find.text('Enter exactly 10 digits'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Rahul Sharma');
      await tester.enterText(fields.at(1), '9876543210');
      await tester.enterText(fields.at(2), 'rahul@example.com');
      await tester.enterText(fields.at(3), 'Site visit');
      await tester.ensureVisible(find.text('Register & generate pass'));
      await tester.tap(find.text('Register & generate pass'));
      await tester.pumpAndSettle();
      expect(find.text('Visitor pass'), findsOneWidget);
      expect(store.visitors, hasLength(1));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Check in visitor'),
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Check in visitor'));
      await tester.pumpAndSettle();
      expect(store.checkedIn, 1);
      expect(find.text('Check out visitor'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
