import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect/services/matching_service.dart';

void main() {
  // calculateScore() er en statisk metode — kan kalles uten å instansiere
  // klassen og uten Supabase-initialisering. Ideell for unit-testing.

  group('MatchingService – calculateScore()', () {
    // Test 1: Brukeren har ingen registrerte ferdigheter.
    // Forventet: 0, siden ingen vekter bidrar til summen.
    test('returnerer 0 når brukeren har ingen ferdigheter', () {
      final score = MatchingService.calculateScore({}, [1, 2, 3]);
      expect(score, equals(0));
    });

    // Test 2: Brukeren har alle prosjektets ferdigheter på advanced-nivå (vekt 1.0).
    // Forventet: 100, siden sum(vekter) / antall_skills = 1.0 → 100%.
    test('returnerer 100 ved fullt match med advanced-ferdigheter', () {
      final score = MatchingService.calculateScore(
        {1: 1.0, 2: 1.0, 3: 1.0},
        [1, 2, 3],
      );
      expect(score, equals(100));
    });

    // Test 3: Brukeren har kun én av to påkrevde ferdigheter, på advanced-nivå.
    // Forventet: 50, siden (1.0 + 0.0) / 2 × 100 = 50.
    test('returnerer 50 ved delvis match (én av to ferdigheter)', () {
      final score = MatchingService.calculateScore(
        {1: 1.0},
        [1, 2],
      );
      expect(score, equals(50));
    });

    // Test 4: Brukeren har ferdigheten på beginner-nivå (vekt 0.3).
    // Forventet: 30, som er lavere enn advanced (100).
    // Testen bekrefter at proficiency-nivå påvirker resultatet.
    test('returnerer 30 når brukeren har ferdigheten på beginner-nivå', () {
      final score = MatchingService.calculateScore(
        {1: 0.3},
        [1],
      );
      expect(score, equals(30));
    });

    // Test 5: Brukeren har en ekstra ferdighet (skill 99) som prosjektet ikke krever.
    // Forventet: 100, siden kun prosjektets skills (skill 1) teller i nevneren.
    test('ignorerer ferdigheter brukeren har som prosjektet ikke krever', () {
      final score = MatchingService.calculateScore(
        {1: 1.0, 99: 1.0},
        [1],
      );
      expect(score, equals(100));
    });

    // Test 6: Prosjektet krever ingen ferdigheter (tom liste).
    // Forventet: 100, siden alle studenter automatisk matcher et kravløst prosjekt.
    test('returnerer 100 når prosjektet ikke krever noen ferdigheter', () {
      final score = MatchingService.calculateScore(
        {1: 1.0},
        [],
      );
      expect(score, equals(100));
    });

    // Test 7: Brukeren har intermediate-nivå (vekt 0.6) på én av to ferdigheter.
    // Forventet: (0.6 + 0.0) / 2 × 100 = 30.
    // Bekrefter at intermediate gir lavere score enn advanced ved delvis match.
    test('returnerer 30 ved intermediate-nivå på én av to ferdigheter', () {
      final score = MatchingService.calculateScore(
        {1: 0.6},
        [1, 2],
      );
      expect(score, equals(30));
    });
  });
}
