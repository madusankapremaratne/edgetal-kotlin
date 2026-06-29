import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Download lifecycle for the on-device LLM model.
sealed class DownloadState {
  const DownloadState();
}

class DownloadIdle extends DownloadState {
  const DownloadIdle();
}

class Downloading extends DownloadState {
  const Downloading(this.bytesDownloaded, this.totalBytes, this.bytesPerSecond);
  final int bytesDownloaded;
  final int totalBytes;
  final int bytesPerSecond;
  int get percentage =>
      totalBytes > 0 ? ((bytesDownloaded * 100) ~/ totalBytes) : 0;
}

class DownloadCompleted extends DownloadState {
  const DownloadCompleted();
}

class DownloadFailed extends DownloadState {
  const DownloadFailed(this.message, {this.canResume = false});
  final String message;
  final bool canResume;
}

/// Downloads the Gemma model into private app storage, with HTTP range-based
/// resume so an interrupted ~1.3 GB transfer continues where it left off.
/// Mirrors the original `ModelDownloadManager` behaviour.
class ModelDownloadManager {
  ModelDownloadManager._();
  static final ModelDownloadManager instance = ModelDownloadManager._();

  static const String modelFileName = 'gemma-2b-it-cpu-int4.bin';
  static const String modelDisplayName = 'Gemma 2B IT (CPU, Int4)';
  static const int approxSizeBytes = 1360000000;
  static const String defaultUrl =
      'https://huggingface.co/a8nova/gemma-2b-it-cpu-int4/resolve/main/gemma-2b-it-cpu-int4.bin';

  final _stateController = StreamController<DownloadState>.broadcast();
  Stream<DownloadState> get state => _stateController.stream;
  DownloadState current = const DownloadIdle();

  Directory? _dir;
  http.Client? _client;
  bool _cancelRequested = false;

  Future<Directory> get _directory async =>
      _dir ??= await getApplicationSupportDirectory();

  Future<File> get _modelFile async =>
      File('${(await _directory).path}/$modelFileName');
  Future<File> get _partFile async =>
      File('${(await _directory).path}/$modelFileName.part');

  void _emit(DownloadState s) {
    current = s;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  Future<bool> isModelInstalled() async => (await _modelFile).exists();

  Future<int> installedSizeBytes() async {
    final f = await _modelFile;
    return await f.exists() ? await f.length() : 0;
  }

  Future<int> partialSizeBytes() async {
    final f = await _partFile;
    return await f.exists() ? await f.length() : 0;
  }

  Future<void> deleteModel() async {
    await cancelDownload(silent: true);
    final model = await _modelFile;
    final part = await _partFile;
    if (await model.exists()) await model.delete();
    if (await part.exists()) await part.delete();
    _emit(const DownloadIdle());
  }

  Future<void> cancelDownload({bool silent = false}) async {
    _cancelRequested = true;
    _client?.close();
    _client = null;
    if (!silent) {
      _emit(const DownloadFailed('Download paused. Tap Download to resume.',
          canResume: true));
    }
  }

  /// Starts (or resumes) the download. No-op if already installed.
  Future<void> startDownload({String? url, String? accessToken}) async {
    if (await isModelInstalled()) {
      _emit(const DownloadCompleted());
      return;
    }
    final target = (url ?? defaultUrl).trim();
    if (!target.startsWith('https://')) {
      _emit(const DownloadFailed('Invalid URL: must start with https://'));
      return;
    }

    _cancelRequested = false;
    final part = await _partFile;
    var resumeFrom = await part.exists() ? await part.length() : 0;
    _emit(Downloading(resumeFrom, 0, 0));

    final client = http.Client();
    _client = client;

    try {
      final request = http.Request('GET', Uri.parse(target));
      if (accessToken != null && accessToken.trim().isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${accessToken.trim()}';
      }
      if (resumeFrom > 0) {
        request.headers['Range'] = 'bytes=$resumeFrom-';
      }

      final response = await client.send(request);

      if (response.statusCode == 401 || response.statusCode == 403) {
        _emit(DownloadFailed(
          'Access denied (HTTP ${response.statusCode}). This model may be '
          'gated — accept its license on Hugging Face and add an access token.',
        ));
        return;
      }
      if (response.statusCode != 200 && response.statusCode != 206) {
        _emit(DownloadFailed('Download failed: HTTP ${response.statusCode}',
            canResume: resumeFrom > 0));
        return;
      }

      final serverResumed = response.statusCode == 206;
      var bytesDownloaded = serverResumed ? resumeFrom : 0;
      if (!serverResumed && resumeFrom > 0 && await part.exists()) {
        await part.delete();
        resumeFrom = 0;
      }
      final contentLength = response.contentLength ?? 0;
      final totalBytes =
          contentLength > 0 ? contentLength + (serverResumed ? resumeFrom : 0) : 0;

      final dir = await _directory;
      final stat = await dir.stat();
      // Best-effort free-space check is platform-dependent; skip if unknown.
      if (stat.type == FileSystemEntityType.notFound) {
        _emit(const DownloadFailed('Storage directory unavailable'));
        return;
      }

      final sink = (await _partFile)
          .openWrite(mode: serverResumed ? FileMode.append : FileMode.write);

      var lastEmit = DateTime.now();
      var bytesSinceEmit = 0;

      await for (final chunk in response.stream) {
        if (_cancelRequested) {
          await sink.close();
          return; // paused state already emitted by cancelDownload
        }
        sink.add(chunk);
        bytesDownloaded += chunk.length;
        bytesSinceEmit += chunk.length;

        final now = DateTime.now();
        final elapsedMs = now.difference(lastEmit).inMilliseconds;
        if (elapsedMs >= 250) {
          _emit(Downloading(
            bytesDownloaded,
            totalBytes,
            (bytesSinceEmit * 1000 / elapsedMs).round(),
          ));
          lastEmit = now;
          bytesSinceEmit = 0;
        }
      }
      await sink.close();

      if (totalBytes > 0 && bytesDownloaded < totalBytes) {
        _emit(DownloadFailed(
          'Connection lost at ${(bytesDownloaded / 1000000).round()} MB. '
          'Tap Download to resume.',
          canResume: true,
        ));
        return;
      }

      await (await _partFile).rename((await _modelFile).path);
      _emit(const DownloadCompleted());
    } on Object catch (e) {
      if (_cancelRequested) return;
      _emit(DownloadFailed(
        'Download error: $e. Tap Download to retry/resume.',
        canResume: await partialSizeBytes() > 0,
      ));
    } finally {
      _client = null;
    }
  }
}
