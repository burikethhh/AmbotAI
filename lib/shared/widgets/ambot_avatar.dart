import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AmbotAvatar extends StatelessWidget {
  final double size;
  final bool isDark;

  const AmbotAvatar({
    super.key,
    this.size = 48,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final asset = isDark
        ? 'assets/avatar/ambot_avatar.svg'
        : 'assets/avatar/ambot_avatar_light.svg';

    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
