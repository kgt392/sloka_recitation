import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/sloka.dart';
import '../services/audio_import.dart';
import '../services/storage_service.dart';
import '../widgets/sloka_highlight.dart';
import 'add_edit_sloka_screen.dart';

class SlokaDetailScreen extends StatefulWidget {
  final String slokaId;
  const SlokaDetailScreen({super.key, required this.slokaId});

  @override
  State<SlokaDetailScreen> createState() => _SlokaDetailScreenState();
}

class _SlokaDetailScreenState extends State<SlokaDetailScreen> {
  final StorageService _storage = StorageService.instance;
  final AudioImport _audioImport = AudioImport.instance;
  final AudioPlayer _player = AudioPlayer();

  Sloka? _sloka;
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _isFocusView = false;
  bool _isRepeatOne = false;
  double _playbackRate = 1.0;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;

  // Recording state in detail screen
  bool _isRecording = false;
  Timer? _recordTimer;
  int _recordSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadSloka();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _durationSubscription = _player.onDurationChanged.listen((dur) {
      if (mounted) {
        setState(() => _duration = dur);
      }
    });

    _positionSubscription = _player.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    _player.onPlayerComplete.listen((_) async {
      if (_isRepeatOne) {
        await _player.seek(Duration.zero);
        await _player.resume();
      } else {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      }
    });
  }

  Future<void> _loadSloka() async {
    final slokas = await _storage.loadSlokas();
    final match = slokas.cast<Sloka?>().firstWhere(
          (s) => s != null && s.id == widget.slokaId,
          orElse: () => null,
        );
    if (mounted) {
      setState(() {
        _sloka = match;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (_sloka == null || !_sloka!.hasAudio) return;

    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        final path = _sloka!.audioPath!;
        final file = File(path);
        if (!await file.exists()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio file could not be found.')),
          );
          return;
        }
        await _player.setPlaybackRate(_playbackRate);
        if (_position >= _duration && _duration > Duration.zero) {
          await _player.seek(Duration.zero);
        }
        await _player.play(DeviceFileSource(path));
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing sloka: $e')),
      );
    }
  }

  Future<void> _startFromBeginning() async {
    await _player.seek(Duration.zero);
    if (!_isPlaying) {
      _togglePlayback();
    }
  }

  Future<void> _seek(double value) async {
    final target = Duration(milliseconds: value.toInt());
    await _player.seek(target);
  }

  void _cycleLoop() {
    setState(() {
      _isRepeatOne = !_isRepeatOne;
    });
  }

  void _setRate() {
    final rates = [0.75, 1.0, 1.25, 1.5];
    final currentIndex = rates.indexOf(_playbackRate);
    final nextIndex = (currentIndex + 1) % rates.length;
    setState(() {
      _playbackRate = rates[nextIndex];
    });
    if (_isPlaying) {
      _player.setPlaybackRate(_playbackRate);
    }
  }

  Future<void> _uploadAudio() async {
    final path = await _audioImport.pickAudioFile();
    if (path != null && _sloka != null) {
      final updated = _sloka!.copyWith(audioPath: path);
      await _storage.updateSloka(updated);
      _loadSloka();
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
      setState(() => _isRecording = false);
      if (path != null && _sloka != null) {
        final updated = _sloka!.copyWith(audioPath: path);
        await _storage.updateSloka(updated);
        _loadSloka();
      }
    }
  }

  Future<void> _deleteAudio() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove audio'),
        content: const Text('Remove the audio for this sloka?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && _sloka != null) {
      await _player.stop();
      await _audioImport.deleteAudioFile(_sloka!.audioPath);
      final updated = _sloka!.copyWith(clearAudio: true);
      await _storage.updateSloka(updated);
      _loadSloka();
    }
  }

  Future<void> _edit() async {
    if (_sloka == null) return;
    await _player.stop();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditSlokaScreen(sloka: _sloka),
      ),
    );
    _loadSloka();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (_duration.inMilliseconds > 0) {
      return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_sloka == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Sloka not found')),
      );
    }

    // FOCUS VIEW: Fullscreen recitation mode
    if (_isFocusView) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1712), // Deep devotional dark
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.fullscreen_exit),
            onPressed: () => setState(() => _isFocusView = false),
          ),
          title: Text(
            _sloka!.title,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Noto Serif',
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: HighlightedSlokaText(
                      text: _sloka!.text,
                      progress: _progress,
                      isPlaying: _isPlaying,
                      fontSize: 24.0,
                      isFocusView: true,
                    ),
                  ),
                ),
              ),
              if (_sloka!.hasAudio) _buildPlayerControls(isDark: true),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_sloka!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen),
            tooltip: 'Focus Mode',
            onPressed: () => setState(() => _isFocusView = true),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Sloka',
            onPressed: _edit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header Block
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                _sloka!.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Noto Serif',
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),

            // Sacred Verse Text Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: HighlightedSlokaText(
                text: _sloka!.text,
                progress: _progress,
                isPlaying: _isPlaying,
                fontSize: 19.0,
              ),
            ),

            // Player Section or No Audio Section
            if (_sloka!.hasAudio) ...[
              _buildPlayerCard(),
              _buildAudioSourceCard(),
            ] else
              _buildNoAudioCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Slider and time
            Slider(
              value: _position.inMilliseconds
                  .toDouble()
                  .clamp(0.0, _duration.inMilliseconds.toDouble()),
              max: _duration.inMilliseconds > 0
                  ? _duration.inMilliseconds.toDouble()
                  : 1.0,
              onChanged: _seek,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(_position), style: theme.textTheme.bodySmall),
                  Text(_fmt(_duration), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Restart button
                IconButton(
                  icon: const Icon(Icons.replay),
                  tooltip: 'Start from beginning',
                  onPressed: _startFromBeginning,
                ),

                // Speed button
                TextButton(
                  onPressed: _setRate,
                  child: Text(
                    '${_playbackRate}x',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),

                // Main Play/Pause
                IconButton.filled(
                  iconSize: 42,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _togglePlayback,
                ),

                // Loop / Repeat One button
                IconButton(
                  icon: Icon(
                    _isRepeatOne ? Icons.repeat_one : Icons.repeat,
                    color: _isRepeatOne ? colorScheme.primary : colorScheme.outline,
                  ),
                  tooltip: _isRepeatOne ? 'Repeat One (On)' : 'Repeat One (Off)',
                  onPressed: _cycleLoop,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerControls({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black38,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _position.inMilliseconds
                .toDouble()
                .clamp(0.0, _duration.inMilliseconds.toDouble()),
            max: _duration.inMilliseconds > 0
                ? _duration.inMilliseconds.toDouble()
                : 1.0,
            activeColor: Colors.amber,
            inactiveColor: Colors.white24,
            onChanged: _seek,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.replay, color: Colors.white70),
                onPressed: _startFromBeginning,
              ),
              TextButton(
                onPressed: _setRate,
                child: Text(
                  '${_playbackRate}x',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton.filled(
                iconSize: 36,
                style: IconButton.styleFrom(backgroundColor: Colors.amber),
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.black87,
                ),
                onPressed: _togglePlayback,
              ),
              IconButton(
                icon: Icon(
                  _isRepeatOne ? Icons.repeat_one : Icons.repeat,
                  color: _isRepeatOne ? Colors.amber : Colors.white38,
                ),
                onPressed: _cycleLoop,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioSourceCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.audiotrack, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Audio attached',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _uploadAudio,
            child: const Text('Replace'),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
            tooltip: 'Remove audio',
            onPressed: _deleteAudio,
          ),
        ],
      ),
    );
  }

  Widget _buildNoAudioCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.mic_none, size: 48, color: colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              'No audio yet.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Record your recitation with the microphone, or upload an audio file.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_isRecording) ...[
              Text(
                'Recording... ${_fmt(Duration(seconds: _recordSeconds))}',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                icon: const Icon(Icons.stop),
                label: const Text('Stop Recording'),
                onPressed: _stopRecording,
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.mic),
                    label: const Text('Record'),
                    onPressed: _startRecording,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload'),
                    onPressed: _uploadAudio,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
