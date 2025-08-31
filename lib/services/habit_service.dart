import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/habit_model.dart';

class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create a new habit
  Future<String> createHabit({
    required String userId,
    required String title,
    required HabitCategory category,
    required HabitFrequency frequency,
    DateTime? startDate,
    String? notes,
  }) async {
    try {
      final habitId = _uuid.v4();
      final habit = HabitModel(
        id: habitId,
        userId: userId,
        title: title,
        category: category,
        frequency: frequency,
        startDate: startDate,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .set(habit.toMap());

      return habitId;
    } catch (e) {
      throw Exception('Failed to create habit: $e');
    }
  }

  // Get all habits for a user
  Stream<List<HabitModel>> getUserHabits(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HabitModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get habits by category
  Stream<List<HabitModel>> getHabitsByCategory(String userId, HabitCategory category) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .where('category', isEqualTo: category.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HabitModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get a specific habit
  Future<HabitModel?> getHabit(String userId, String habitId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .get();

      if (doc.exists) {
        return HabitModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get habit: $e');
    }
  }

  // Update a habit
  Future<void> updateHabit(String userId, HabitModel habit) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habit.id)
          .update(habit.toMap());
    } catch (e) {
      throw Exception('Failed to update habit: $e');
    }
  }

  // Delete a habit
  Future<void> deleteHabit(String userId, String habitId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete habit: $e');
    }
  }

  // Mark habit as completed for a specific date
  Future<void> markHabitCompleted(String userId, String habitId, DateTime date) async {
    try {
      final habitDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .get();

      if (!habitDoc.exists) {
        throw Exception('Habit not found');
      }

      final habit = HabitModel.fromMap(habitDoc.data()!, habitDoc.id);
      
      // Check if already completed for this date
      if (habit.isCompletedForDate(date)) {
        throw Exception('Habit already completed for this date');
      }

      // Add completion date
      final updatedCompletionHistory = List<DateTime>.from(habit.completionHistory)
        ..add(date);

      // Calculate new streak
      final newStreak = _calculateStreak(updatedCompletionHistory, habit.frequency);

      // Update habit
      final updatedHabit = habit.copyWith(
        completionHistory: updatedCompletionHistory,
        currentStreak: newStreak,
      );

      await updateHabit(userId, updatedHabit);
    } catch (e) {
      throw Exception('Failed to mark habit completed: $e');
    }
  }

  // Mark habit as incomplete for a specific date
  Future<void> markHabitIncomplete(String userId, String habitId, DateTime date) async {
    try {
      final habitDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .get();

      if (!habitDoc.exists) {
        throw Exception('Habit not found');
      }

      final habit = HabitModel.fromMap(habitDoc.data()!, habitDoc.id);
      
      // Remove completion date
      final updatedCompletionHistory = habit.completionHistory
          .where((completionDate) => 
              completionDate.year != date.year ||
              completionDate.month != date.month ||
              completionDate.day != date.day)
          .toList();

      // Calculate new streak
      final newStreak = _calculateStreak(updatedCompletionHistory, habit.frequency);

      // Update habit
      final updatedHabit = habit.copyWith(
        completionHistory: updatedCompletionHistory,
        currentStreak: newStreak,
      );

      await updateHabit(userId, updatedHabit);
    } catch (e) {
      throw Exception('Failed to mark habit incomplete: $e');
    }
  }

  // Calculate streak based on completion history
  int _calculateStreak(List<DateTime> completionHistory, HabitFrequency frequency) {
    if (completionHistory.isEmpty) return 0;

    // Sort completion dates in descending order
    final sortedDates = List<DateTime>.from(completionHistory)
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    final now = DateTime.now();
    
    if (frequency == HabitFrequency.daily) {
      // Calculate daily streak
      DateTime currentDate = DateTime(now.year, now.month, now.day);
      
      for (int i = 0; i < sortedDates.length; i++) {
        final completionDate = DateTime(
          sortedDates[i].year,
          sortedDates[i].month,
          sortedDates[i].day,
        );
        
        if (i == 0) {
          // Check if the first completion is today or yesterday
          final daysDifference = currentDate.difference(completionDate).inDays;
          if (daysDifference <= 1) {
            streak = 1;
            currentDate = completionDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        } else {
          // Check if consecutive
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
      // Calculate weekly streak
      final startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
      
      for (int i = 0; i < sortedDates.length; i++) {
        final completionDate = sortedDates[i];
        final startOfCompletionWeek = completionDate.subtract(
          Duration(days: completionDate.weekday - 1),
        );
        
        if (i == 0) {
          // Check if the first completion is this week or last week
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

  // Get completion statistics for a habit
  Map<String, dynamic> getHabitStats(HabitModel habit) {
    final now = DateTime.now();
    final thisWeek = now.subtract(Duration(days: now.weekday - 1));
    final lastWeek = thisWeek.subtract(const Duration(days: 7));
    
    int thisWeekCompletions = 0;
    int lastWeekCompletions = 0;
    int totalCompletions = habit.completionHistory.length;
    
    for (final completionDate in habit.completionHistory) {
      if (completionDate.isAfter(thisWeek.subtract(const Duration(days: 1)))) {
        thisWeekCompletions++;
      } else if (completionDate.isAfter(lastWeek.subtract(const Duration(days: 1))) &&
                 completionDate.isBefore(thisWeek)) {
        lastWeekCompletions++;
      }
    }
    
    return {
      'currentStreak': habit.currentStreak,
      'thisWeekCompletions': thisWeekCompletions,
      'lastWeekCompletions': lastWeekCompletions,
      'totalCompletions': totalCompletions,
      'completionRate': totalCompletions > 0 
          ? (totalCompletions / _daysSinceCreation(habit.createdAt)) * 100 
          : 0.0,
    };
  }
  
  int _daysSinceCreation(DateTime createdAt) {
    final now = DateTime.now();
    return now.difference(createdAt).inDays + 1;
  }
}
