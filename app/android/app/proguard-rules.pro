# Release (R8) keep rules.
#
# ML Kit (translate + language-id) registers its components through Firebase's ComponentDiscovery,
# which instantiates each registrar by reflection. R8 full mode strips the unused no-arg
# constructors → "NoSuchMethodException ... LanguageIdRegistrar.<init>" → Translator() NPE →
# the release APK crashed on launch (found 2026-10-18 before 1.0.0; debug builds don't minify).
-keep class * implements com.google.firebase.components.ComponentRegistrar { public <init>(); }
