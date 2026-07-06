import 'package:flutter_test/flutter_test.dart';
import 'package:find_your_two/app.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const FindYourTwoApp());
  });
}
