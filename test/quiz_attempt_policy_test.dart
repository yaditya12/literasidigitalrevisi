import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/quiz_attempt_service.dart';

void main() {
  group('Quiz attempt policy', () {
    test('allows unlimited practice attempts', () {
      expect(canAttemptQuiz(0, 2), isTrue);
      expect(canAttemptQuiz(1, 2), isTrue);
      expect(canAttemptQuiz(2, 2), isTrue);
      expect(canAttemptQuiz(99, 2), isTrue);
    });

    test('keeps the best score only', () {
      expect(selectBestScore(currentBest: 70, newScore: 90), 90);
      expect(selectBestScore(currentBest: 90, newScore: 70), 90);
      expect(selectBestScore(currentBest: 70, newScore: 70), 70);
      expect(selectBestScore(currentBest: 0, newScore: 0), 0);
    });

    test('only adds points for score improvement', () {
      expect(pointsDeltaForAttempt(currentBest: 70, newScore: 90), 20);
      expect(pointsDeltaForAttempt(currentBest: 90, newScore: 70), 0);
      expect(pointsDeltaForAttempt(currentBest: 70, newScore: 70), 0);
    });
  });
}
