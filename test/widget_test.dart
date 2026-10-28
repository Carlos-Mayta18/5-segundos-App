import 'package:flutter_test/flutter_test.dart';
import 'package:reto_5_segundos/data/decks_data.dart';
import 'package:reto_5_segundos/main.dart';
import 'package:reto_5_segundos/models/game_session.dart';

void main() {
  test('El banco inicial cuenta con los 4 mazos temáticos y +50 cartas cada uno', () {
    expect(DecksRepository.allDecks.length, 4);
    for (final deck in DecksRepository.allDecks) {
      expect(deck.questions.length, greaterThanOrEqualTo(50),
          reason: 'El mazo ${deck.title} debe tener al menos 50 cartas');
    }
  });

  test('Sistema de barajado continuo no repite ninguna pregunta hasta agotar el mazo', () {
    final deck = DecksRepository.allDecks.first;
    final shuffler = ContinuousDeckShuffler([deck]);
    final seenQuestions = <String>{};

    for (int i = 0; i < deck.questions.length; i++) {
      final q = shuffler.nextQuestion();
      expect(seenQuestions.contains(q.prompt), isFalse,
          reason: 'La pregunta no debe repetirse antes de agotar el mazo');
      seenQuestions.add(q.prompt);
    }

    expect(seenQuestions.length, deck.questions.length);
    // Al pedir una más, reinicia y baraja automáticamente un nuevo ciclo
    final nextCycleQuestion = shuffler.nextQuestion();
    expect(nextCycleQuestion.prompt.isNotEmpty, isTrue);
    expect(shuffler.cyclesCompleted, 1);
  });

  testWidgets('Renderiza el menú principal sin fricción de inicio', (WidgetTester tester) async {
    await tester.pumpWidget(const Reto5SegundosApp());
    await tester.pumpAndSettle();

    expect(find.text('RETO 5 SEGUNDOS'), findsOneWidget);
    expect(find.text('MODO COMPETITIVO (POR PUNTOS)'), findsOneWidget);
    expect(find.text('MODO RÁPIDO / CASUAL (SIN REGISTRO)'), findsOneWidget);
  });
}
