import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/stats_card.dart';
import '../../models/habit_model.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _selectedTimeframe = 'week'; // week, month, year

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final habitProvider = Provider.of<HabitProvider>(context);

    if (authProvider.currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final overallStats = habitProvider.getOverallStats();
    final categoryStats = habitProvider.getCategoryStats();

    return Scaffold(
      appBar: AppBar(
                 title: const Text(
           'Progress & Analytics',
           style: TextStyle(
             fontWeight: FontWeight.bold,
           ),
         ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedTimeframe = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'week',
                child: Text('This Week'),
              ),
              const PopupMenuItem(
                value: 'month',
                child: Text('This Month'),
              ),
              const PopupMenuItem(
                value: 'year',
                child: Text('This Year'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getTimeframeText(_selectedTimeframe),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Progress Section
                         Text(
               'Overall Progress',
               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                 fontWeight: FontWeight.bold,
               ),
             ),
            const SizedBox(height: 16),
            
            // Overall Stats Cards
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Total Habits',
                    value: overallStats['totalHabits'].toString(),
                    icon: Icons.track_changes,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: 'Completion Rate',
                    value: '${overallStats['completionRate'].toStringAsFixed(1)}%',
                    icon: Icons.analytics,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Total Streak',
                    value: overallStats['totalStreak'].toString(),
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: 'Completed Today',
                    value: '${overallStats['completedToday']}/${overallStats['totalHabits']}',
                    icon: Icons.check_circle,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Progress Chart Section
                         Text(
               'Progress Over Time',
               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                 fontWeight: FontWeight.bold,
               ),
             ),
            const SizedBox(height: 16),
            
            // Progress Chart
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: _buildProgressChart(),
            ),
            
            const SizedBox(height: 32),
            
            // Category Progress Section
                         Text(
               'Progress by Category',
               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                 fontWeight: FontWeight.bold,
               ),
             ),
            const SizedBox(height: 16),
            
            // Category Progress Cards
            ...categoryStats.entries.map((entry) {
              final category = entry.key;
              final stats = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProgressStatsCard(
                  title: category.displayName,
                  value: '${stats['completedToday']}/${stats['totalHabits']}',
                  subtitle: 'Completed today',
                  progress: stats['totalHabits'] > 0 
                      ? stats['completedToday'] / stats['totalHabits']
                      : 0.0,
                  icon: _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                ),
              );
            }).toList(),
            
            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    // This is a placeholder chart - you would implement actual data here
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: const TextStyle(fontSize: 12),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 60),
              const FlSpot(1, 80),
              const FlSpot(2, 70),
              const FlSpot(3, 90),
              const FlSpot(4, 85),
              const FlSpot(5, 95),
              const FlSpot(6, 88),
            ],
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 100,
      ),
    );
  }

  String _getTimeframeText(String timeframe) {
    switch (timeframe) {
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'year':
        return 'This Year';
      default:
        return 'This Week';
    }
  }

  IconData _getCategoryIcon(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return Icons.health_and_safety;
      case HabitCategory.study:
        return Icons.school;
      case HabitCategory.fitness:
        return Icons.fitness_center;
      case HabitCategory.productivity:
        return Icons.work;
      case HabitCategory.mentalHealth:
        return Icons.psychology;
      case HabitCategory.others:
        return Icons.more_horiz;
    }
    return Icons.more_horiz; // Default fallback
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
    return Colors.grey; // Default fallback
  }
}
