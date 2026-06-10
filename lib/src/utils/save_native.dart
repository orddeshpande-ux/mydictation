import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> saveFile(String fileName, String content) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsString(content);
}
