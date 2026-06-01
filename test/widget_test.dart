import 'package:flutter_test/flutter_test.dart';

import 'package:crudo/main.dart';

void main() {
  testWidgets('CrudoApp renders without crashing', (tester) async {
    await tester.pumpWidget(const CrudoApp());
    expect(find.text('Crudo'), findsOneWidget);
  });
}
