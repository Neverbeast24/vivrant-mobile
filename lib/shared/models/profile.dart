import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  const Profile({
    required this.userId,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.role = 'user',
    this.status = 'active',
    this.timezone = 'Asia/Manila',
    this.birthDate,
    this.sex,
    this.heightCm,
    this.weightKg,
    this.goalWeightKg,
    this.activityLevel,
    this.healthFocus,
    this.dailyStepGoal = 8000,
    this.dailyWaterGoalMl = 2500,
    this.monthlyHealthBudget,
    this.bio,
  });

  final String userId;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String role;
  final String status;

  bool get isStaff => role == 'admin' || role == 'super_admin';
  bool get isSuperAdmin => role == 'super_admin';
  bool get isActive => status == 'active';
  final String timezone;
  final String? birthDate;
  final String? sex;
  final double? heightCm;
  final double? weightKg;
  final double? goalWeightKg;
  final String? activityLevel;
  final String? healthFocus;
  final int dailyStepGoal;
  final int dailyWaterGoalMl;
  final double? monthlyHealthBudget;
  final String? bio;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['user_id'] as String? ?? json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Member',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'user',
      status: json['status'] as String? ?? 'active',
      timezone: json['timezone'] as String? ?? 'Asia/Manila',
      birthDate: json['birth_date'] as String?,
      sex: json['sex'] as String?,
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      goalWeightKg: (json['goal_weight_kg'] as num?)?.toDouble(),
      activityLevel: json['activity_level'] as String?,
      healthFocus: json['health_focus'] as String?,
      dailyStepGoal: (json['daily_step_goal'] as num?)?.toInt() ?? 8000,
      dailyWaterGoalMl: (json['daily_water_goal_ml'] as num?)?.toInt() ?? 2500,
      monthlyHealthBudget: (json['monthly_health_budget'] as num?)?.toDouble(),
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'display_name': displayName,
        'email': email,
        'avatar_url': avatarUrl,
        'role': role,
        'status': status,
        'timezone': timezone,
        'birth_date': birthDate,
        'sex': sex,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'goal_weight_kg': goalWeightKg,
        'activity_level': activityLevel,
        'health_focus': healthFocus,
        'daily_step_goal': dailyStepGoal,
        'daily_water_goal_ml': dailyWaterGoalMl,
        'monthly_health_budget': monthlyHealthBudget,
        'bio': bio,
      };

  @override
  List<Object?> get props => [userId, email, displayName];
}
