import 'package:flutter/material.dart';

class AddAppSheet extends StatefulWidget {
  final String? initialName;
  final String? initialPackage;
  final int? initialLimit;
  final Future<void> Function(String name, String package, int limit) onAdd;

  const AddAppSheet({
    super.key,
    this.initialName,
    this.initialPackage,
    this.initialLimit,
    required this.onAdd,
  });

  @override
  State<AddAppSheet> createState() => _AddAppSheetState();
}

class _AddAppSheetState extends State<AddAppSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _packageController;
  late int _limit;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _packageController = TextEditingController(text: widget.initialPackage ?? '');
    _limit = widget.initialLimit ?? 60;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _packageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initialName == null ? 'Add blocked app' : 'Edit app',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'App name',
                hintText: 'e.g. Instagram',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _packageController,
              decoration: const InputDecoration(
                labelText: 'Package name',
                hintText: 'e.g. com.instagram.android',
              ),
              autocorrect: false,
              enabled: widget.initialPackage == null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _limit,
              decoration: const InputDecoration(
                labelText: 'Daily limit (minutes)',
              ),
              items: [15, 30, 60, 90, 120, 180].map((v) {
                return DropdownMenuItem(
                  value: v,
                  child: Text('$v min'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _limit = v ?? 60),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.initialName == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final package = _packageController.text.trim();
    if (name.isEmpty || package.isEmpty) return;
    setState(() => _isLoading = true);
    await widget.onAdd(name, package, _limit);
    if (mounted) setState(() => _isLoading = false);
  }
}
