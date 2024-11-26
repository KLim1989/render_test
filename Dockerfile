# Используем официальный Dart SDK образ
FROM dart:stable AS build

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем весь проект в контейнер
COPY . .
RUN dart pub get

# Собираем сервер
RUN dart compile exe bin/server.dart -o server

# Создаем минимальный образ для запуска
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/server
COPY --from=build /app/public/ /app/public/

# Указываем порт
EXPOSE 8080

# Указываем команду запуска
CMD ["/app/server"]
