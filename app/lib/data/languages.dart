/// A language the user can pick as a translation target.
class Lang {
  const Lang(this.code, this.name, this.native, {this.flag = ''});

  /// BCP-47 tag as ML Kit uses it.
  final String code;
  final String name;

  /// Native name shown in the language sheet (e.g. Français).
  final String native;

  /// Optional emoji for the ML Kit spike screen.
  final String flag;
}

/// v1 target languages, from the prototype. Adding one is one line here —
/// ML Kit supports ~59, nothing else changes.
const kLangs = [
  Lang('fr', 'French', 'Français', flag: '🇫🇷'),
  Lang('es', 'Spanish', 'Español', flag: '🇪🇸'),
  Lang('de', 'German', 'Deutsch', flag: '🇩🇪'),
  Lang('pt', 'Portuguese', 'Português', flag: '🇵🇹'),
];

/// English is the reply direction and ML Kit's pivot; not offered as a target.
const kEnglish = Lang('en', 'English', 'English', flag: '🇬🇧');

String langName(String code) =>
    [...kLangs, kEnglish].where((l) => l.code == code).map((l) => l.name).firstOrNull ??
    code.toUpperCase();
