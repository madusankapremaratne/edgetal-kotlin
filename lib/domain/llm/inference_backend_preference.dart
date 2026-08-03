import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's preferred LLM inference backend ("CPU"/"GPU") across
/// app restarts, so the resource-analysis GPU comparison survives a relaunch.
class InferenceBackendPreference {
  static const _key = 'edgetal_llm_backend';

  Future<String> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'CPU';
  }

  Future<void> save(String backend) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, backend);
  }
}
