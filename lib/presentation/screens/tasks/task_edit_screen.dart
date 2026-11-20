import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../../data/models/task.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/sync/sync_service.dart';

class TaskEditScreen extends StatefulWidget {
  const TaskEditScreen({super.key, this.task});

  final Task? task;

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  late final TextEditingController _titleController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = context.read<TaskRepository>();
    final sync = context.read<SyncService>();
    try {
      if (_isEdit) {
        final updated = widget.task!.copyWith(
          title: _titleController.text.trim(),
          isSynced: false,
          updatedAt: DateTime.now().toUtc(),
          version: widget.task!.version + 1,
        );
        await repo.update(updated);
      } else {
        final task = Task(
          title: _titleController.text.trim(),
          isSynced: false,
        );
        await repo.create(task);
      }
      if (mounted) {
        sync.syncNow();
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit task' : 'New task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.task_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Save changes' : 'Create task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

