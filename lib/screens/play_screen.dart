import 'package:flutter/material.dart';
import '../models/sloka.dart';
import '../services/storage_service.dart';
import 'sloka_detail_screen.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  final StorageService _storage = StorageService.instance;
  List<Sloka> _audioSlokas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final all = await _storage.loadSlokas();
    if (mounted) {
      setState(() {
        _audioSlokas = all.where((s) => s.hasAudio).toList();
        _isLoading = false;
      });
    }
  }

  void _open(Sloka sloka) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SlokaDetailScreen(slokaId: sloka.id),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Play the Sloka'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _audioSlokas.isEmpty
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
                            Icons.headphones,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No slokas with audio yet.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Record or upload audio for a sloka to play it here.',
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
                    itemCount: _audioSlokas.length,
                    itemBuilder: (context, index) {
                      final sloka = _audioSlokas[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.primary,
                            child: const Icon(Icons.play_arrow),
                          ),
                          title: Text(
                            sloka.title,
                            style: const TextStyle(
                              fontFamily: 'Noto Serif',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              sloka.text
                                  .split(RegExp(r'[\r\n]+'))
                                  .firstWhere((l) => l.trim().isNotEmpty,
                                      orElse: () => ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Noto Serif',
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _open(sloka),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
