import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Overlay and accessibility, plus the first-run flag.
///
/// `onboarded` is a file in the app files directory until Phase 4's sqflite
/// `settings` row replaces it. Do not add `shared_preferences` for this.
class PermissionStatus {
  const PermissionStatus({required this.overlay, required this.accessibility, required this.onboarded});

  final bool overlay;
  final bool accessibility;
  final bool onboarded;

  bool get ready => overlay && accessibility;

  factory PermissionStatus.fromMap(Map<Object?, Object?> map) {
    return PermissionStatus(
      overlay: map['overlay'] == true,
      accessibility: map['accessibility'] == true,
      onboarded: map['onboarded'] == true,
    );
  }
}

/// What the Onboard 2 button does next. Overlay first; the disclosure is only
/// for accessibility, and only after the user taps.
enum PermissionStep { overlay, disclosure, home }

PermissionStep nextStep(PermissionStatus status) {
  if (!status.overlay) return PermissionStep.overlay;
  if (!status.accessibility) return PermissionStep.disclosure;
  return PermissionStep.home;
}

/// Home warning when a permission was revoked after onboarding. Null when both hold.
String? permissionWarning(PermissionStatus status) {
  if (status.overlay && status.accessibility) return null;
  if (!status.overlay && !status.accessibility) {
    return 'Display over other apps and screen text access are off';
  }
  if (!status.overlay) return 'Display over other apps is off';
  return 'Screen text access is off';
}

/// Exact wording from wiki Privacy and Permissions. Shown before accessibility settings.
const accessibilityDisclosure =
    "Relay uses Android's Accessibility service to read the text of messages on your screen, "
    'only when you hold the bubble or drop it on a message, and to paste replies you write '
    "into the app's message box. Translation happens on your phone. Your messages are not "
    "sent anywhere. Relay doesn't collect anything else from your screen.";

/// Pause after both permissions are granted, then Home. Matches the prototype.
const permissionGrantDelay = Duration(milliseconds: 650);

class Permissions {
  const Permissions({MethodChannel? channel}) : _channel = channel ?? Permissions.channel;

  static const channel = MethodChannel('relay/permissions');

  final MethodChannel _channel;

  Future<PermissionStatus> status() async {
    final raw = await _channel.invokeMethod<Map<Object?, Object?>>('status');
    return PermissionStatus.fromMap(raw ?? const {});
  }

  Future<void> openOverlay() => _channel.invokeMethod<void>('openOverlay');

  Future<void> openAccessibility() => _channel.invokeMethod<void>('openAccessibility');

  Future<void> setOnboarded() => _channel.invokeMethod<void>('setOnboarded');
}

class PermissionsController extends ChangeNotifier {
  PermissionsController(this.permissions, this.status);

  final Permissions permissions;
  PermissionStatus status;

  Future<void> refresh() async {
    status = await permissions.status();
    notifyListeners();
  }

  Future<void> markOnboarded() async {
    await permissions.setOnboarded();
    status = PermissionStatus(overlay: status.overlay, accessibility: status.accessibility, onboarded: true);
    notifyListeners();
  }
}

class RelayScope extends InheritedNotifier<PermissionsController> {
  const RelayScope({required PermissionsController controller, required super.child, super.key})
    : super(notifier: controller);

  static PermissionsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RelayScope>();
    assert(scope != null, 'RelayScope is missing above this widget');
    return scope!.notifier!;
  }
}
