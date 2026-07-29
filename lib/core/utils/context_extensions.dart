import 'package:flutter/material.dart';

import '../widgets/app_snackbar.dart';

extension VivrantContextX on BuildContext {
  void showSnack(String message, {SnackTone tone = SnackTone.info}) {
    showAppSnackBar(this, message: message, tone: tone);
  }

  void showSuccess(String message) =>
      showAppSnackBar(this, message: message, tone: SnackTone.success);

  void showError(String message) =>
      showAppSnackBar(this, message: message, tone: SnackTone.error);

  void showInfo(String message) =>
      showAppSnackBar(this, message: message, tone: SnackTone.info);

  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => Theme.of(this).textTheme;
}
