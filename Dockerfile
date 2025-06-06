# Версия Node.js
ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-alpine

# 1. Устанавливаем системные зависимости
RUN apk add --no-cache --update git openssh graphicsmagick tzdata ca-certificates msttcorefonts-installer fontconfig && \
	update-ms-fonts && \
	fc-cache -f

# 2. Устанавливаем нужные npm-пакеты глобально
RUN npm install -g pnpm full-icu tini

# 3. Создаем рабочую директорию
WORKDIR /home/node

# 4. Копируем код приложения
COPY . .

# 5. Устанавливаем зависимости приложения
RUN pnpm install -r --prod --frozen-lockfile --ignore-scripts

# 6. Устанавливаем переменные окружения для запуска
ENV NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu

# 7. Объявляем том для данных
VOLUME /home/node/.n8n

# 8. Открываем порт
EXPOSE 5678

# 9. Устанавливаем пользователя для безопасности
USER node

# 10. Точка входа и команда
# Используем tini, который мы установили через npm. Он будет лежать в /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/tini", "--"]
CMD ["n8n"]
