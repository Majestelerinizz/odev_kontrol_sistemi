import 'package:flutter/material.dart';

enum AdminLayoutMode { mobile, tablet, desktop }

AdminLayoutMode layoutModeForWidth(double width) {
  if (width >= 1100) return AdminLayoutMode.desktop;
  if (width >= 768) return AdminLayoutMode.tablet;
  return AdminLayoutMode.mobile;
}

class AdminResponsive extends StatelessWidget {
  const AdminResponsive({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return switch (layoutModeForWidth(width)) {
      AdminLayoutMode.mobile => mobile,
      AdminLayoutMode.tablet => tablet,
      AdminLayoutMode.desktop => desktop,
    };
  }
}
