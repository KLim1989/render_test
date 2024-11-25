# Используем официальный Dart SDK образ
FROM dart:stable AS build

RUN echo "details:" && ls -la

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем весь проект в контейнер
COPY . .
RUN echo "Contents of /app in final image:" && ls -la

RUN dart pub get

# Собираем сервер
RUN dart compile exe bin/server.dart -o server

# Создаем минимальный образ для запуска
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/server
COPY --from=build /app/public/ /app/public/

RUN echo "FROM scratch:" && ls -la

# Указываем порт
EXPOSE 8080

# Указываем команду запуска
CMD ["/app/server"]
