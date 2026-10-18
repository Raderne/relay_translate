import 'dart:ui' show TextDirection;

/// A language the user can pick as a translation target.
class Lang {
  const Lang(this.code, this.name, this.native, {this.flag = ''});

  /// BCP-47 tag as ML Kit uses it.
  final String code;
  final String name;

  /// Native name shown in the language sheet (e.g. Français).
  final String native;

  /// Optional emoji (unused in the UI).
  final String flag;
}

/// Phase 11: the two featured targets. Listed first and their models download right after onboarding.
/// Arabic is the default for new installs (`SettingsStore`).
const kFeaturedLangs = [
  Lang('ar', 'Arabic', 'العربية'),
  Lang('fr', 'French', 'Français', flag: '🇫🇷'),
];

/// Optional targets under "More languages"; their model downloads when picked.
const kMoreLangs = [
  Lang('es', 'Spanish', 'Español', flag: '🇪🇸'),
  Lang('de', 'German', 'Deutsch', flag: '🇩🇪'),
  Lang('pt', 'Portuguese', 'Português', flag: '🇵🇹'),
];

/// Every target. Adding one is one line above — ML Kit supports ~59, nothing else changes.
const kLangs = [...kFeaturedLangs, ...kMoreLangs];

/// Scripts written right to left (ML Kit codes). Drives `TextDirection` wherever translated text is shown.
bool isRtlLang(String code) => const {'ar', 'fa', 'he', 'ur'}.contains(code);

/// Direction for a text in [code]; null (= ambient) when unknown.
TextDirection? textDirectionFor(String? code) =>
    code == null ? null : (isRtlLang(code) ? TextDirection.rtl : TextDirection.ltr);

/// English is the reply direction and ML Kit's pivot; not offered as a target.
const kEnglish = Lang('en', 'English', 'English', flag: '🇬🇧');

String langName(String code) =>
    [...kLangs, kEnglish].where((l) => l.code == code).map((l) => l.name).firstOrNull ??
    code.toUpperCase();
