// اختبار دخان بسيط: يتأكد أن التطبيق يُبنى ويعرض شاشة البداية دون أعطال.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tawfik/main.dart';

void main() {
  testWidgets('App builds and shows the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TawfikApp()));
    await tester.pump();

    // عنوان التطبيق وزر البداية يظهران في شاشة البداية.
    expect(find.text('التوفيق'), findsOneWidget);
    expect(find.text('ابدأ الآن'), findsOneWidget);
  });
}
