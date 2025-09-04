// lib/models/user_profile.dart

class UserProfile {
  final String name;
  final String concurredBy;
  final String role;
  final String password;

  UserProfile({
    required this.name,
    required this.concurredBy,
    required this.role,
    required this.password,
  });
}

class WeekEntry {
  final String majorActivity;
  final List<String> processedItems;
  final String? customActivity;
  bool isSaved;

  WeekEntry({
    required this.majorActivity,
    this.processedItems = const [],
    this.customActivity,
    this.isSaved = false,
  });
}