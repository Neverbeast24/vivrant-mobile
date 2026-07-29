import 'package:flutter/material.dart';

/// Single entry in the More menu / module directory.
class AppModule {
  const AppModule({
    required this.icon,
    required this.label,
    required this.caption,
    required this.path,
    this.group = ModuleGroup.wellness,
    this.minRole = 'user',
  });

  final IconData icon;
  final String label;
  final String caption;
  final String path;
  final ModuleGroup group;

  /// Minimum role required: `user` | `admin` | `super_admin`.
  final String minRole;
}

enum ModuleGroup {
  training('Training'),
  wellness('Wellness'),
  household('Household'),
  insights('Insights'),
  account('Account'),
  admin('Admin');

  const ModuleGroup(this.label);
  final String label;
}

/// Catalog mirrored from viva-server `dashboardNav` (member modules only).
const appModules = <AppModule>[
  AppModule(
    icon: Icons.fitness_center,
    label: 'Gym',
    caption: 'Demos & sessions',
    path: '/gym',
    group: ModuleGroup.training,
  ),
  AppModule(
    icon: Icons.nightlight_round,
    label: 'Sleep',
    caption: 'Rest & recovery',
    path: '/sleep',
    group: ModuleGroup.wellness,
  ),
  AppModule(
    icon: Icons.water_drop_outlined,
    label: 'Hydration',
    caption: 'Water goals',
    path: '/hydration',
    group: ModuleGroup.wellness,
  ),
  AppModule(
    icon: Icons.air,
    label: 'Mindfulness',
    caption: 'Mood & calm',
    path: '/mindfulness',
    group: ModuleGroup.wellness,
  ),
  AppModule(
    icon: Icons.menu_book_outlined,
    label: 'Journal',
    caption: 'Notes & reflection',
    path: '/journal',
    group: ModuleGroup.wellness,
  ),
  AppModule(
    icon: Icons.local_fire_department_outlined,
    label: 'Habits',
    caption: 'Streaks & challenges',
    path: '/habits',
    group: ModuleGroup.wellness,
  ),
  AppModule(
    icon: Icons.shopping_basket_outlined,
    label: 'Groceries',
    caption: 'Smart shopping list',
    path: '/groceries',
    group: ModuleGroup.household,
  ),
  AppModule(
    icon: Icons.kitchen_outlined,
    label: 'Pantry',
    caption: 'Stock at a glance',
    path: '/pantry',
    group: ModuleGroup.household,
  ),
  AppModule(
    icon: Icons.account_balance_wallet_outlined,
    label: 'Spending',
    caption: 'Monthly budget',
    path: '/spending',
    group: ModuleGroup.household,
  ),
  AppModule(
    icon: Icons.insights_outlined,
    label: 'Reports',
    caption: 'Weekly patterns',
    path: '/reports',
    group: ModuleGroup.insights,
  ),
  AppModule(
    icon: Icons.search_rounded,
    label: 'Search',
    caption: 'Find across modules',
    path: '/search',
    group: ModuleGroup.insights,
  ),
  AppModule(
    icon: Icons.person_outline,
    label: 'Profile',
    caption: 'Goals & preferences',
    path: '/profile',
    group: ModuleGroup.account,
  ),
  AppModule(
    icon: Icons.support_agent,
    label: 'Help',
    caption: 'Support tickets',
    path: '/support',
    group: ModuleGroup.account,
  ),
  AppModule(
    icon: Icons.notifications_outlined,
    label: 'Notifications',
    caption: 'Inbox',
    path: '/notifications',
    group: ModuleGroup.account,
  ),
];

/// Staff console modules — filtered by [AppModule.minRole] in the More menu.
const adminModules = <AppModule>[
  AppModule(
    icon: Icons.admin_panel_settings_outlined,
    label: 'Admin overview',
    caption: 'Platform pulse',
    path: '/admin',
    group: ModuleGroup.admin,
    minRole: 'admin',
  ),
  AppModule(
    icon: Icons.people_outline,
    label: 'Users',
    caption: 'Roles and access',
    path: '/admin/users',
    group: ModuleGroup.admin,
    minRole: 'admin',
  ),
  AppModule(
    icon: Icons.support_agent_outlined,
    label: 'Tickets',
    caption: 'Bugs & support',
    path: '/admin/tickets',
    group: ModuleGroup.admin,
    minRole: 'admin',
  ),
  AppModule(
    icon: Icons.shield_outlined,
    label: 'Permissions',
    caption: 'Access model',
    path: '/admin/roles',
    group: ModuleGroup.admin,
    minRole: 'admin',
  ),
  AppModule(
    icon: Icons.receipt_long_outlined,
    label: 'Audit logs',
    caption: 'Admin changes',
    path: '/admin/audit',
    group: ModuleGroup.admin,
    minRole: 'admin',
  ),
  AppModule(
    icon: Icons.settings_suggest_outlined,
    label: 'System',
    caption: 'Health & broadcast',
    path: '/admin/settings',
    group: ModuleGroup.admin,
    minRole: 'admin',
  ),
  AppModule(
    icon: Icons.travel_explore_outlined,
    label: 'Member activity',
    caption: 'All user logs',
    path: '/admin/activity',
    group: ModuleGroup.admin,
    minRole: 'super_admin',
  ),
  AppModule(
    icon: Icons.inbox_outlined,
    label: 'Inquiries',
    caption: 'Contact requests',
    path: '/admin/inquiries',
    group: ModuleGroup.admin,
    minRole: 'super_admin',
  ),
];

/// Modules visible for a given profile role.
List<AppModule> modulesForRole(String? role) {
  final staff = role == 'admin' || role == 'super_admin';
  final superAdmin = role == 'super_admin';
  if (!staff) return appModules;
  return [
    ...appModules,
    ...adminModules.where((m) {
      if (m.minRole == 'super_admin') return superAdmin;
      return staff;
    }),
  ];
}
