import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class AudioImport {
  static final AudioImport instance = AudioImport._internal();
  AudioImport._internal();
  factory AudioImport() => instance;

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;

  Future<String?> pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'opus', 'webm'],
      );

      if (result != null && result.files.isNotEmpty) {
        final sourcePath = result.files.single.path;
        if (sourcePath != null) {
          return await copyToAppStorage(sourcePath);
        }
      }
    } catch (e) {
      debugPrint('Error picking audio file: $e');
    }
    return null;
  }

  Future<String> copyToAppStorage(String sourcePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(docsDir.path, 'audio'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final ext = p.extension(sourcePath).isEmpty ? '.m4a' : p.extension(sourcePath);
    final fileName = 'sloka_${const Uuid().v4()}$ext';
    final targetPath = p.join(audioDir.path, fileName);

    final sourceFile = File(sourcePath);
    await sourceFile.copy(targetPath);
    return targetPath;
  }

  Future<bool> startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('Microphone permission not granted');
        return false;
      }

      if (await _recorder.hasPermission()) {
        final docsDir = await getApplicationDocumentsDirectory();
        final audioDir = Directory(p.join(docsDir.path, 'audio'));
        if (!await audioDir.exists()) {
          await audioDir.create(recursive: true);
        }

        final fileName = 'sloka_rec_${const Uuid().v4()}.m4a';
        _currentRecordingPath = p.join(audioDir.path, fileName);

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _currentRecordingPath!,
        );

        _isRecording = true;
        return true;
      }
    } catch (e) {
      debugPrint('Error starting audio recording: $e');
    }
    return false;
  }

  Future<String?> stopRecording() async {
    try {
      if (_isRecording) {
        final path = await _recorder.stop();
        _isRecording = false;
        final savedPath = path ?? _currentRecordingPath;
        _currentRecordingPath = null;
        return savedPath;
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
    }
    return null;
  }

  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
          _currentRecordingPath = null;
        }
      }
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
    }
  }

  Future<void> deleteAudioFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting audio file: $e');
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}
