# Версия Node.js
ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-alpine

# 1. Устанавливаем системные зависимости
RUN apk add --no-cache --update git openssh graphicsmagick tzdata ca-certificates msttcorefonts-installer fontconfig && \
	update-ms-fonts && \
	fc-cache -f

# 2. Устанавливаем нужные npm-пакеты глобально
RUN npm install -g pnpm full-icu

# 3. Создаем рабочую директорию
WORKDIR /home/node

# 4. Копируем код приложения
COPY . .

# 5. Устанавливаем зависимости приложения
RUN pnpm install -r --prod --frozen-lockfile --ignore-scripts

# 6. Устанавливаем переменную для интернационализации
ENV NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu

# 7. Меняем владельца всех файлов
#RUN chown -R node:node /home/node

# 8. Объявляем том для данных
VOLUME /home/node/.n8n

# 9. Открываем порт
EXPOSE 5678

# 10. Устанавливаем пользователя для безопасности
USER node

# 11. ФИНАЛЬНОЕ ИЗМЕНЕНИЕ: ЗАПУСКАЕМСЯ НАПРЯМУЮ С ФЛАГОМ --host
CMD ["node", "./packages/cli/bin/n8n", "start", "--host=0.0.0.0"]
