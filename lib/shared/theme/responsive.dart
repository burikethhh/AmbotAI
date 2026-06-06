import 'package:flutter/material.dart';

enum DeviceType { phone, tablet, desktop }

DeviceType getDeviceType(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w >= 900) return DeviceType.desktop;
  if (w >= 600) return DeviceType.tablet;
  return DeviceType.phone;
}

bool isTabletOrWider(BuildContext context) =>
    MediaQuery.of(context).size.width >= 600;

int responsiveGridColumns(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w >= 1200) return 4;
  if (w >= 900) return 3;
  if (w >= 600) return 2;
  if (w >= 400) return 2;
  return 1;
}

double responsivePadding(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w >= 900) return 24;
  if (w >= 600) return 20;
  return 16;
}

double responsiveIconSize(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w >= 600) return 48;
  return 40;
}

double responsiveFontSize(double base, BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w >= 900) return base * 1.15;
  if (w >= 600) return base * 1.08;
  return base;
}
