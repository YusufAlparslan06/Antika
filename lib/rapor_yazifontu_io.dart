import 'dart:io';
import 'dart:typed_data';

Future<ByteData?> loadReportFont({required bool bold}) async {
  final fontNames = bold
      ? ['arialbd.ttf', 'segoeuib.ttf']
      : ['arial.ttf', 'segoeui.ttf'];
  final directories = <String>[
    if (Platform.isWindows) r'C:\Windows\Fonts',
    if (Platform.isLinux) '/usr/share/fonts/truetype/dejavu',
    if (Platform.isMacOS) '/System/Library/Fonts/Supplemental',
  ];

  for (final directory in directories) {
    for (final fontName in fontNames) {
      final file = File('$directory${Platform.pathSeparator}$fontName');
      if (await file.exists()) {
        return ByteData.sublistView(await file.readAsBytes());
      }
    }
  }

  return null;
}
