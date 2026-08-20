import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WellnessPulseBar extends StatelessWidget {
  const WellnessPulseBar({
    super.key,
    required this.today,
    this.current,
  });

  final Map<String, dynamic> today;
  final String? current;

  @override
  Widget build(BuildContext context) {
    final checkin = today['checkin'] is Map
        ? Map<String, dynamic>.from(today['checkin'] as Map)
        : const <String, dynamic>{};
    final sleepMin = (checkin['sleep_minutes'] as num?)?.toInt();
    final waterMl = (today['water_ml'] as num?)?.toInt() ??
        (checkin['water_ml'] as num?)?.toInt() ??
        0;
    final mood = (checkin['mood'] as num?)?.toInt();

    final items = [
      (
        key: 'sleep',
        href: '/sleep',
        label: 'Sleep',
        value: sleepMin == null ? '—' : '${(sleepMin / 60).toStringAsFixed(1)}h',
      ),
      (
        key: 'hydration',
        href: '/hydration',
        label: 'Water',
        value: '${(waterMl / 1000).toStringAsFixed(1)}L',
      ),
      (
        key: 'mindfulness',
        href: '/mindfulness',
        label: 'Mood',
        value: mood == null ? '—' : '$mood/5',
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: Material(
              color: current == items[i].key
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                  : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push(items[i].href),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Text(
                        items[i].label.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].value,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (i < items.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}
