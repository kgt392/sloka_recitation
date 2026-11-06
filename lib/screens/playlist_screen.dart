import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/playlist.dart';
import '../models/sloka.dart';
import '../services/playlist_share.dart';
import '../services/storage_service.dart';
import 'playlist_detail_screen.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final StorageService _storage = StorageService.instance;
  final PlaylistShare _share = PlaylistShare.instance;

  List<Playlist> _playlists = [];
  List<Sloka> _allSlokas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final playlists = await _storage.loadPlaylists();
    final slokas = await _storage.loadSlokas();
    if (mounted) {
      setState(() {
        _playlists = playlists;
        _allSlokas = slokas;
        _isLoading = false;
      });
    }
  }

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final createdName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create a Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Playlist Name',
            hintText: 'e.g., Morning Recitations',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (createdName != null && createdName.isNotEmpty) {
      final newPlaylist = Playlist(
        id: const Uuid().v4(),
        name: createdName,
      );
      await _storage.addPlaylist(newPlaylist);
      _load();
    }
  }

  Future<void> _editPlaylistName(Playlist playlist) async {
    final controller = TextEditingController(text: playlist.name);
    final updatedName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Playlist Name',
          ),
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
      final updated = playlist.copyWith(name: updatedName);
      await _storage.updatePlaylist(updated);
      _load();
    }
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Delete "${playlist.name}"?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.deletePlaylist(playlist.id);
      _load();
    }
  }

  Future<void> _sharePlaylist(Playlist playlist) async {
    try {
      await _share.exportPlaylist(playlist, _allSlokas);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share playlist: $e')),
        );
      }
    }
  }

  Future<void> _importPlaylist() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['slokapack', 'zip'],
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path != null) {
          final imported = await _share.importPlaylist(path);
          if (imported != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Imported "${imported.name}" successfully!')),
            );
            _load();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Import'),
            onPressed: _importPlaylist,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _playlists.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.queue_music,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No playlists yet.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap + to create one or import a .slokapack shared by a friend.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _playlists.length,
                    itemBuilder: (context, index) {
                      final p = _playlists[index];
                      final count = p.slokaIds.length;
                      final audioCount = _allSlokas
                          .where((s) => p.slokaIds.contains(s.id) && s.hasAudio)
                          .length;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.primary,
                            child: const Icon(Icons.playlist_play),
                          ),
                          title: Text(
                            p.name,
                            style: const TextStyle(
                              fontFamily: 'Noto Serif',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '$count slokas • $audioCount with audio',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'share') _sharePlaylist(p);
                              if (val == 'edit') _editPlaylistName(p);
                              if (val == 'delete') _deletePlaylist(p);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'share',
                                child: Row(
                                  children: [
                                    Icon(Icons.share_outlined, size: 20),
                                    SizedBox(width: 10),
                                    Text('Share playlist'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 20),
                                    SizedBox(width: 10),
                                    Text('Edit name'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline,
                                        size: 20,
                                        color: colorScheme.error),
                                    const SizedBox(width: 10),
                                    Text('Delete',
                                        style:
                                            TextStyle(color: colorScheme.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PlaylistDetailScreen(playlistId: p.id),
                              ),
                            );
                            _load();
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        tooltip: 'New Playlist',
        child: const Icon(Icons.add),
      ),
    );
  }
}
