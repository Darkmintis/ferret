import 'package:ferret_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('example app loads', (tester) async {
    await tester.pumpWidget(const FerretExampleApp());
    await tester.pump();

    expect(find.text('Ferret'), findsOneWidget);
    expect(find.textContaining('Dio · GET'), findsOneWidget);
  });
}
