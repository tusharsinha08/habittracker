enum HabitCategory {
  health,
  study,
  fitness,
  productivity,
  mentalHealth,
  others;

  String get displayName {
    switch (this) {
      case HabitCategory.health:
        return 'Health';
      case HabitCategory.study:
        return 'Study';
      case HabitCategory.fitness:
        return 'Fitness';
      case HabitCategory.productivity:
        return 'Productivity';
      case HabitCategory.mentalHealth:
        return 'Mental Health';
      case HabitCategory.others:
        return 'Others';
    }
  }

  String get icon {
    switch (this) {
      case HabitCategory.health:
        return '🏥';
      case HabitCategory.study:
        return '📚';
      case HabitCategory.fitness:
        return '💪';
      case HabitCategory.productivity:
        return '⚡';
      case HabitCategory.mentalHealth:
        return '🧠';
      case HabitCategory.others:
        return '📝';
    }
  }
}

enum HabitFrequency {
  daily,
  weekly;

  String get displayName {
    switch (this) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
    }
  }
}

class HabitModel {
  final String id;
  final String userId;
  final String title;
  final HabitCategory category;
  final HabitFrequency frequency;
  final DateTime? startDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int currentStreak;
  final List<DateTime> completionHistory;

  HabitModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.frequency,
    this.startDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.currentStreak = 0,
    this.completionHistory = const [],
  });

  factory HabitModel.fromMap(Map<String, dynamic> map, String id) {
    return HabitModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      category: HabitCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => HabitCategory.others,
      ),
      frequency: HabitFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      startDate: map['startDate'] != null 
          ? DateTime.parse(map['startDate']) 
          : null,
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      currentStreak: map['currentStreak'] ?? 0,
      completionHistory: (map['completionHistory'] as List<dynamic>?)
          ?.map((date) => DateTime.parse(date))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'category': category.name,
      'frequency': frequency.name,
      'startDate': startDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'currentStreak': currentStreak,
      'completionHistory': completionHistory
          .map((date) => date.toIso8601String())
          .toList(),
    };
  }

  HabitModel copyWith({
    String? title,
    HabitCategory? category,
    HabitFrequency? frequency,
    DateTime? startDate,
    String? notes,
    int? currentStreak,
    List<DateTime>? completionHistory,
  }) {
    return HabitModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      currentStreak: currentStreak ?? this.currentStreak,
      completionHistory: completionHistory ?? this.completionHistory,
    );
  }

  bool isCompletedForDate(DateTime date) {
    return completionHistory.any((completionDate) =>
        completionDate.year == date.year &&
        completionDate.month == date.month &&
        completionDate.day == date.day);
  }

  bool canCompleteForDate(DateTime date) {
    final now = DateTime.now();
    if (date.isAfter(now)) return false;
    
    if (frequency == HabitFrequency.daily) {
      return true;
    } else {
      // Weekly frequency - check if it's the same week
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
             date.isBefore(endOfWeek.add(const Duration(days: 1)));
    }
  }
}
