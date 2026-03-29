import 'package:shared_preferences/shared_preferences.dart';

import '../models/remote_user_profile.dart';

class UserPrefsStore {
  static const _kFont = 'alfawz_arabic_font_size';
  static const _kReminder = 'alfawz_daily_reminder';
  static const _kRegComplete = 'alfawz_registration_complete';
  static const _kDisplayName = 'alfawz_display_name';
  static const _kEmail = 'alfawz_email';
  static const _kAuthToken = 'alfawz_auth_token';
  static const _kHearAbout = 'alfawz_hear_about';
  static const _kAgeRange = 'alfawz_age_range';

  Future<double> loadArabicFontSize({double fallback = 26}) async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(_kFont) ?? fallback;
  }

  Future<void> saveArabicFontSize(double v) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kFont, v.clamp(20, 36));
  }

  Future<bool> loadDailyReminder({bool fallback = true}) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kReminder) ?? fallback;
  }

  Future<void> saveDailyReminder(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kReminder, v);
  }

  /// Inscription valide si un jeton serveur est présent.
  Future<bool> loadRegistrationComplete() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString(_kAuthToken);
    return t != null && t.isNotEmpty;
  }

  Future<String?> loadAuthToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kAuthToken);
  }

  Future<String?> loadDisplayName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kDisplayName);
  }

  Future<String?> loadEmail() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kEmail);
  }

  Future<String?> loadHearAboutUs() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kHearAbout);
  }

  Future<String?> loadAgeRange() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kAgeRange);
  }

  /// Après inscription ou mise à jour profil.
  Future<void> saveRemoteSession({
    required String token,
    required RemoteUserProfile profile,
    required String hearAboutUs,
    required String ageRange,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAuthToken, token);
    await p.setBool(_kRegComplete, true);
    await p.setString(_kDisplayName, profile.firstName.trim());
    await p.setString(_kEmail, profile.email.trim());
    await p.setString(_kHearAbout, hearAboutUs);
    await p.setString(_kAgeRange, ageRange);
  }

  Future<void> applyProfileSnapshot(RemoteUserProfile profile) async {
    final p = await SharedPreferences.getInstance();
    if (profile.firstName.isNotEmpty) {
      await p.setString(_kDisplayName, profile.firstName);
    }
    if (profile.email.isNotEmpty) {
      await p.setString(_kEmail, profile.email);
    }
    if (profile.hearAboutUs != null && profile.hearAboutUs!.isNotEmpty) {
      await p.setString(_kHearAbout, profile.hearAboutUs!);
    }
    if (profile.ageRange != null && profile.ageRange!.isNotEmpty) {
      await p.setString(_kAgeRange, profile.ageRange!);
    }
  }

  Future<void> clearRegistration() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAuthToken);
    await p.setBool(_kRegComplete, false);
    await p.remove(_kDisplayName);
    await p.remove(_kEmail);
    await p.remove(_kHearAbout);
    await p.remove(_kAgeRange);
  }
}
