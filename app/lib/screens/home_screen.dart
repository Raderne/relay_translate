import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../native/permissions.dart';
import '../routes.dart';
import '../theme/theme.dart';
import 'gallery.dart';

/// Thin landing until Phase 4 builds the settings screen.
/// Shows a warning row when overlay or accessibility was revoked.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const route = AppRoutes.home;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(RelayScope.of(context).refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = RelayScope.of(context).status;
    final warning = permissionWarning(status);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Relay', style: RelayType.brand),
              const SizedBox(height: 22),
              if (warning != null)
                _WarningRow(
                  text: warning,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.onboard2),
                ),
              const Spacer(),
              if (kDebugMode)
                RelayButton.ghost(
                  label: 'Gallery',
                  expand: true,
                  height: 40,
                  onPressed: () => Navigator.of(context).pushNamed(GalleryScreen.route),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarningRow extends StatelessWidget {
  const _WarningRow({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('permission-warning'),
      onTap: onTap,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: RelayColors.divider),
            bottom: BorderSide(color: RelayColors.divider),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(child: Text(text, style: RelayType.row)),
              const SizedBox(width: 10),
              const RelayIcon(RelayIcons.chevronRight, size: 18, color: RelayColors.accent700),
            ],
          ),
        ),
      ),
    );
  }
}
