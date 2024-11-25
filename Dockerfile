# Используем официальный Dart SDK образ
FROM dart:stable AS build

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем pubspec.* и устанавливаем зависимости
COPY pubspec.* .
RUN dart pub get

# Копируем весь проект в контейнер
COPY . .

# Собираем сервер
RUN dart compile exe bin/server.dart -o server

# Создаем минимальный образ для запуска
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/server

# Указываем порт
EXPOSE 8080

# Указываем команду запуска
CMD ["/app/server"]
