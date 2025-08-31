import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/habit_model.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';

class HabitCard extends StatelessWidget {
  final HabitModel habit;
  final bool showActions;
  final bool isCompact;
  final VoidCallback? onTap;

  const HabitCard({
    super.key,
    required this.habit,
    this.showActions = true,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final isCompletedToday = habit.isCompletedForDate(today);
    final canCompleteToday = habit.canCompleteForDate(today);

    return Slidable(
      endActionPane: showActions
          ? ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) => _editHabit(context),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  icon: Icons.edit,
                  label: 'Edit',
                ),
                SlidableAction(
                  onPressed: (_) => _deleteHabit(context),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            )
          : null,
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(habit.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      habit.category.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Habit Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Category
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              habit.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: isCompletedToday 
                                    ? TextDecoration.lineThrough 
                                    : null,
                                color: isCompletedToday 
                                    ? theme.colorScheme.onSurface.withOpacity(0.6)
                                    : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCompact) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(habit.category).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                habit.category.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _getCategoryColor(habit.category),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      if (!isCompact) ...[
                        const SizedBox(height: 4),
                        Text(
                          habit.category.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 8),
                      
                      // Frequency and Streak
                      Row(
                        children: [
                          Icon(
                            habit.frequency == HabitFrequency.daily 
                                ? Icons.calendar_today 
                                : Icons.calendar_view_week,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            habit.frequency.displayName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${habit.currentStreak} day${habit.currentStreak != 1 ? 's' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      if (habit.notes?.isNotEmpty == true && !isCompact) ...[
                        const SizedBox(height: 8),
                        Text(
                          habit.notes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Completion Toggle
                if (showActions && canCompleteToday)
                  GestureDetector(
                    onTap: () => _toggleCompletion(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompletedToday 
                            ? Colors.green 
                            : theme.colorScheme.outline.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCompletedToday 
                              ? Colors.green 
                              : theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        isCompletedToday ? Icons.check : Icons.add,
                        size: 20,
                        color: isCompletedToday 
                            ? Colors.white 
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return Colors.green;
      case HabitCategory.study:
        return Colors.blue;
      case HabitCategory.fitness:
        return Colors.orange;
      case HabitCategory.productivity:
        return Colors.purple;
      case HabitCategory.mentalHealth:
        return Colors.teal;
      case HabitCategory.others:
        return Colors.grey;
    }
  }

  void _toggleCompletion(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) return;
    
    final today = DateTime.now();
    final isCompletedToday = habit.isCompletedForDate(today);
    
    if (isCompletedToday) {
      habitProvider.markHabitIncomplete(
        authProvider.currentUser!.uid,
        habit.id,
        today,
      );
    } else {
      habitProvider.markHabitCompleted(
        authProvider.currentUser!.uid,
        habit.id,
        today,
      );
    }
  }

  void _editHabit(BuildContext context) {
    // Navigate to edit habit screen
    // This will be implemented later
  }

  void _deleteHabit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDeleteHabit(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteHabit(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) return;
    
    habitProvider.deleteHabit(
      authProvider.currentUser!.uid,
      habit.id,
    );
  }
}
