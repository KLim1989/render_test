import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

void logCurrentDirectory() {
  print('Current working directory: ${Directory.current.path}');
}

void logParentDirectoryStructure() {
  final parentDir = Directory('../');
  print('Contents of ${parentDir.path}:');
  try {
    parentDir.listSync().forEach((entity) {
      print(entity.path);
    });
  } catch (e) {
    print('Error reading parent directory: $e');
  }
}

void main() async {

  logCurrentDirectory();
  logParentDirectoryStructure();
  // Укажите директорию для статических файлов
  final staticHandler = createStaticHandler(
    './public', // Папка для статических файлов
    defaultDocument: 'index.html', // Главный файл
  );

  // Оберните обработчик для улучшенной обработки ошибок
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(staticHandler);

  // Запустите сервер
  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Сервер запущен на http://${server.address.host}:${server.port}');
}
