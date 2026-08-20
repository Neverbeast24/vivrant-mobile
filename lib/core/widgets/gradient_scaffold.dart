import 'package:flutter/material.dart';

import 'ambient_orbs.dart';
import '../theme/vivrant_colors.dart';

class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.atmosphere = true,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool atmosphere;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    return Container(
      decoration: BoxDecoration(gradient: c.bodyGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: extendBody,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        body: atmosphere
            ? Stack(
                fit: StackFit.expand,
                children: [
                  const AmbientOrbs(),
                  child,
                ],
              )
            : child,
      ),
    );
  }
}
