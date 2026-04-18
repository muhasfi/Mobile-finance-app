import 'package:flutter/material.dart';
import 'package:finance_app_mobile/core/utils/bootstrap_icon_mapper.dart';

class IconCircle extends StatelessWidget {
  final String? icon;
  final Color? bgColor;

  const IconCircle({
    super.key,
    this.icon,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: bgColor ?? Colors.grey,
      child: Icon(
        BootstrapIconMapper.get(icon),
        color: Colors.white,
        size: 18,
      ),
    );
  }
}
