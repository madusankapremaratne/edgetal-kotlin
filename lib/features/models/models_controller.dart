import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/embedding/embedding_provider.dart';
import '../../domain/llm/inference_backend_preference.dart';
import '../../domain/llm/llm_provider.dart';
import '../../domain/llm/model_download_manager.dart';

class ModelsState {
  const ModelsState({
    this.isInstalled = false,
    this.installedBytes = 0,
    this.partialBytes = 0,
    this.download = const DownloadIdle(),
    this.embedderLabel = '',
    this.embedderNative = false,
    this.llmBackend = 'CPU',
    this.switchingBackend = false,
  });

  final bool isInstalled;
  final int installedBytes;
  final int partialBytes;
  final DownloadState download;
  final String embedderLabel;
  final bool embedderNative;
  final String llmBackend;
  final bool switchingBackend;

  ModelsState copyWith({
    bool? isInstalled,
    int? installedBytes,
    int? partialBytes,
    DownloadState? download,
    String? embedderLabel,
    bool? embedderNative,
    String? llmBackend,
    bool? switchingBackend,
  }) =>
      ModelsState(
        isInstalled: isInstalled ?? this.isInstalled,
        installedBytes: installedBytes ?? this.installedBytes,
        partialBytes: partialBytes ?? this.partialBytes,
        download: download ?? this.download,
        embedderLabel: embedderLabel ?? this.embedderLabel,
        embedderNative: embedderNative ?? this.embedderNative,
        llmBackend: llmBackend ?? this.llmBackend,
        switchingBackend: switchingBackend ?? this.switchingBackend,
      );
}

class ModelsController extends StateNotifier<ModelsState> {
  ModelsController(
    this._downloads,
    this._embedder,
    this._llm,
    this._backendPreference,
  ) : super(const ModelsState()) {
    _sub = _downloads.state.listen((s) {
      state = state.copyWith(download: s);
      if (s is DownloadCompleted || s is DownloadIdle) refresh();
    });
    refresh();
    _initEmbedder();
    _initLlmBackend();
  }

  final ModelDownloadManager _downloads;
  final EmbeddingProvider _embedder;
  final LlmProvider _llm;
  final InferenceBackendPreference _backendPreference;
  StreamSubscription<DownloadState>? _sub;

  Future<void> _initEmbedder() async {
    await _embedder.initialize();
    state = state.copyWith(
      embedderLabel: _embedder.backendLabel,
      embedderNative: _embedder.isNativeActive,
    );
  }

  Future<void> _initLlmBackend() async {
    final preferred = await _backendPreference.load();
    if (preferred != 'CPU') {
      await setLlmBackend(preferred);
    } else {
      state = state.copyWith(llmBackend: _llm.activeBackend);
    }
  }

  Future<void> setLlmBackend(String backend) async {
    if (state.switchingBackend) return;
    state = state.copyWith(switchingBackend: true);
    await _llm.setBackend(backend);
    await _backendPreference.save(backend);
    state = state.copyWith(
      llmBackend: _llm.activeBackend,
      switchingBackend: false,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(
      isInstalled: await _downloads.isModelInstalled(),
      installedBytes: await _downloads.installedSizeBytes(),
      partialBytes: await _downloads.partialSizeBytes(),
    );
  }

  Future<void> startDownload({String? url, String? token}) =>
      _downloads.startDownload(url: url, accessToken: token);

  Future<void> cancel() => _downloads.cancelDownload();

  Future<void> deleteModel() => _downloads.deleteModel();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final modelsControllerProvider =
    StateNotifierProvider<ModelsController, ModelsState>((ref) {
  return ModelsController(
    ref.watch(downloadManagerProvider),
    ref.watch(embeddingProviderProvider),
    ref.watch(llmProviderProvider),
    ref.watch(inferenceBackendPreferenceProvider),
  );
});
