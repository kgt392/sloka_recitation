import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'models/playlist.dart';
import 'screens/add_edit_sloka_screen.dart';
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
    AddEditSlokaScreen(),
    PlayScreen(),
    PlaylistScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _handleSharedFiles();
  }

  void _handleSharedFiles() {
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
          setState(() {
            _currentIndex = 3; // Switch to Playlist tab
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
    return Scaffold(
      drawer: const Drawer(
        child: MenuScreen(),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Add Sloka',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            activeIcon: Icon(Icons.play_circle_fill),
            label: 'Play the Sloka',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music_outlined),
            activeIcon: Icon(Icons.queue_music),
            label: 'Playlist',
          ),
        ],
      ),
    );
  }
}
