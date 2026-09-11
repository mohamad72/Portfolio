import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

@lazySingleton
class MarkdownFileWriter {
  const MarkdownFileWriter();

  Future<String> write({required String content}) async {
    final directory = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${directory.path}/portfolio-$stamp.md');
    await file.writeAsString(content, flush: true);
    return file.path;
  }
}
