import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final src = img.decodeImage(await File('assets/md2pdf.png').readAsBytes())!;
  final resized = img.copyResize(src, width: 192, height: 192);
  final canvas = img.Image(width: 288, height: 288);
  final x = (288 - 192) ~/ 2;
  final y = (288 - 192) ~/ 2;
  img.compositeImage(canvas, resized, dstX: x, dstY: y);
  await File('assets/splash_icon.png').writeAsBytes(img.encodePng(canvas));
  print('Created assets/splash_icon.png');
}
