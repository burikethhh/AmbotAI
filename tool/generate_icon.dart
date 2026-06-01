// ignore_for_file: depend_on_referenced_packages, avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:math';

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // Dark background circle
  final bgColor = img.ColorRgba8(26, 26, 26, 255);
  final white = img.ColorRgba8(255, 255, 255, 255);
  final dimWhite = img.ColorRgba8(255, 255, 255, 80);
  final center = size ~/ 2;
  final radius = (size * 0.47).toInt();

  // Fill with transparent
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  // Draw filled circle for background
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x - center;
      final dy = y - center;
      if (dx * dx + dy * dy <= radius * radius) {
        image.setPixel(x, y, bgColor);
      }
    }
  }

  // Draw the "A" legs and crossbar using thick anti-aliased lines
  // Scale from SVG 512 coordinate space to 1024
  const scale = 1024.0 / 512.0;

  // Apex, left foot, right foot, crossbar endpoints (from SVG)
  final ax = (256 * scale).toInt(), ay = (90 * scale).toInt();
  final lx = (120 * scale).toInt(), ly = (312 * scale).toInt();
  final rx = (392 * scale).toInt(), ry = (312 * scale).toInt();
  final clx = (176 * scale).toInt(), cly = (220 * scale).toInt();
  final crx = (336 * scale).toInt(), cry = (220 * scale).toInt();

  // Draw thick lines
  _drawThickLine(image, lx, ly, ax, ay, 14, white);
  _drawThickLine(image, rx, ry, ax, ay, 14, white);
  _drawThickLine(image, clx, cly, crx, cry, 10, white);

  // Draw nodes
  _drawFilledCircle(image, ax, ay, 12, white);
  _drawFilledCircle(image, clx, cly, 7, dimWhite);
  _drawFilledCircle(image, crx, cry, 7, dimWhite);

  // Neural branches from apex
  _drawThickLine(image, ax, ay, (190 * scale).toInt(), (136 * scale).toInt(), 3, img.ColorRgba8(255, 255, 255, 50));
  _drawThickLine(image, ax, ay, (322 * scale).toInt(), (136 * scale).toInt(), 3, img.ColorRgba8(255, 255, 255, 50));
  _drawFilledCircle(image, (190 * scale).toInt(), (136 * scale).toInt(), 5, img.ColorRgba8(255, 255, 255, 50));
  _drawFilledCircle(image, (322 * scale).toInt(), (136 * scale).toInt(), 5, img.ColorRgba8(255, 255, 255, 50));

  // Encode as PNG
  final png = img.encodePng(image);
  File('assets/icon/app_icon.png').createSync(recursive: true);
  File('assets/icon/app_icon.png').writeAsBytesSync(png);
  print('Icon generated: assets/icon/app_icon.png (${png.length} bytes)');
}

void _drawThickLine(img.Image image, int x0, int y0, int x1, int y1, int thickness, img.Color color) {
  final half = thickness ~/ 2;
  final dx = x1 - x0;
  final dy = y1 - y0;
  final steps = max(dx.abs(), dy.abs());
  if (steps == 0) return;

  for (int i = 0; i <= steps; i++) {
    final x = x0 + (dx * i / steps).round();
    final y = y0 + (dy * i / steps).round();
    for (int oy = -half; oy <= half; oy++) {
      for (int ox = -half; ox <= half; ox++) {
        if (ox * ox + oy * oy <= half * half) {
          final px = x + ox;
          final py = y + oy;
          if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
            image.setPixel(px, py, color);
          }
        }
      }
    }
  }
}

void _drawFilledCircle(img.Image image, int cx, int cy, int r, img.Color color) {
  for (int y = cy - r; y <= cy + r; y++) {
    for (int x = cx - r; x <= cx + r; x++) {
      if ((x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          image.setPixel(x, y, color);
        }
      }
    }
  }
}
