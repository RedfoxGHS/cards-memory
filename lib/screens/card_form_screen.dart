import 'dart:io';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/flashcard.dart';
import '../providers/app_state.dart';

class CardFormScreen extends StatefulWidget {
  final Category category;
  final Flashcard? card;

  const CardFormScreen({super.key, required this.category, this.card});

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _frontController;
  late final TextEditingController _backController;

  File? _newFrontImage;
  bool _removeFrontImage = false;
  File? _newBackImage;
  bool _removeBackImage = false;

  bool _saving = false;

  bool get _isEditing => widget.card != null;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.card?.frontText);
    _backController = TextEditingController(text: widget.card?.backText);
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isFront}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (!kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS))
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tirar foto'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      if (isFront) {
        _newFrontImage = File(picked.path);
        _removeFrontImage = false;
      } else {
        _newBackImage = File(picked.path);
        _removeBackImage = false;
      }
    });
  }

  void _clearImage({required bool isFront}) {
    setState(() {
      if (isFront) {
        _newFrontImage = null;
        _removeFrontImage = true;
      } else {
        _newBackImage = null;
        _removeBackImage = true;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    try {
      if (_isEditing) {
        await state.updateFlashcard(
          widget.card!,
          frontText: _frontController.text.trim(),
          newFrontImage: _newFrontImage,
          removeFrontImage: _removeFrontImage,
          backText: _backController.text.trim(),
          newBackImage: _newBackImage,
          removeBackImage: _removeBackImage,
        );
      } else {
        await state.addFlashcard(
          categoryId: widget.category.id!,
          frontText: _frontController.text.trim(),
          frontImage: _newFrontImage,
          backText: _backController.text.trim(),
          backImage: _newBackImage,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar cartão' : 'Novo cartão'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              category.frontLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _frontController,
              decoration: InputDecoration(
                labelText: category.frontLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            _ImagePickerField(
              existingPath: _removeFrontImage ? null : widget.card?.frontImagePath,
              newFile: _newFrontImage,
              onPick: () => _pickImage(isFront: true),
              onClear: () => _clearImage(isFront: true),
            ),
            const SizedBox(height: 28),
            Text(
              category.backLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _backController,
              decoration: InputDecoration(
                labelText: category.backLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            _ImagePickerField(
              existingPath: _removeBackImage ? null : widget.card?.backImagePath,
              newFile: _newBackImage,
              onPick: () => _pickImage(isFront: false),
              onClear: () => _clearImage(isFront: false),
              label: 'Foto (opcional)',
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

class _ImagePickerField extends StatelessWidget {
  final String? existingPath;
  final File? newFile;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final String label;

  const _ImagePickerField({
    required this.existingPath,
    required this.newFile,
    required this.onPick,
    required this.onClear,
    this.label = 'Foto do sinal (opcional)',
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = newFile != null || existingPath != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  newFile ?? File(existingPath!),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton.filledTonal(
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        if (hasImage)
          TextButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.refresh),
            label: const Text('Trocar foto'),
          ),
      ],
    );
  }
}
