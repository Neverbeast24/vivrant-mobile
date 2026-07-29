import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stable keys for [ModuleCache] entries.
abstract final class ModuleCacheKeys {
  static const today = 'today';
  static const nutrition = 'nutrition';
  static const movement = 'movement';
  static const aiChat = 'ai_chat';
  static const gymOverview = 'gym_overview';
  static const gymDemos = 'gym_demos';
  static const gymMachines = 'gym_machines';
  static const gymSessions = 'gym_sessions';
  static const gymPlans = 'gym_plans';
  static const habits = 'habits';
  static const challenges = 'challenges';
  static const journal = 'journal';
  static const groceries = 'groceries';
  static const pantry = 'pantry';
  static const spending = 'spending';
  static const reports = 'reports';
  static const reminders = 'reminders';
  static const notifications = 'notifications';
  static const goals = 'goals';
  static const healthHistory = 'health_history';
  static const adminOverview = 'admin_overview';
  static const adminUsers = 'admin_users';
  static const adminTickets = 'admin_tickets';
  static const adminRoles = 'admin_roles';
  static const adminAudit = 'admin_audit';
  static const adminSettings = 'admin_settings';
  static const adminActivity = 'admin_activity';
  static const adminInquiries = 'admin_inquiries';
}

/// In-memory session cache for module payloads.
///
/// Survives route dispose so revisiting a module can paint instantly
/// instead of showing a full-screen spinner while refetching.
class ModuleCache {
  final Map<String, Object?> _store = {};

  T? read<T>(String key) {
    final value = _store[key];
    return value is T ? value : null;
  }

  void write(String key, Object? value) {
    _store[key] = value;
  }

  void invalidate([String? key]) {
    if (key == null) {
      _store.clear();
    } else {
      _store.remove(key);
    }
  }

  bool has(String key) => _store.containsKey(key);

  /// True only when this module has never been loaded this session.
  /// Empty lists still count as cached — do not use `list.isEmpty` for this.
  bool shouldShowSpinner(String key) => !has(key);
}

final moduleCacheProvider = Provider<ModuleCache>((ref) => ModuleCache());
