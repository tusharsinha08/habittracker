import 'package:flutter/material.dart';
import '../models/habit_model.dart';
import '../services/habit_service.dart';

class HabitProvider extends ChangeNotifier {
  final HabitService _habitService = HabitService();
  
  List<HabitModel> _habits = [];
  HabitCategory? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<HabitModel> get habits => _habits;
  HabitCategory? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get habits filtered by selected category
  List<HabitModel> get filteredHabits {
    if (_selectedCategory == null) return _habits;
    return _habits.where((habit) => habit.category == _selectedCategory).toList();
  }

  // Get habits for today
  List<HabitModel> get todayHabits {
    final today = DateTime.now();
    return _habits.where((habit) => habit.canCompleteForDate(today)).toList();
  }

  // Get habits for current week
  List<HabitModel> get weekHabits {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return _habits.where((habit) {
      if (habit.frequency == HabitFrequency.daily) {
        return true; // Daily habits can be completed any day
      } else {
        // Weekly habits - check if it's the current week
        return habit.startDate == null || 
               (habit.startDate!.isBefore(endOfWeek.add(const Duration(days: 1))) &&
               habit.startDate!.isAfter(startOfWeek.subtract(const Duration(days: 1))));
      }
    }).toList();
  }

  // Set selected category filter
  void setSelectedCategory(HabitCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Load habits for a user
  void loadHabits(String userId) {
    _habitService.getUserHabits(userId).listen(
      (habits) {
        _habits = habits;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Create a new habit
  Future<bool> createHabit({
    required String userId,
    required String title,
    required HabitCategory category,
    required HabitFrequency frequency,
    DateTime? startDate,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _habitService.createHabit(
        userId: userId,
        title: title,
        category: category,
        frequency: frequency,
        startDate: startDate,
        notes: notes,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update a habit
  Future<bool> updateHabit(String userId, HabitModel habit) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _habitService.updateHabit(userId, habit);

      // Update local habit list
      final index = _habits.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        _habits[index] = habit;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete a habit
  Future<bool> deleteHabit(String userId, String habitId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _habitService.deleteHabit(userId, habitId);

      // Remove from local habit list
      _habits.removeWhere((habit) => habit.id == habitId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark habit as completed
  Future<bool> markHabitCompleted(String userId, String habitId, DateTime date) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _habitService.markHabitCompleted(userId, habitId, date);

      // Update local habit
      final index = _habits.indexWhere((habit) => habit.id == habitId);
      if (index != -1) {
        final habit = _habits[index];
        final updatedCompletionHistory = List<DateTime>.from(habit.completionHistory)..add(date);
        final newStreak = _calculateStreak(updatedCompletionHistory, habit.frequency);
        
        _habits[index] = habit.copyWith(
          completionHistory: updatedCompletionHistory,
          currentStreak: newStreak,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark habit as incomplete
  Future<bool> markHabitIncomplete(String userId, String habitId, DateTime date) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _habitService.markHabitIncomplete(userId, habitId, date);

      // Update local habit
      final index = _habits.indexWhere((habit) => habit.id == habitId);
      if (index != -1) {
        final habit = _habits[index];
        final updatedCompletionHistory = habit.completionHistory
            .where((completionDate) => 
                completionDate.year != date.year ||
                completionDate.month != date.month ||
                completionDate.day != date.day)
            .toList();
        final newStreak = _calculateStreak(updatedCompletionHistory, habit.frequency);
        
        _habits[index] = habit.copyWith(
          completionHistory: updatedCompletionHistory,
          currentStreak: newStreak,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get habit statistics
  Map<String, dynamic> getHabitStats(HabitModel habit) {
    return _habitService.getHabitStats(habit);
  }

  // Get overall progress statistics
  Map<String, dynamic> getOverallStats() {
    if (_habits.isEmpty) {
      return {
        'totalHabits': 0,
        'completedToday': 0,
        'totalStreak': 0,
        'completionRate': 0.0,
      };
    }

    final today = DateTime.now();
    int completedToday = 0;
    int totalStreak = 0;

    for (final habit in _habits) {
      if (habit.isCompletedForDate(today)) {
        completedToday++;
      }
      totalStreak += habit.currentStreak;
    }

    final totalHabits = _habits.length;
    final completionRate = (completedToday / totalHabits) * 100;

    return {
      'totalHabits': totalHabits,
      'completedToday': completedToday,
      'totalStreak': totalStreak,
      'completionRate': completionRate,
    };
  }

  // Get habits by category with completion stats
  Map<HabitCategory, Map<String, dynamic>> getCategoryStats() {
    final Map<HabitCategory, Map<String, dynamic>> categoryStats = {};
    
    for (final category in HabitCategory.values) {
      final categoryHabits = _habits.where((habit) => habit.category == category).toList();
      
      if (categoryHabits.isNotEmpty) {
        int totalHabits = categoryHabits.length;
        int completedToday = 0;
        int totalStreak = 0;
        
        for (final habit in categoryHabits) {
          if (habit.isCompletedForDate(DateTime.now())) {
            completedToday++;
          }
          totalStreak += habit.currentStreak;
        }
        
        categoryStats[category] = {
          'totalHabits': totalHabits,
          'completedToday': completedToday,
          'totalStreak': totalStreak,
          'completionRate': (completedToday / totalHabits) * 100,
        };
      }
    }
    
    return categoryStats;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Calculate streak (simplified version for local updates)
  int _calculateStreak(List<DateTime> completionHistory, HabitFrequency frequency) {
    if (completionHistory.isEmpty) return 0;

    final sortedDates = List<DateTime>.from(completionHistory)
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    final now = DateTime.now();
    
    if (frequency == HabitFrequency.daily) {
      DateTime currentDate = DateTime(now.year, now.month, now.day);
      
      for (int i = 0; i < sortedDates.length; i++) {
        final completionDate = DateTime(
          sortedDates[i].year,
          sortedDates[i].month,
          sortedDates[i].day,
        );
        
        if (i == 0) {
          final daysDifference = currentDate.difference(completionDate).inDays;
          if (daysDifference <= 1) {
            streak = 1;
            currentDate = completionDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        } else {
          final expectedDate = currentDate.add(const Duration(days: 1));
          if (completionDate.isAtSameMomentAs(expectedDate)) {
            streak++;
            currentDate = expectedDate;
          } else {
            break;
          }
        }
      }
    } else {
      // Weekly frequency calculation
      final startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
      
      for (int i = 0; i < sortedDates.length; i++) {
        final completionDate = sortedDates[i];
        final startOfCompletionWeek = completionDate.subtract(
          Duration(days: completionDate.weekday - 1),
        );
        
        if (i == 0) {
          final weeksDifference = startOfCurrentWeek.difference(startOfCompletionWeek).inDays ~/ 7;
          if (weeksDifference <= 1) {
            streak = 1;
            // For weekly, we track weeks, not individual dates
            continue;
          } else {
            break;
          }
        } else {
          // For weekly, check if consecutive weeks
          final previousWeek = sortedDates[i - 1].subtract(
            Duration(days: sortedDates[i - 1].weekday - 1),
          );
          final currentWeek = startOfCompletionWeek;
          final weekDifference = currentWeek.difference(previousWeek).inDays;
          
          if (weekDifference == 7) {
            streak++;
          } else {
            break;
          }
        }
      }
    }

    return streak;
  }
}
