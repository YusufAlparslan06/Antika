import 'dart:typed_data';

import 'rapor_yazifontu_stub.dart'
    if (dart.library.io) 'rapor_yazifontu_io.dart'
    as implementation;

Future<ByteData?> loadReportFont({required bool bold}) {
  return implementation.loadReportFont(bold: bold);
}
