import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/sloka.dart';
import '../services/playlist_share.dart';
import '../services/storage_service.dart';
import 'sloka_detail_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final StorageService _storage = StorageService.instance;
  final PlaylistShare _shareService = PlaylistShare.instance;
  final AudioPlayer _player = AudioPlayer();

  Playlist? _playlist;
  List<Sloka> _allSlokas = [];
  List<Sloka> _playlistSlokas = [];

  bool _isLoading = true;
  bool _isPlaying = false;
  int _currentIndex = -1;
  double _playbackRate = 1.0;
  bool _isLoopPlaylist = false;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _load();
    _initAudio();
  }

  void _initAudio() {
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

    _player.onPlayerComplete.listen((_) {
      _onComplete();
    });
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final playlists = await _storage.loadPlaylists();
    final all = await _storage.loadSlokas();

    final match = playlists.cast<Playlist?>().firstWhere(
          (p) => p != null && p.id == widget.playlistId,
          orElse: () => null,
        );

    if (match != null) {
      final pSlokas = <Sloka>[];
      for (final id in match.slokaIds) {
        final sloka = all.cast<Sloka?>().firstWhere(
              (s) => s != null && s.id == id,
              orElse: () => null,
            );
        if (sloka != null) {
          pSlokas.add(sloka);
        }
      }

      if (mounted) {
        setState(() {
          _playlist = match;
          _allSlokas = all;
          _playlistSlokas = pSlokas;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Sloka> get _audioSlokas =>
      _playlistSlokas.where((s) => s.hasAudio).toList();

  Future<void> _playAt(int index) async {
    if (index < 0 || index >= _playlistSlokas.length) return;
    final sloka = _playlistSlokas[index];
    if (!sloka.hasAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No audio recorded for "${sloka.title}"')),
      );
      return;
    }

    try {
      final file = File(sloka.audioPath!);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio file not found on device.')),
        );
        return;
      }

      setState(() {
        _currentIndex = index;
        _position = Duration.zero;
      });

      await _player.stop();
      await _player.setPlaybackRate(_playbackRate);
      await _player.play(DeviceFileSource(sloka.audioPath!));
    } catch (e) {
      debugPrint('Error playing audio in playlist: $e');
    }
  }

  Future<void> _playAll() async {
    if (_playlistSlokas.isEmpty) return;
    final firstAudioIdx = _playlistSlokas.indexWhere((s) => s.hasAudio);
    if (firstAudioIdx != -1) {
      _playAt(firstAudioIdx);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio recordings in this playlist.')),
      );
    }
  }

  Future<void> _togglePlayback() async {
    if (_currentIndex == -1) {
      _playAll();
      return;
    }

    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  Future<void> _stopPlayback() async {
    await _player.stop();
    setState(() {
      _isPlaying = false;
      _currentIndex = -1;
      _position = Duration.zero;
    });
  }

  void _next() {
    if (_playlistSlokas.isEmpty) return;
    // Find next sloka with audio
    for (var i = _currentIndex + 1; i < _playlistSlokas.length; i++) {
      if (_playlistSlokas[i].hasAudio) {
        _playAt(i);
        return;
      }
    }
    // If loop enabled, wrap around
    if (_isLoopPlaylist) {
      for (var i = 0; i <= _currentIndex; i++) {
        if (_playlistSlokas[i].hasAudio) {
          _playAt(i);
          return;
        }
      }
    }
  }

  void _prev() {
    if (_playlistSlokas.isEmpty) return;
    for (var i = _currentIndex - 1; i >= 0; i--) {
      if (_playlistSlokas[i].hasAudio) {
        _playAt(i);
        return;
      }
    }
  }

  void _onComplete() {
    _next();
  }

  void _cycleLoop() {
    setState(() {
      _isLoopPlaylist = !_isLoopPlaylist;
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

  Future<void> _seek(double value) async {
    await _player.seek(Duration(milliseconds: value.toInt()));
  }

  Future<void> _addSlokas() async {
    final unadded = _allSlokas
        .where((s) => !_playlist!.slokaIds.contains(s.id))
        .toList();

    if (unadded.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All slokas are already in this playlist.')),
      );
      return;
    }

    final selectedIds = <String>{};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add Slokas to Playlist',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: unadded.length,
                        itemBuilder: (context, index) {
                          final sloka = unadded[index];
                          final isSelected = selectedIds.contains(sloka.id);
                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(
                              sloka.title,
                              style: const TextStyle(fontFamily: 'Noto Serif'),
                            ),
                            subtitle: Text(
                              sloka.text.split('\n').first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Noto Serif',
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            secondary: sloka.hasAudio
                                ? const Icon(Icons.mic, size: 20)
                                : null,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  selectedIds.add(sloka.id);
                                } else {
                                  selectedIds.remove(sloka.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: selectedIds.isEmpty
                            ? null
                            : () => Navigator.pop(context, selectedIds),
                        child: Text(
                          selectedIds.isEmpty
                              ? 'Select Slokas'
                              : 'Add Selected Slokas (${selectedIds.length})',
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (selectedIds.isNotEmpty && _playlist != null) {
      final updatedIds = List<String>.from(_playlist!.slokaIds)
        ..addAll(selectedIds);
      final updated = _playlist!.copyWith(slokaIds: updatedIds);
      await _storage.updatePlaylist(updated);
      _load();
    }
  }

  Future<void> _removeSloka(String slokaId) async {
    if (_playlist == null) return;
    final updatedIds = List<String>.from(_playlist!.slokaIds)..remove(slokaId);
    final updated = _playlist!.copyWith(slokaIds: updatedIds);
    await _storage.updatePlaylist(updated);
    _load();
  }

  Future<void> _share() async {
    if (_playlist == null) return;
    try {
      await _shareService.exportPlaylist(_playlist!, _allSlokas);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share playlist: $e')),
        );
      }
    }
  }

  Future<void> _editPlaylistName() async {
    if (_playlist == null) return;
    final controller = TextEditingController(text: _playlist!.name);
    final updatedName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Playlist Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updatedName != null && updatedName.isNotEmpty) {
      final updated = _playlist!.copyWith(name: updatedName);
      await _storage.updatePlaylist(updated);
      _load();
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_playlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Playlist not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_playlist!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Slokas',
            onPressed: _addSlokas,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share playlist',
            onPressed: _share,
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'edit') _editPlaylistName();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Rename playlist'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Playlist Header info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_playlistSlokas.length} SLOKAS  •  ${_audioSlokas.length} WITH AUDIO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                if (_audioSlokas.isNotEmpty)
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Play All'),
                    onPressed: _playAll,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Reorderable slokas list
          Expanded(
            child: _playlistSlokas.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.playlist_add,
                            size: 48,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No slokas in this playlist.',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap + to add some.',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Slokas'),
                            onPressed: _addSlokas,
                          ),
                        ],
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: _playlistSlokas.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (oldIndex < newIndex) newIndex -= 1;
                      final item = _playlistSlokas.removeAt(oldIndex);
                      _playlistSlokas.insert(newIndex, item);
                      final updatedIds =
                          _playlistSlokas.map((s) => s.id).toList();
                      final updated =
                          _playlist!.copyWith(slokaIds: updatedIds);
                      await _storage.updatePlaylist(updated);
                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      final sloka = _playlistSlokas[index];
                      final isCurrent = index == _currentIndex;

                      return Card(
                        key: ValueKey(sloka.id),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        color: isCurrent
                            ? colorScheme.primaryContainer.withOpacity(0.4)
                            : Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: isCurrent
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest,
                            foregroundColor:
                                isCurrent ? Colors.white : colorScheme.onSurface,
                            child: isCurrent && _isPlaying
                                ? const Icon(Icons.volume_up, size: 20)
                                : Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                          title: Text(
                            sloka.title,
                            style: TextStyle(
                              fontFamily: 'Noto Serif',
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            sloka.text.split('\n').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Noto Serif',
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (sloka.hasAudio)
                                IconButton(
                                  icon: Icon(
                                    isCurrent && _isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: colorScheme.primary,
                                  ),
                                  onPressed: () => _playAt(index),
                                ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                tooltip: 'Remove from playlist',
                                onPressed: () => _removeSloka(sloka.id),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle),
                              ),
                            ],
                          ),
                          onTap: () {
                            if (sloka.hasAudio) {
                              _playAt(index);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SlokaDetailScreen(
                                    slokaId: sloka.id,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: _currentIndex != -1 ? _buildNowPlayingPanel() : null,
    );
  }

  Widget _buildNowPlayingPanel() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentSloka =
        (_currentIndex >= 0 && _currentIndex < _playlistSlokas.length)
            ? _playlistSlokas[_currentIndex]
            : null;

    if (currentSloka == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current track header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentSloka.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'Noto Serif',
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_currentIndex + 1} of ${_playlistSlokas.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _stopPlayback,
              ),
            ],
          ),

          // Slider
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

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  _isLoopPlaylist ? Icons.repeat_on : Icons.repeat,
                  color: _isLoopPlaylist ? colorScheme.primary : colorScheme.outline,
                ),
                tooltip: 'Loop Playlist',
                onPressed: _cycleLoop,
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: _prev,
              ),
              IconButton.filled(
                iconSize: 36,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: _togglePlayback,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: _next,
              ),
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
            ],
          ),
        ],
      ),
    );
  }
}
