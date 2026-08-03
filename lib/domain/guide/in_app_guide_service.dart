import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages persistence for interactive in-app feature onboarding guides.
class InAppGuideService extends ChangeNotifier {
  static const String keyCandidatesTour = 'guide_candidates_tour_v1';
  static const String keyImportTour = 'guide_import_tour_v1';
  static const String keyModelsTour = 'guide_models_tour_v1';

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  bool isGuideCompleted(String guideKey) {
    return _prefs?.getBool(guideKey) ?? false;
  }

  Future<void> markGuideCompleted(String guideKey) async {
    await initialize();
    await _prefs?.setBool(guideKey, true);
    notifyListeners();
  }

  Future<void> resetAllGuides() async {
    await initialize();
    await _prefs?.remove(keyCandidatesTour);
    await _prefs?.remove(keyImportTour);
    await _prefs?.remove(keyModelsTour);
    notifyListeners();
  }
}
