import 'package:flutter/services.dart';

/// Rest-timer alarm: system sound plus vibration / haptics.
///
/// Lives under `gym/data/` because it is a device helper, not a widget.
class GymRestAlert {
  static Future<void> fire() async {
    await SystemSound.play(SystemSoundType.alert);
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.vibrate();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.mediumImpact();
  }

  static Future<void> tick() async {
    await HapticFeedback.selectionClick();
  }
}
