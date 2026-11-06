import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'models/playlist.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/play_screen.dart';
import 'screens/playlist_detail_screen.dart';
import 'screens/playlist_screen.dart';
import 'services/playlist_share.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SlokaRecitationApp());
}

class SlokaRecitationApp extends StatelessWidget {
  const SlokaRecitationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sloka Recitation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  StreamSubscription? _intentSubscription;
  final PlaylistShare _shareService = PlaylistShare.instance;

  final List<Widget> _screens = const [
    HomeScreen(),
    PlayScreen(),
    PlaylistScreen(),
    MenuScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _handleSharedFiles();
  }

  void _handleSharedFiles() {
    // Listen for incoming shared files while the app is running in memory
    _intentSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          _processSharedFile(value.first.path);
        }
      },
      onError: (err) {
        debugPrint('ReceiveSharingIntent getMediaStream error: $err');
      },
    );

    // Get files when app is opened via intent from closed state
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _processSharedFile(value.first.path);
      }
    });
  }

  Future<void> _processSharedFile(String path) async {
    if (path.endsWith('.slokapack') || path.endsWith('.zip')) {
      try {
        final imported = await _shareService.importPlaylist(path);
        if (imported != null && mounted) {
          _snack('Imported shared playlist: "${imported.name}"');
          // Switch to Playlists tab
          setState(() {
            _currentIndex = 2;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailScreen(playlistId: imported.id),
            ),
          );
        }
      } catch (e) {
        _snack('Could not import playlist: $e');
      }
    }
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void dispose() {
    _intentSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.7),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Slokas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            activeIcon: Icon(Icons.play_circle_fill),
            label: 'Play',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music_outlined),
            activeIcon: Icon(Icons.queue_music),
            label: 'Playlists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_outlined),
            activeIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
