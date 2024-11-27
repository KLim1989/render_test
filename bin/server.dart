import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import 'dart:convert'; // For decoding JWT
import 'package:jose/jose.dart'; // For JWT verification
import 'package:http/http.dart' as http; // For HTTP requests

void main() async {
// Инициализация Firebase (замените на свои данные)
  final firebaseConfig = {
    "apiKey": "AIzaSyBodTVXEUFLFtA1Hi4Y7Ut6VHz6mEezlKs",
    "authDomain": "co-mobile-docs.firebaseapp.com",
    "projectId": "co-mobile-docs",
  };

  // Статические файлы
  final staticHandler = createStaticHandler(
    'app/public', // Папка с вашими файлами
    defaultDocument: 'login.html', // Главный файл
  );

  // Создание маршрутов
  final router = Router();

  // Обработчик главной страницы (login.html)
  router.get('/login.html', (Request request) {
    // Возвращаем login.html
    return staticHandler(request);
  });

  router.get('/protected.html', (Request request) async {
    final authHeader = request.headers['Authorization'];

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.found('/login.html');
    }

    final token = authHeader.substring(7); // Извлекаем токен
    print ('token is: $token');
    try {
      // Проверяем токен через Firebase Auth
      await verifyIdToken(token, firebaseConfig['projectId']!);

      return Response.found('/protected.html');
    } catch (e) {
      // Если токен недействителен, перенаправляем на /login.html
      return Response.found('/login.html');
    }
  });

  // Обработчик корневого URL (редирект на /login.html)
  router.get('/', (Request request) {
    return Response.found('/login.html');
  });

  // Добавляем обработку маршрутов в пайплайн
  final handler = Pipeline()
      .addMiddleware(logRequests()) // Логируем запросы
      .addHandler(router);

  // Запускаем сервер
  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Сервер запущен на http://${server.address.host}:${server.port}');
}

Future<void> verifyIdToken(String idToken, String projectId) async {
  // Step 1: Decode the token
  final parts = idToken.split('.');
  if (parts.length != 3) {
    throw Exception('Invalid ID token format.');
  }

  // Decode header and payload
  final header = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))));
  final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

  // Step 2: Validate Header Claims
  if (header['alg'] != 'RS256') {
    throw Exception('Invalid algorithm. Expected RS256.');
  }
  if (!header.containsKey('kid')) {
    throw Exception('Missing key ID (kid) in token header.');
  }

  // Step 3: Fetch Firebase public keys
  const googleCertsUrl = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';
  final response = await http.get(Uri.parse(googleCertsUrl));
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch public keys from Firebase.');
  }
  final publicKeys = json.decode(response.body) as Map<String, String>;

  // Get the key for the "kid" from the token header
  final kid = header['kid'];
  if (!publicKeys.containsKey(kid)) {
    throw Exception('Public key for key ID ($kid) not found.');
  }
  final publicKeyPem = publicKeys[kid]!;

  // Step 4: Verify Signature
  final key = JsonWebKey.fromPem(publicKeyPem);
  final jws = JsonWebSignature.fromCompactSerialization(idToken);
  final webKeySet = JsonWebKeyStore()..addKey(key);
  final isValid = await jws.verify(webKeySet);
  if (!isValid) {
    throw Exception('Invalid token signature.');
  }

  // Step 5: Validate Payload Claims
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000; // Current time in seconds since epoch
  if (payload['exp'] < now) {
    throw Exception('Token has expired.');
  }
  if (payload['iat'] > now) {
    throw Exception('Token issued-at time is in the future.');
  }
  if (payload['aud'] != projectId) {
    throw Exception('Invalid audience. Expected $projectId.');
  }
  if (payload['iss'] != 'https://securetoken.google.com/$projectId') {
    throw Exception('Invalid issuer. Expected https://securetoken.google.com/$projectId.');
  }
  if (payload['sub'] == null || payload['sub'].isEmpty) {
    throw Exception('Invalid subject claim.');
  }
  if (payload['auth_time'] > now) {
    throw Exception('Authentication time is in the future.');
  }

  // Step 6: Success
  print('Token is valid. User ID (sub): ${payload['sub']}');
}
