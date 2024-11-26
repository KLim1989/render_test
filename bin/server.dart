import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';


void main() async {

  // Укажите директорию для статических файлов
  final staticHandler = createStaticHandler(
    'app/public', // Папка для статических файлов
    defaultDocument: 'login.html', // Главный файл
  );

  // Оберните обработчик для улучшенной обработки ошибок
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(staticHandler);

  // Запустите сервер
  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Сервер запущен на http://${server.address.host}:${server.port}');
}
