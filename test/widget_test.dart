import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vivrant_mobile/app/app.dart';

void main() {
  testWidgets('VivrantApp mounts under ProviderScope', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VivrantApp()));
    await tester.pump();
    expect(find.byType(VivrantApp), findsOneWidget);
  });
}
