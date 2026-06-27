import 'package:flutter_test/flutter_test.dart';
import 'package:md_to_pdf/app.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const MdToPdfApp());
    expect(find.byType(MdToPdfApp), findsOneWidget);
  });
}
