import 'dart:io';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/flashcard.dart';
import '../models/libras_entry.dart';
import '../providers/app_state.dart';
import '../widgets/video_preview.dart';

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

  // Libras dictionary flow. The sign (video + image) is the answer, so it
  // lives on the back side; the front side is just the word being quizzed.
  String? _newBackImagePath;
  String? _newBackVideoPath;
  bool _removeBackVideo = false;
  bool _librasBusy = false;
  String? _librasError;
  bool _manualFallback = false;

  bool _saving = false;

  bool get _isEditing => widget.card != null;
  bool get _isLibras => widget.category.isLibras;

  String? get _backVideoPath =>
      _removeBackVideo ? null : (_newBackVideoPath ?? widget.card?.backVideoPath);
  String? get _backSignImagePath =>
      _removeBackImage ? null : (_newBackImagePath ?? widget.card?.backImagePath);

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

  Future<void> _searchLibras() async {
    final word = _frontController.text.trim();
    if (word.isEmpty) return;
    setState(() {
      _librasBusy = true;
      _librasError = null;
    });
    final state = context.read<AppState>();
    try {
      var entry = await state.rememberedLibrasChoice(word);
      entry ??= await _resolveEntry(state, word);
      if (entry == null) return;
      await _applyLibrasEntry(entry);
    } catch (e) {
      setState(() => _librasError = 'Erro ao consultar o dicionário: $e');
    } finally {
      if (mounted) setState(() => _librasBusy = false);
    }
  }

  Future<LibrasEntry?> _resolveEntry(AppState state, String word) async {
    final matches = await state.findLibrasMatches(word);
    if (matches.isEmpty) {
      setState(() {
        _librasError = 'Palavra não encontrada no dicionário do INES.';
      });
      return null;
    }
    LibrasEntry entry;
    if (matches.length == 1) {
      entry = matches.first;
    } else {
      final picked = await _pickLibrasVariant(matches, state);
      if (picked == null) return null;
      entry = picked;
    }
    await state.rememberLibrasChoice(word, entry);
    return entry;
  }

  Future<LibrasEntry?> _pickLibrasVariant(
    List<LibrasEntry> matches,
    AppState state,
  ) {
    return showDialog<LibrasEntry>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mais de um sinal encontrado'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final entry = matches[index];
              final imageUrl = state.librasImageUrl(entry);
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      imageUrl != null ? NetworkImage(imageUrl) : null,
                  child: imageUrl == null
                      ? const Icon(Icons.sign_language_outlined)
                      : null,
                ),
                title: Text(entry.palavra),
                subtitle: Text(
                  entry.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.of(context).pop(entry),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyLibrasEntry(LibrasEntry entry) async {
    setState(() => _librasBusy = true);
    try {
      final state = context.read<AppState>();
      final media = await state.downloadLibrasMedia(entry);
      if (!mounted) return;
      setState(() {
        _newBackVideoPath = media.videoPath;
        _removeBackVideo = false;
        _newBackImagePath = media.imagePath;
        _removeBackImage = false;
        _frontController.text = entry.palavra;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _librasError = 'Erro ao baixar o sinal: $e');
      }
    } finally {
      if (mounted) setState(() => _librasBusy = false);
    }
  }

  void _clearLibrasMedia() {
    setState(() {
      _newBackVideoPath = null;
      _removeBackVideo = true;
      _newBackImagePath = null;
      _removeBackImage = true;
      _librasError = null;
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
          newBackImagePath: _newBackImagePath,
          removeBackImage: _removeBackImage,
          newBackVideoPath: _newBackVideoPath,
          removeBackVideo: _removeBackVideo,
        );
      } else {
        await state.addFlashcard(
          categoryId: widget.category.id!,
          frontText: _frontController.text.trim(),
          frontImage: _newFrontImage,
          backText: _backController.text.trim(),
          backImage: _newBackImage,
          backImagePath: _newBackImagePath,
          backVideoPath: _newBackVideoPath,
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
            if (_isLibras) ...[
              _buildLibrasWordField(),
            ] else ...[
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
            ],
            const SizedBox(height: 28),
            Text(
              category.backLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_isLibras) ...[
              _buildLibrasSignField(),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _backController,
              decoration: InputDecoration(
                labelText: _isLibras
                    ? '${category.backLabel} (opcional)'
                    : category.backLabel,
                border: const OutlineInputBorder(),
              ),
              validator: _isLibras
                  ? null
                  : (v) => (v == null || v.trim().isEmpty)
                      ? 'Obrigatório'
                      : null,
              textCapitalization: TextCapitalization.sentences,
              maxLines: _isLibras ? 3 : 1,
            ),
            if (!_isLibras) ...[
              const SizedBox(height: 12),
              _ImagePickerField(
                existingPath: _removeBackImage ? null : widget.card?.backImagePath,
                newFile: _newBackImage,
                onPick: () => _pickImage(isFront: false),
                onClear: () => _clearImage(isFront: false),
                label: 'Foto (opcional)',
              ),
            ],
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

  /// Front side for Libras cards: just the word being quizzed — no sign
  /// media here, so practicing "Normal" mode never gives the answer away.
  Widget _buildLibrasWordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _frontController,
                decoration: const InputDecoration(
                  labelText: 'Palavra (em português)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                textCapitalization: TextCapitalization.sentences,
                onFieldSubmitted: (_) => _searchLibras(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: _librasBusy ? null : _searchLibras,
              icon: _librasBusy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: const Text('Buscar'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Busca o sinal no Dicionário de Libras do INES e salva o vídeo '
          'localmente, como resposta do cartão.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (_librasError != null) ...[
          const SizedBox(height: 8),
          Text(
            _librasError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            onPressed: () => setState(() => _manualFallback = true),
            child: const Text('Adicionar foto manualmente'),
          ),
        ],
      ],
    );
  }

  /// Back side for Libras cards: the resolved sign (video/image) — the
  /// actual answer revealed when the card is flipped.
  Widget _buildLibrasSignField() {
    final videoPath = _backVideoPath;
    final imagePath = _backSignImagePath;
    final hasMedia = videoPath != null || imagePath != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasMedia)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: videoPath != null
                      ? VideoPreview(path: videoPath)
                      : Image.file(File(imagePath!), fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton.filledTonal(
                  onPressed: _clearLibrasMedia,
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          )
        else if (_manualFallback)
          _ImagePickerField(
            existingPath: _removeBackImage ? null : widget.card?.backImagePath,
            newFile: _newBackImage,
            onPick: () => _pickImage(isFront: false),
            onClear: () => _clearImage(isFront: false),
            label: 'Foto do sinal (opcional)',
          )
        else
          Text(
            'Busque a palavra acima para preencher o sinal automaticamente.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
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
