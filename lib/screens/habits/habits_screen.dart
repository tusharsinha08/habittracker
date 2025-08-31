import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../models/habit_model.dart';
import '../../widgets/habit_card.dart';
import 'create_habit_screen.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  HabitCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final habitProvider = Provider.of<HabitProvider>(context);

    if (authProvider.currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final habits = habitProvider.filteredHabits;
    final filteredHabits = _filterHabits(habits);

    return Scaffold(
      appBar: AppBar(
                 title: const Text(
           'My Habits',
           style: TextStyle(
             fontWeight: FontWeight.bold,
           ),
         ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(context),
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by category',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search habits...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),

          // Category Filter Chips
          if (_selectedCategory != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Filtered by: ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(_selectedCategory!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getCategoryColor(_selectedCategory!),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCategory!.icon,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedCategory!.displayName,
                          style: TextStyle(
                            color: _getCategoryColor(_selectedCategory!),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = null;
                            });
                            habitProvider.setSelectedCategory(null);
                          },
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: _getCategoryColor(_selectedCategory!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Habits List
          Expanded(
            child: filteredHabits.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredHabits.length,
                    itemBuilder: (context, index) {
                      final habit = filteredHabits[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: HabitCard(
                          habit: habit,
                          showActions: true,
                          onTap: () => _viewHabitDetails(context, habit),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewHabit(context),
        icon: const Icon(Icons.add),
        label: const Text('New Habit'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  List<HabitModel> _filterHabits(List<HabitModel> habits) {
    if (_searchQuery.isEmpty) return habits;
    
    return habits.where((habit) {
      final query = _searchQuery.toLowerCase();
      return habit.title.toLowerCase().contains(query) ||
             habit.category.displayName.toLowerCase().contains(query) ||
             (habit.notes?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedCategory != null 
                ? Icons.filter_list_off 
                : Icons.track_changes_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedCategory != null 
                ? 'No habits in ${_selectedCategory!.displayName} category'
                : 'No habits yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategory != null 
                ? 'Try creating a new habit in this category or change the filter'
                : 'Create your first habit to get started on your journey!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createNewHabit(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Habit'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...HabitCategory.values.map((category) => ListTile(
              leading: Text(
                category.icon,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(category.displayName),
              trailing: _selectedCategory == category
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
                final habitProvider = Provider.of<HabitProvider>(context, listen: false);
                habitProvider.setSelectedCategory(category);
                Navigator.of(context).pop();
              },
            )),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('All Categories'),
              trailing: _selectedCategory == null
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                setState(() {
                  _selectedCategory = null;
                });
                final habitProvider = Provider.of<HabitProvider>(context, listen: false);
                habitProvider.setSelectedCategory(null);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _createNewHabit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateHabitScreen(),
      ),
    );
  }

  void _viewHabitDetails(BuildContext context, HabitModel habit) {
    // Navigate to habit details screen
    // This will be implemented later
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
}
