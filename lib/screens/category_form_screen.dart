import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/app_state.dart';

const _palette = <Color>[
  Color(0xFF3F51B5),
  Color(0xFFE53935),
  Color(0xFF43A047),
  Color(0xFFFB8C00),
  Color(0xFF8E24AA),
  Color(0xFF00897B),
  Color(0xFFD81B60),
  Color(0xFF3949AB),
];

class CategoryFormScreen extends StatefulWidget {
  final Category? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _frontLabelController;
  late final TextEditingController _backLabelController;
  late Color _selectedColor;
  bool _saving = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _frontLabelController = TextEditingController(
      text: widget.category?.frontLabel ?? 'Palavra',
    );
    _backLabelController = TextEditingController(
      text: widget.category?.backLabel ?? 'Significado',
    );
    _selectedColor = widget.category != null
        ? Color(widget.category!.colorValue)
        : _palette[DateTime.now().millisecond % _palette.length];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _frontLabelController.dispose();
    _backLabelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    try {
      if (_isEditing) {
        await state.updateCategory(
          widget.category!.copyWith(
            name: _nameController.text.trim(),
            frontLabel: _frontLabelController.text.trim(),
            backLabel: _backLabelController.text.trim(),
            colorValue: _selectedColor.toARGB32(),
          ),
        );
      } else {
        await state.addCategory(
          name: _nameController.text.trim(),
          frontLabel: _frontLabelController.text.trim(),
          backLabel: _backLabelController.text.trim(),
          colorValue: _selectedColor.toARGB32(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar biblioteca' : 'Nova biblioteca'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da biblioteca',
                hintText: 'Ex: Libras, Inglês, Japonês',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _frontLabelController,
                    decoration: const InputDecoration(
                      labelText: 'Rótulo da frente',
                      hintText: 'Ex: Sinal, Palavra',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _backLabelController,
                    decoration: const InputDecoration(
                      labelText: 'Rótulo do verso',
                      hintText: 'Ex: Significado',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Esses rótulos aparecem nos cartões. Por exemplo, para Libras: '
              '"Sinal" e "Significado". Para inglês: "Inglês" e "Português".',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Text('Cor', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final color in _palette)
                  GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: 20,
                      child: _selectedColor.toARGB32() == color.toARGB32()
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
