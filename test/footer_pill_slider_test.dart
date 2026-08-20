import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivrant_mobile/core/widgets/floating_glass_nav_bar.dart';
import 'package:vivrant_mobile/core/widgets/sliding_indexed_stack.dart';

void main() {
  const destinations = [
    FloatingNavDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    FloatingNavDestination(
      icon: Icons.access_time_outlined,
      selectedIcon: Icons.access_time_rounded,
      label: 'Attendance',
    ),
    FloatingNavDestination(
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
      label: 'Announcements',
    ),
    FloatingNavDestination(
      icon: Icons.person_outlined,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  Widget wrapNav({
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    double? selectedPosition,
    ValueListenable<double>? positionListenable,
    ValueChanged<int>? onDragSettled,
  }) {
    return MaterialApp(
      home: Scaffold(
        bottomNavigationBar: FloatingGlassNavBar(
          destinations: destinations,
          selectedIndex: selectedIndex,
          selectedPosition: selectedPosition,
          positionListenable: positionListenable,
          onDestinationSelected: onSelected,
          onDragSettled: onDragSettled,
        ),
      ),
    );
  }

  testWidgets('pill nav slides indicator to tapped tab', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => wrapNav(
          selectedIndex: selected,
          onSelected: (i) => setState(() => selected = i),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);

    final homeCenterBefore = tester.getCenter(find.byIcon(Icons.home_rounded));

    await tester.tapAt(tester.getCenter(find.byIcon(Icons.person_outlined)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();

    expect(selected, 3);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Home'), findsNothing);

    final homeCenterAfter = tester.getCenter(find.byIcon(Icons.home_outlined));
    expect((homeCenterAfter.dx - homeCenterBefore.dx).abs(), greaterThan(1.0));
  });

  testWidgets('footer tap and page swipe stay locked together', (tester) async {
    var index = 0;
    final position = ValueNotifier<double>(0);

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: VivrantSlidingIndexedStack(
                index: index,
                onIndexChanged: (i) => setState(() => index = i),
                positionNotifier: position,
                children: const [
                  Center(child: Text('Page A')),
                  Center(child: Text('Page B')),
                  Center(child: Text('Page C')),
                  Center(child: Text('Page D')),
                ],
              ),
              bottomNavigationBar: FloatingGlassNavBar(
                destinations: destinations,
                selectedIndex: index,
                positionListenable: position,
                onDestinationSelected: (i) => setState(() => index = i),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(position.value, closeTo(0.0, 0.05));

    await tester.tapAt(tester.getCenter(find.byIcon(Icons.person_outlined)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(position.value, greaterThan(0.2));
    await tester.pumpAndSettle();
    expect(index, 3);
    expect(find.text('Page D'), findsOneWidget);
    expect(position.value, closeTo(3.0, 0.05));
    position.dispose();
  });

  testWidgets('pill tracks fractional swipe position via listenable', (
    tester,
  ) async {
    final position = ValueNotifier<double>(1.5);
    await tester.pumpWidget(
      wrapNav(
        selectedIndex: 0,
        positionListenable: position,
        onSelected: (_) {},
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      find.byIcon(Icons.access_time_outlined).evaluate().isNotEmpty ||
          find.byIcon(Icons.access_time_rounded).evaluate().isNotEmpty,
      isTrue,
    );
    expect(
      find.byIcon(Icons.notifications_outlined).evaluate().isNotEmpty ||
          find.byIcon(Icons.notifications_rounded).evaluate().isNotEmpty,
      isTrue,
    );
    position.dispose();
  });

  testWidgets('pill settles when a shell stops feeding a listenable', (
    tester,
  ) async {
    final position = ValueNotifier<double>(1.6);
    var useListenable = true;
    late StateSetter rebuild;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return wrapNav(
            selectedIndex: 2,
            positionListenable: useListenable ? position : null,
            onSelected: (_) {},
          );
        },
      ),
    );
    await tester.pump();

    rebuild(() => useListenable = false);
    await tester.pumpAndSettle();

    expect(find.text('Announcements'), findsOneWidget);
    expect(find.text('Attendance'), findsNothing);
    expect(tester.takeException(), isNull);
    position.dispose();
  });

  testWidgets('footer drag released on the starting tab snaps back', (
    tester,
  ) async {
    var index = 0;
    final position = ValueNotifier<double>(0);

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: VivrantSlidingIndexedStack(
                index: index,
                positionNotifier: position,
                onIndexChanged: (i) => setState(() => index = i),
                children: const [
                  Center(child: Text('Page A')),
                  Center(child: Text('Page B')),
                  Center(child: Text('Page C')),
                ],
              ),
              bottomNavigationBar: FloatingGlassNavBar(
                destinations: destinations,
                selectedIndex: index,
                positionListenable: position,
                onDestinationSelected: (i) => setState(() => index = i),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final drag = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.home_rounded)),
    );
    await drag.moveBy(const Offset(60, 0));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();

    expect(index, 0);
    expect(position.value, closeTo(0.0, 0.05));
    expect(find.text('Page A'), findsOneWidget);
    position.dispose();
  });

  testWidgets('dragging footer moves module page in lockstep', (tester) async {
    var index = 0;
    final position = ValueNotifier<double>(0);

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: VivrantSlidingIndexedStack(
                index: index,
                positionNotifier: position,
                onIndexChanged: (i) => setState(() => index = i),
                children: const [
                  Center(child: Text('Page A')),
                  Center(child: Text('Page B')),
                  Center(child: Text('Page C')),
                  Center(child: Text('Page D')),
                ],
              ),
              bottomNavigationBar: FloatingGlassNavBar(
                destinations: destinations,
                selectedIndex: index,
                positionListenable: position,
                onDestinationSelected: (i) => setState(() => index = i),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final drag = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.home_rounded)),
    );
    for (var i = 0; i < 8; i++) {
      await drag.moveBy(const Offset(18, 0));
      await tester.pump(const Duration(milliseconds: 8));
      expect(tester.takeException(), isNull);
    }

    expect(position.value, greaterThan(0.5));

    await drag.up();
    await tester.pumpAndSettle();
    expect(index, 1);
    expect(find.text('Page B'), findsOneWidget);
    expect(position.value, closeTo(1.0, 0.05));
    position.dispose();
  });

  testWidgets('footer pill follows the finger onto the target module', (
    tester,
  ) async {
    var index = 0;
    final position = ValueNotifier<double>(0);

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: VivrantSlidingIndexedStack(
                index: index,
                positionNotifier: position,
                onIndexChanged: (i) => setState(() => index = i),
                children: const [
                  Center(child: Text('Page A')),
                  Center(child: Text('Page B')),
                  Center(child: Text('Page C')),
                  Center(child: Text('Page D')),
                ],
              ),
              bottomNavigationBar: FloatingGlassNavBar(
                destinations: destinations,
                selectedIndex: index,
                positionListenable: position,
                onDestinationSelected: (i) => setState(() => index = i),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final start = tester.getCenter(find.byIcon(Icons.home_rounded));
    final target = tester.getCenter(find.byIcon(Icons.person_outlined));
    expect(target.dx, greaterThan(start.dx));

    final drag = await tester.startGesture(start);
    final step = Offset((target.dx - start.dx) / 16, 0);
    for (var i = 0; i < 16; i++) {
      await drag.moveBy(step);
      await tester.pump(const Duration(milliseconds: 8));
    }

    expect(position.value, greaterThan(2.0));

    await drag.up();
    await tester.pumpAndSettle();
    expect(index, 3);
    expect(find.text('Page D'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    position.dispose();
  });

  testWidgets('swiping page view updates footer index without shell setState', (
    tester,
  ) async {
    var index = 0;
    final position = ValueNotifier<double>(0);
    var shellBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            shellBuilds++;
            return Scaffold(
              body: VivrantSlidingIndexedStack(
                index: index,
                onIndexChanged: (i) => setState(() => index = i),
                positionNotifier: position,
                children: const [
                  Center(child: Text('Page A')),
                  Center(child: Text('Page B')),
                  Center(child: Text('Page C')),
                ],
              ),
              bottomNavigationBar: ListenableBuilder(
                listenable: position,
                builder: (_, _) =>
                    Text('pos-${position.value.toStringAsFixed(1)}'),
              ),
            );
          },
        ),
      ),
    );

    final buildsBeforeSwipe = shellBuilds;
    expect(find.text('Page A'), findsOneWidget);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Page A')),
    );
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();
    expect(position.value, greaterThan(0.1));
    expect(shellBuilds, buildsBeforeSwipe);

    await gesture.moveBy(const Offset(-280, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(index, 1);
    expect(find.text('Page B'), findsOneWidget);
    expect(position.value, closeTo(1.0, 0.05));
    position.dispose();
  });

  testWidgets('mouse drag also changes module (desktop)', (tester) async {
    var index = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: VivrantSlidingIndexedStack(
                index: index,
                onIndexChanged: (i) => setState(() => index = i),
                children: const [
                  Center(child: Text('Page A')),
                  Center(child: Text('Page B')),
                ],
              ),
            );
          },
        ),
      ),
    );

    await tester.fling(
      find.text('Page A'),
      const Offset(-400, 0),
      1000,
      deviceKind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();

    expect(index, 1);
    expect(find.text('Page B'), findsOneWidget);
  });

  testWidgets('tapping footer animates page view to that tab', (tester) async {
    var index = 0;
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Scaffold(
              body: VivrantSlidingIndexedStack(
                index: index,
                onIndexChanged: (i) => setState(() => index = i),
                children: const [
                  Center(child: Text('Page A')),
                  Center(child: Text('Page B')),
                  Center(child: Text('Page C')),
                ],
              ),
            );
          },
        ),
      ),
    );

    rebuild(() => index = 2);
    await tester.pumpAndSettle();

    expect(find.text('Page C'), findsOneWidget);
    expect(find.text('Page A'), findsNothing);
  });
}
