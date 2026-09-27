/// A language the user can pick as a translation target.
class Lang {
  const Lang(this.code, this.name, this.flag);

  /// BCP-47 tag as ML Kit uses it.
  final String code;
  final String name;
  final String flag;
}

/// v1 target languages, from the prototype. Adding one is one line here —
/// ML Kit supports ~59, nothing else changes.
const kLangs = [
  Lang('fr', 'French', '🇫🇷'),
  Lang('es', 'Spanish', '🇪🇸'),
  Lang('de', 'German', '🇩🇪'),
  Lang('pt', 'Portuguese', '🇵🇹'),
];

/// English is the reply direction and ML Kit's pivot; not offered as a target.
const kEnglish = Lang('en', 'English', '🇬🇧');

String langName(String code) =>
    [...kLangs, kEnglish].where((l) => l.code == code).map((l) => l.name).firstOrNull ??
    code.toUpperCase();
