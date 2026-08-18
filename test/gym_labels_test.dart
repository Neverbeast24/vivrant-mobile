import 'package:flutter_test/flutter_test.dart';
import 'package:vivrant_mobile/features/gym/presentation/gym_labels.dart';

void main() {
  group('pickTodaysPlanDay', () {
    test('matches a weekday name on the session label', () {
      final named = [
        {'day': 'Monday · Pull', 'focus': 'Pull', 'exercises': <Map<String, dynamic>>[]},
        {'day': 'Wednesday', 'focus': 'Push', 'exercises': <Map<String, dynamic>>[]},
      ];
      expect(
        pickTodaysPlanDay(named, DateTime(2026, 8, 17, 12))?['focus'],
        'Pull',
      );
      expect(pickTodaysPlanDay(named, DateTime(2026, 8, 18, 12)), isNull);
      expect(
        pickTodaysPlanDay(named, DateTime(2026, 8, 19, 12))?['focus'],
        'Push',
      );
    });

    test('returns null on rest days when sessions are weekday-labeled', () {
      final named = [
        {'day': 'Monday · Pull', 'focus': 'Pull', 'exercises': <Map<String, dynamic>>[]},
        {'day': 'Tuesday · Push', 'focus': 'Push', 'exercises': <Map<String, dynamic>>[]},
        {'day': 'Wednesday · Legs', 'focus': 'Legs', 'exercises': <Map<String, dynamic>>[]},
        {'day': 'Thursday · Upper', 'focus': 'Upper', 'exercises': <Map<String, dynamic>>[]},
        {'day': 'Friday · Lower', 'focus': 'Lower', 'exercises': <Map<String, dynamic>>[]},
        {'day': 'Sunday · Full body', 'focus': 'Full body', 'exercises': <Map<String, dynamic>>[]},
      ];
      expect(pickTodaysPlanDay(named, DateTime(2026, 8, 22, 12)), isNull);
      expect(
        pickTodaysPlanDay(named, DateTime(2026, 8, 23, 12))?['focus'],
        'Full body',
      );
    });

    test('uses Mon/Wed/Fri for unlabeled 3-day plans and rests otherwise', () {
      final days = [
        {
          'day': 'Day 1',
          'focus': 'Pull',
          'exercises': [
            {'name': 'Row', 'sets': '3 x 10'},
          ],
        },
        {
          'day': 'Day 2',
          'focus': 'Push',
          'exercises': [
            {'name': 'Press', 'sets': '3 x 10'},
          ],
        },
        {
          'day': 'Day 3',
          'focus': 'Legs',
          'exercises': [
            {'name': 'Squat', 'sets': '3 x 8'},
          ],
        },
      ];
      expect(pickTodaysPlanDay(days, DateTime(2026, 8, 17, 12))?['focus'], 'Pull');
      expect(pickTodaysPlanDay(days, DateTime(2026, 8, 18, 12)), isNull);
      expect(pickTodaysPlanDay(days, DateTime(2026, 8, 19, 12))?['focus'], 'Push');
    });

    test('maps a 6-day unlabeled plan onto Mon–Fri + Sunday', () {
      final six = [
        {'day': 'Day 1', 'focus': 'Pull', 'exercises': <Map<String, dynamic>>[]},
        {'day': 'Day 2', 'focus': 'Push', 'exercises': <Map<String, dynamic>>[]},
        {'day': 'Day 3', 'focus': 'Legs', 'exercises': <Map<String, dynamic>>[]},
        {'day': 'Day 4', 'focus': 'Upper', 'exercises': <Map<String, dynamic>>[]},
        {'day': 'Day 5', 'focus': 'Lower', 'exercises': <Map<String, dynamic>>[]},
        {'day': 'Day 6', 'focus': 'Full', 'exercises': <Map<String, dynamic>>[]},
      ];
      expect(pickTodaysPlanDay(six, DateTime(2026, 8, 22, 12)), isNull);
      expect(pickTodaysPlanDay(six, DateTime(2026, 8, 23, 12))?['focus'], 'Full');
    });
  });

  group('sanitizeGymPlanLevel', () {
    test('defaults unknown values to beginner', () {
      expect(sanitizeGymPlanLevel(null), 'beginner');
      expect(sanitizeGymPlanLevel('expert'), 'beginner');
      expect(sanitizeGymPlanLevel('ADVANCED'), 'advanced');
      expect(sanitizeGymPlanLevel('intermediate'), 'intermediate');
    });
  });

  group('parseRestSeconds', () {
    test('reads seconds, minutes, and zero rest', () {
      expect(parseRestSeconds('90s'), 90);
      expect(parseRestSeconds('2 min'), 120);
      expect(parseRestSeconds('60-90s'), 60);
      expect(parseRestSeconds('0s'), 0);
      expect(parseRestSeconds('none'), 0);
    });
  });

  group('parseSetCount', () {
    test('reads the leading set count', () {
      expect(parseSetCount('4 x 10-12'), 4);
      expect(parseSetCount('3x10'), 3);
      expect(parseSetCount('1 set of 35-40 mins'), 1);
      expect(parseSetCount('12 minutes steady'), 1);
    });
  });

  group('gymSessionFocusFromPlan', () {
    test('maps day labels onto session focus values', () {
      expect(gymSessionFocusFromPlan('Pull'), 'upper');
      expect(gymSessionFocusFromPlan('Leg day'), 'lower');
      expect(gymSessionFocusFromPlan('strength'), 'strength');
      expect(gymSessionFocusFromPlan('HIIT'), 'endurance');
    });
  });
}
