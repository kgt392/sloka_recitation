import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sloka.dart';
import '../models/playlist.dart';

class StorageService {
  static const String _slokasKey = 'slokas';
  static const String _playlistsKey = 'playlists';

  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  factory StorageService() => instance;

  Future<List<Sloka>> loadSlokas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_slokasKey);
      if (jsonString == null || jsonString.isEmpty) {
        return _getDefaultSlokas();
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => Sloka.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading slokas from storage: $e');
      return _getDefaultSlokas();
    }
  }

  Future<void> saveSlokas(List<Sloka> slokas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(slokas.map((s) => s.toJson()).toList());
      await prefs.setString(_slokasKey, jsonString);
    } catch (e) {
      debugPrint('Error saving slokas to storage: $e');
    }
  }

  Future<void> addSloka(Sloka sloka) async {
    final list = await loadSlokas();
    list.insert(0, sloka);
    await saveSlokas(list);
  }

  Future<void> updateSloka(Sloka sloka) async {
    final list = await loadSlokas();
    final index = list.indexWhere((s) => s.id == sloka.id);
    if (index != -1) {
      list[index] = sloka;
      await saveSlokas(list);
    } else {
      await addSloka(sloka);
    }
  }

  Future<void> deleteSloka(String id) async {
    final list = await loadSlokas();
    list.removeWhere((s) => s.id == id);
    await saveSlokas(list);

    // Also remove reference from playlists
    final playlists = await loadPlaylists();
    var modified = false;
    for (var i = 0; i < playlists.length; i++) {
      if (playlists[i].slokaIds.contains(id)) {
        final updatedIds = List<String>.from(playlists[i].slokaIds)..remove(id);
        playlists[i] = playlists[i].copyWith(slokaIds: updatedIds);
        modified = true;
      }
    }
    if (modified) {
      await savePlaylists(playlists);
    }
  }

  Future<List<Playlist>> loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_playlistsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => Playlist.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading playlists: $e');
      return [];
    }
  }

  Future<void> savePlaylists(List<Playlist> playlists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(playlists.map((p) => p.toJson()).toList());
      await prefs.setString(_playlistsKey, jsonString);
    } catch (e) {
      debugPrint('Error saving playlists: $e');
    }
  }

  Future<void> addPlaylist(Playlist playlist) async {
    final list = await loadPlaylists();
    list.insert(0, playlist);
    await savePlaylists(list);
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    final list = await loadPlaylists();
    final index = list.indexWhere((p) => p.id == playlist.id);
    if (index != -1) {
      list[index] = playlist;
      await savePlaylists(list);
    } else {
      await addPlaylist(playlist);
    }
  }

  Future<void> deletePlaylist(String id) async {
    final list = await loadPlaylists();
    list.removeWhere((p) => p.id == id);
    await savePlaylists(list);
  }

  List<Sloka> _getDefaultSlokas() {
    return [
      Sloka(
        id: 'default-bg-2-13',
        title: 'Bhagavad Gita 2.13',
        text: 'dehino \'smin yathā dehe\nkaumāraṁ yauvanaṁ jarā\ntathā dehāntara-prāptir\ndhīras tatra na muhyati',
      ),
      Sloka(
        id: 'default-bg-9-22',
        title: 'Bhagavad Gita 9.22',
        text: 'ananyāś cintayanto māṁ\nye janāḥ paryupāsate\nteṣāṁ nityābhiyuktānāṁ\nyoga-kṣemaṁ vahāmy aham',
      ),
      Sloka(
        id: 'default-bg-18-66',
        title: 'Bhagavad Gita 18.66',
        text: 'sarva-dharmān parityajya\nmām ekaṁ śaraṇaṁ vraja\nahaṁ tvāṁ sarva-pāpebhyo\nmokṣayiṣyāmi mā śucaḥ',
      ),
      Sloka(
        id: 'default-maha-mantra',
        title: 'Maha Mantra',
        text: 'Hare Kṛṣṇa Hare Kṛṣṇa\nKṛṣṇa Kṛṣṇa Hare Hare\nHare Rāma Hare Rāma\nRāma Rāma Hare Hare',
      ),
    ];
  }
}
