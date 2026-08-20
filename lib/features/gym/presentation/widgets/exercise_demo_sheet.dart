import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../shared/models/gym_exercise.dart';
import '../../data/gym_labels.dart';

Future<void> showExerciseDemoSheet(
  BuildContext context,
  GymExercise exercise,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ExerciseDemoSheet(exercise: exercise),
  );
}

class ExerciseDemoSheet extends StatelessWidget {
  const ExerciseDemoSheet({super.key, required this.exercise});

  final GymExercise exercise;

  Future<void> _watch(BuildContext context) async {
    final raw = exercise.demoVideoUrl?.trim();
    if (raw == null || raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      context.showError('Could not open demo video.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    final thumb = exercise.demoThumbnailUrl?.trim();
    final hasThumb = thumb != null && thumb.isNotEmpty;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 12, 18, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.ink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasThumb)
                        CachedNetworkImage(
                          imageUrl: thumb,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => ColoredBox(color: c.accentSoft),
                          errorWidget: (_, __, ___) => ColoredBox(
                            color: c.accentSoft,
                            child: Icon(
                              muscleIcon(exercise.muscleGroup),
                              color: c.accent,
                              size: 40,
                            ),
                          ),
                        )
                      else
                        ColoredBox(
                          color: c.accentSoft,
                          child: Icon(
                            muscleIcon(exercise.muscleGroup),
                            color: c.accent,
                            size: 40,
                          ),
                        ),
                      if (exercise.hasDemo)
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: c.panel.withValues(alpha: 0.94),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 32,
                              color: c.accent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                exercise.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (exercise.muscleGroup.isNotEmpty)
                    _MetaChip(
                      icon: muscleIcon(exercise.muscleGroup),
                      label: humanizeLabel(exercise.muscleGroup),
                    ),
                  if (exercise.equipment.isNotEmpty)
                    _MetaChip(
                      icon: Icons.handyman_outlined,
                      label: humanizeLabel(exercise.equipment),
                    ),
                  if (exercise.difficulty.isNotEmpty)
                    _MetaChip(
                      icon: Icons.signal_cellular_alt_rounded,
                      label: humanizeLabel(exercise.difficulty),
                      color: difficultyColor(
                        exercise.difficulty,
                        brightness: Theme.of(context).brightness,
                      ),
                    ),
                  if (exercise.durationSeconds > 0)
                    _MetaChip(
                      icon: Icons.timer_outlined,
                      label: '${exercise.durationSeconds}s',
                    ),
                ],
              ),
              if (exercise.cues != null && exercise.cues!.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Form cues',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: c.ink.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  exercise.cues!,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: c.ink.withValues(alpha: 0.78),
                  ),
                ),
              ],
              if (exercise.hasDemo) ...[
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Watch demo',
                  onPressed: () => _watch(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? VivrantColors.of(context).accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: tint,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
