import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/playlist.dart';
import '../models/sloka.dart';
import 'storage_service.dart';

class PlaylistShare {
  static final PlaylistShare instance = PlaylistShare._internal();
  PlaylistShare._internal();
  factory PlaylistShare() => instance;

  Future<void> exportPlaylist(Playlist playlist, List<Sloka> allSlokas) async {
    try {
      final archive = Archive();

      // Find all slokas belonging to this playlist
      final playlistSlokas = allSlokas
          .where((s) => playlist.slokaIds.contains(s.id))
          .toList();

      final slokasManifest = <Map<String, dynamic>>[];

      for (final sloka in playlistSlokas) {
        String? audioArchiveName;
        if (sloka.audioPath != null && sloka.audioPath!.isNotEmpty) {
          final audioFile = File(sloka.audioPath!);
          if (await audioFile.exists()) {
            final ext = p.extension(sloka.audioPath!).isEmpty
                ? '.m4a'
                : p.extension(sloka.audioPath!);
            audioArchiveName = 'sloka_${sloka.id}$ext';
            final audioBytes = await audioFile.readAsBytes();
            archive.addFile(
              ArchiveFile(audioArchiveName, audioBytes.length, audioBytes),
            );
          }
        }

        slokasManifest.add({
          'id': sloka.id,
          'title': sloka.title,
          'text': sloka.text,
          'audioFile': audioArchiveName,
        });
      }

      final manifestData = {
        'version': 1,
        'app': 'SlokaRecitation',
        'playlist': {
          'id': playlist.id,
          'name': playlist.name,
          'slokaIds': playlist.slokaIds,
          'createdAt': playlist.createdAt.toIso8601String(),
        },
        'slokas': slokasManifest,
      };

      final manifestBytes = utf8.encode(jsonEncode(manifestData));
      archive.addFile(
        ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
      );

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      if (zipData == null) {
        throw Exception('Could not build the playlist file.');
      }

      final tempDir = await getTemporaryDirectory();
      final safeName = playlist.name
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();
      final fileName = '${safeName.isEmpty ? "playlist" : safeName}.slokapack';
      final exportPath = p.join(tempDir.path, fileName);

      final exportFile = File(exportPath);
      await exportFile.writeAsBytes(zipData);

      final xFile = XFile(
        exportPath,
        mimeType: 'application/octet-stream',
        name: fileName,
      );

      await Share.shareXFiles(
        [xFile],
        subject: 'Sloka playlist: ${playlist.name}',
        text: 'The playlist is sent as a ".slokapack" file. That single file already contains every sloka and its audio.',
      );
    } catch (e) {
      debugPrint('Could not share playlist: $e');
      rethrow;
    }
  }

  Future<Playlist?> importPlaylist(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      final bytes = await file.readAsBytes();
      Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(bytes);
      } catch (e) {
        throw Exception('The playlist file is corrupted.');
      }

      ArchiveFile? manifestFile;
      for (final f in archive) {
        if (f.name == 'manifest.json') {
          manifestFile = f;
          break;
        }
      }

      if (manifestFile == null) {
        throw Exception('This file does not contain a sloka playlist.');
      }

      final manifestContent = utf8.decode(manifestFile.content as List<int>);
      final Map<String, dynamic> manifest = jsonDecode(manifestContent);

      if (!manifest.containsKey('playlist') || !manifest.containsKey('slokas')) {
        throw Exception('This is not a valid sloka playlist file.');
      }

      final playlistJson = manifest['playlist'] as Map<String, dynamic>;
      final slokasJsonList = manifest['slokas'] as List<dynamic>;

      final docsDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory(p.join(docsDir.path, 'audio'));
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final storage = StorageService.instance;
      final existingSlokas = await storage.loadSlokas();
      final slokaIdMap = <String, String>{}; // original id -> merged id

      for (final item in slokasJsonList) {
        final sMap = item as Map<String, dynamic>;
        final origId = sMap['id'] as String;
        final title = sMap['title'] as String? ?? 'Untitled Sloka';
        final text = sMap['text'] as String? ?? '';
        final audioArchiveName = sMap['audioFile'] as String?;

        String? localAudioPath;
        if (audioArchiveName != null && audioArchiveName.isNotEmpty) {
          ArchiveFile? audioArchiveFile;
          for (final f in archive) {
            if (f.name == audioArchiveName) {
              audioArchiveFile = f;
              break;
            }
          }

          if (audioArchiveFile != null) {
            final ext = p.extension(audioArchiveName);
            final destName = 'sloka_${const Uuid().v4()}$ext';
            final destFile = File(p.join(audioDir.path, destName));
            await destFile.writeAsBytes(audioArchiveFile.content as List<int>);
            localAudioPath = destFile.path;
          }
        }

        // Check if matching sloka already exists (avoid duplication)
        final existingMatch = existingSlokas.cast<Sloka?>().firstWhere(
              (s) => s != null && (s.id == origId || (s.text.trim() == text.trim() && text.isNotEmpty)),
              orElse: () => null,
            );

        if (existingMatch != null) {
          slokaIdMap[origId] = existingMatch.id;
          // If existing sloka had no audio, but imported has audio, attach it
          if (!existingMatch.hasAudio && localAudioPath != null) {
            final updated = existingMatch.copyWith(audioPath: localAudioPath);
            await storage.updateSloka(updated);
          }
        } else {
          final newSloka = Sloka(
            id: const Uuid().v4(),
            title: title,
            text: text,
            audioPath: localAudioPath,
          );
          slokaIdMap[origId] = newSloka.id;
          await storage.addSloka(newSloka);
        }
      }

      // Rebuild playlist with resolved sloka IDs
      final rawSlokaIds = (playlistJson['slokaIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final resolvedSlokaIds = rawSlokaIds
          .map((id) => slokaIdMap[id] ?? id)
          .toList();

      final newPlaylist = Playlist(
        id: const Uuid().v4(),
        name: playlistJson['name'] as String? ?? 'Imported Playlist',
        slokaIds: resolvedSlokaIds,
      );

      await storage.addPlaylist(newPlaylist);
      return newPlaylist;
    } catch (e) {
      debugPrint('Error importing playlist: $e');
      rethrow;
    }
  }
}
