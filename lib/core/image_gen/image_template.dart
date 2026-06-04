import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';

class ImageTemplate {
  static const String _branding = 'AMBOT AI';

  static Future<String> applyWatermark(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) return imagePath;

    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final size = image.width > image.height ? image.width : image.height;

      final scaleFactor = size / 800;
      final fontSize = (14 * scaleFactor).clamp(14.0, 36.0);
      final padding = (12 * scaleFactor).clamp(12.0, 32.0);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      canvas.drawImage(image, ui.Offset.zero, ui.Paint());

      final textStyle = ui.TextStyle(
        color: const ui.Color(0x88FFFFFF),
        fontSize: fontSize,
        letterSpacing: 2.0,
      );
      final paragraphBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: ui.TextAlign.right,
          fontSize: fontSize,
        ),
      )
        ..pushStyle(textStyle)
        ..addText(_branding);
      final paragraph = paragraphBuilder.build()..layout(const ui.ParagraphConstraints(width: 200));

      final dx = image.width - paragraph.width - padding;
      final dy = image.height - paragraph.height - padding;

      final bgRect = ui.Rect.fromLTWH(dx - 6, dy - 4, paragraph.width + 12, paragraph.height + 8);
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(bgRect, const ui.Radius.circular(4)),
        ui.Paint()..color = const ui.Color(0x66000000),
      );
      canvas.drawParagraph(paragraph, ui.Offset(dx, dy));

      final picture = recorder.endRecording();
      final resultImage = await picture.toImage(image.width, image.height);
      final byteData = await resultImage.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      resultImage.dispose();

      if (byteData == null) return imagePath;

      final outDir = await getTemporaryDirectory();
      final outPath = '${outDir.path}/ambot_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(outPath).writeAsBytes(byteData.buffer.asUint8List());
      return outPath;
    } catch (_) {
      return imagePath;
    }
  }

  static Future<String> saveToGallery(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) return '';

    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/ambot_saved');
    if (!await dir.exists()) await dir.create(recursive: true);

    final ts = DateTime.now();
    final name = 'ambot_${ts.year}${_pad(ts.month)}${_pad(ts.day)}_${_pad(ts.hour)}${_pad(ts.minute)}${_pad(ts.second)}.png';
    final outPath = '${dir.path}/$name';
    await file.copy(outPath);
    return outPath;
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
