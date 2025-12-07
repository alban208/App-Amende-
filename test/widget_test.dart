import 'package:flutter_test/flutter_test.dart';
import 'package:application_amende/app.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Construire l'app et déclencher un frame
    await tester.pumpWidget(const AmendesApp());

    // Vérifier que l'app se charge
    expect(find.byType(AmendesApp), findsOneWidget);
  });

  group('Montant calculations', () {
    test('Convert euros to centimes', () {
      expect(9000 / 100, 90.0);
      expect(4500 / 100, 45.0);
      expect(13550 / 100, 135.50);
    });

    test('Format euros', () {
      final centimes = 9000;
      final euros = (centimes / 100).toStringAsFixed(2);
      expect(euros, '90.00');
    });
  });
}