import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'tokens.dart';

/// Lucide icons shipped as SVG so the stroke stays 1.5.
class RelayIcons {
  const RelayIcons._();

  static const languages = 'assets/icons/languages.svg';
  static const arrowLeft = 'assets/icons/arrow-left.svg';
  static const chevronRight = 'assets/icons/chevron-right.svg';
  static const x = 'assets/icons/x.svg';
  static const send = 'assets/icons/send.svg';
  static const mic = 'assets/icons/mic.svg';
  static const wifi = 'assets/icons/wifi.svg';
  static const battery = 'assets/icons/battery.svg';

  static const all = <String>[
    languages,
    arrowLeft,
    chevronRight,
    x,
    send,
    mic,
    wifi,
    battery,
  ];
}

class RelayIcon extends StatelessWidget {
  const RelayIcon(this.asset, {this.size = 20, this.color, super.key});

  final String asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? IconTheme.of(context).color ?? RelayColors.text;
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}
