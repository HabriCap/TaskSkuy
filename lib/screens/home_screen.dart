import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import 'login_screen.dart';
import 'task_form_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.username});

  final String username;

  Future<void> _logout(BuildContext context) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('loginData', false);
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _showTaskForm(BuildContext context, {Task? task}) async {
    final updatedTask = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => TaskFormSheet(task: task),
    );
    if (updatedTask == null) return;

    final box = Hive.box<Task>('tasks');
    if (task == null) {
      await box.add(updatedTask);
    } else {
      task
        ..title = updatedTask.title
        ..description = updatedTask.description
        ..isCompleted = updatedTask.isCompleted;
      await task.save();
    }
  }

  Future<void> _deleteTask(BuildContext context, Task task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus tugas?'),
        content: Text('Tugas "${task.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await task.delete();
    }
  }

  Future<void> _toggleTask(Task task, bool isCompleted) async {
    task.isCompleted = isCompleted;
    await task.save();
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Task>('tasks');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TaskSkuy!',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Box<Task>>(
          valueListenable: box.listenable(),
          builder: (context, taskBox, child) {
            final tasks = taskBox.values.toList();
            final completedCount = tasks
                .where((task) => task.isCompleted)
                .length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $username',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tasks.isEmpty
                            ? 'Yuk, rencanakan hal baik hari ini.'
                            : '$completedCount dari ${tasks.length} tugas selesai',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: Colors.blueGrey.shade600),
                      ),
                      if (tasks.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: completedCount / tasks.length,
                            backgroundColor: const Color(0xFFDCE8E6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Daftar tugas',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: tasks.isEmpty
                      ? _EmptyTasks(onAdd: () => _showTaskForm(context))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: tasks.length,
                          separatorBuilder: (context, index) {
                            return const SizedBox(height: 10);
                          },
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return _TaskCard(
                              task: task,
                              onToggle: (value) {
                                _toggleTask(task, value ?? false);
                              },
                              onEdit: () {
                                _showTaskForm(context, task: task);
                              },
                              onDelete: () {
                                _deleteTask(context, task);
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah tugas'),
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_note_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada tugas',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan tugas pertamamu dan mulai produktif hari ini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat tugas'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      decoration: task.isCompleted
          ? TextDecoration.lineThrough
          : TextDecoration.none,
      color: task.isCompleted ? Colors.blueGrey.shade400 : null,
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE9EEF2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: onToggle,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: titleStyle),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        task.description,
                        style: TextStyle(color: Colors.blueGrey.shade600),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      task.isCompleted ? 'Selesai' : 'Belum selesai',
                      style: TextStyle(
                        color: task.isCompleted
                            ? Theme.of(context).colorScheme.primary
                            : Colors.blueGrey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Aksi tugas',
              onSelected: (action) {
                if (action == 'edit') onEdit();
                if (action == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Ubah'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline_rounded),
                    title: Text('Hapus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
