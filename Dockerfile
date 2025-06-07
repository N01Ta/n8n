# Версия Node.js
ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-alpine

# 1. Устанавливаем системные зависимости
RUN apk add --no-cache --update git openssh graphicsmagick tzdata ca-certificates msttcorefonts-installer fontconfig

# 2. Устанавливаем нужные npm-пакеты глобально
RUN npm install -g pnpm full-icu

# 3. Создаем рабочую директорию
WORKDIR /home/node

# 4. Копируем код приложения
COPY . .

# 5. Устанавливаем зависимости приложения
RUN pnpm install -r --prod --frozen-lockfile --ignore-scripts

# 6. Устанавливаем переменные окружения для запуска
ENV NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu

# 7. **ВАЖНОЕ ИЗМЕНЕНИЕ: Меняем владельца всех файлов**
# Это нужно сделать ПЕРЕД переключением на пользователя 'node'
RUN chown -R node:node /home/node

# 8. Объявляем том для данных
VOLUME /home/node/.n8n

# 9. Открываем порт
EXPOSE 5678

# 10. Устанавливаем пользователя для безопасности
USER node

# 11. Запускаемся напрямую, БЕЗ TINI, чтобы обойти баг платформы
CMD ["node", "./packages/cli/bin/n8n"]
