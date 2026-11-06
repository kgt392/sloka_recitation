import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/sloka.dart';
import '../services/audio_import.dart';
import '../services/storage_service.dart';

class AddEditSlokaScreen extends StatefulWidget {
  final Sloka? sloka;
  const AddEditSlokaScreen({super.key, this.sloka});

  @override
  State<AddEditSlokaScreen> createState() => _AddEditSlokaScreenState();
}

class _AddEditSlokaScreenState extends State<AddEditSlokaScreen> {
  final StorageService _storage = StorageService.instance;
  final AudioImport _audioImport = AudioImport.instance;
  final AudioPlayer _previewPlayer = AudioPlayer();

  late final TextEditingController _titleController;
  late final TextEditingController _textController;

  String? _audioPath;
  bool _isRecording = false;
  Timer? _recordTimer;
  int _recordSeconds = 0;

  bool _isPreviewPlaying = false;
  StreamSubscription? _previewSubscription;

  bool get _isEdit => widget.sloka != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.sloka?.title ?? '');
    _textController = TextEditingController(text: widget.sloka?.text ?? '');
    _audioPath = widget.sloka?.audioPath;

    _previewSubscription = _previewPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPreviewPlaying = state == PlayerState.playing;
        });
      }
    });

    _previewPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _isPreviewPlaying = false);
      }
    });
  }

  Future<void> _pasteText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _textController.text = data.text!;
      });
    }
  }

  Future<void> _startRecording() async {
    final ok = await _audioImport.startRecording();
    if (ok && mounted) {
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordSeconds++);
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    final path = await _audioImport.stopRecording();
    if (mounted) {
      setState(() {
        _isRecording = false;
        if (path != null) {
          _audioPath = path;
        }
      });
    }
  }

  Future<void> _uploadAudio() async {
    final path = await _audioImport.pickAudioFile();
    if (path != null && mounted) {
      setState(() {
        _audioPath = path;
      });
    }
  }

  Future<void> _togglePreview() async {
    if (_audioPath == null) return;
    if (_isPreviewPlaying) {
      await _previewPlayer.pause();
    } else {
      await _previewPlayer.play(DeviceFileSource(_audioPath!));
    }
  }

  void _removeAudio() {
    _previewPlayer.stop();
    setState(() {
      _audioPath = null;
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final text = _textController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the sloka text')),
      );
      return;
    }

    final finalTitle = title.isEmpty ? 'Untitled Sloka' : title;

    try {
      if (_isEdit) {
        final updated = widget.sloka!.copyWith(
          title: finalTitle,
          text: text,
          audioPath: _audioPath,
          clearAudio: _audioPath == null,
        );
        await _storage.updateSloka(updated);
      } else {
        final newSloka = Sloka(
          id: const Uuid().v4(),
          title: finalTitle,
          text: text,
          audioPath: _audioPath,
        );
        await _storage.addSloka(newSloka);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save sloka. Please try again.')),
      );
    }
  }

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _previewSubscription?.cancel();
    _previewPlayer.dispose();
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Sloka' : 'Add Sloka'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              _isEdit ? 'Update' : 'Save',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title input
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Bhagavad Gita 2.13',
                prefixIcon: Icon(Icons.bookmark_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Sloka text input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sloka Text',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.content_paste, size: 16),
                      label: const Text('Paste'),
                      onPressed: _pasteText,
                    ),
                  ],
                ),
                TextField(
                  controller: _textController,
                  maxLines: 6,
                  style: const TextStyle(
                    fontFamily: 'Noto Serif',
                    fontSize: 16,
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter Sanskrit or transliterated sloka verses...',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Audio recitation section
            Text(
              'Recitation Audio',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  if (_audioPath != null) ...[
                    // Attached audio preview row
                    Row(
                      children: [
                        IconButton.filledTonal(
                          icon: Icon(
                            _isPreviewPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          onPressed: _togglePreview,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Audio attached',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: colorScheme.error),
                          tooltip: 'Remove audio',
                          onPressed: _removeAudio,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                  ],

                  if (_isRecording) ...[
                    // Live recording row
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colorScheme.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recording: ${_fmt(_recordSeconds)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.error,
                            ),
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop Recording'),
                            onPressed: _stopRecording,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Buttons to Record or Upload
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.mic),
                            label: Text(_audioPath == null ? 'Record' : 'Replace (Mic)'),
                            onPressed: _startRecording,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.upload_file),
                            label: Text(_audioPath == null ? 'Upload' : 'Replace (File)'),
                            onPressed: _uploadAudio,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  _isEdit ? 'Update Sloka' : 'Save Sloka',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
