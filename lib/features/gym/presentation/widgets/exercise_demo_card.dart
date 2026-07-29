import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/vivrant_colors.dart';
import '../../../../shared/models/gym_exercise.dart';
import '../gym_labels.dart';

class ExerciseDemoCard extends StatelessWidget {
  const ExerciseDemoCard({
    super.key,
    required this.exercise,
    required this.onTap,
  });

  final GymExercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumb = exercise.demoThumbnailUrl?.trim();
    final hasThumb = thumb != null && thumb.isNotEmpty;
    final meta = [
      if (exercise.muscleGroup.isNotEmpty) humanizeLabel(exercise.muscleGroup),
      if (exercise.equipment.isNotEmpty) humanizeLabel(exercise.equipment),
    ].join(' · ');

    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: VivrantColors.ink.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              _Thumb(
                hasThumb: hasThumb,
                thumbUrl: thumb,
                muscleGroup: exercise.muscleGroup,
                showPlay: exercise.hasDemo,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.25,
                        color: VivrantColors.ink,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        style: TextStyle(
                          color: VivrantColors.ink.withValues(alpha: 0.62),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (exercise.difficulty.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _DifficultyChip(label: exercise.difficulty),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: VivrantColors.ink.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.hasThumb,
    required this.thumbUrl,
    required this.muscleGroup,
    required this.showPlay,
  });

  final bool hasThumb;
  final String? thumbUrl;
  final String muscleGroup;
  final bool showPlay;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 76,
        height: 76,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasThumb)
              CachedNetworkImage(
                imageUrl: thumbUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _Fallback(muscleGroup: muscleGroup),
                errorWidget: (_, __, ___) =>
                    _Fallback(muscleGroup: muscleGroup),
              )
            else
              _Fallback(muscleGroup: muscleGroup),
            if (showPlay)
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: VivrantColors.panel.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 18,
                    color: VivrantColors.accent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.muscleGroup});

  final String muscleGroup;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VivrantColors.accentSoft,
      child: Icon(
        muscleIcon(muscleGroup),
        color: VivrantColors.accent,
        size: 28,
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = difficultyColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        humanizeLabel(label),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
