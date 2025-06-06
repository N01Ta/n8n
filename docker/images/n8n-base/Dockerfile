# Использовать версию Node.js, которая рекомендуется для n8n. 22 может быть слишком новой. 
# Лучше свериться с package.json вашего форка. Давайте для примера оставим 20.
ARG NODE_VERSION=20

# --- ЭТАП 1: Сборка зависимостей и окружения ---
FROM node:${NODE_VERSION}-alpine AS builder

# Установка системных зависимостей, как у вас и было
RUN apk add --update git openssh graphicsmagick tini tzdata ca-certificates libc6-compat jq msttcorefonts-installer fontconfig && \
	update-ms-fonts && \
	fc-cache -f

# Установка pnpm - стандартный менеджер пакетов для n8n
RUN npm install -g pnpm

# --- ЭТАП 2: Сборка самого приложения n8n ---
FROM builder AS build

# Устанавливаем рабочую директорию
WORKDIR /usr/src/app

# Копируем файлы с описанием зависимостей
COPY package.json pnpm-lock.yaml ./

# Устанавливаем только 'production' зависимости, чтобы образ был меньше
RUN pnpm install --prod --frozen-lockfile

# Копируем весь исходный код вашего форка в образ
COPY . .

# Запускаем команду сборки n8n
RUN pnpm build

# --- ЭТАП 3: Финальный, легковесный образ для запуска ---
FROM node:${NODE_VERSION}-alpine

# Копируем системные зависимости из первого этапа
COPY --from=builder /usr/bin/tini /usr/bin/tini
COPY --from=builder /usr/share/fonts/truetype/msttcorefonts/ /usr/share/fonts/truetype/msttcorefonts/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Устанавливаем рабочую директорию, куда будем копировать собранное приложение
WORKDIR /home/node

# Копируем собранное приложение из этапа 'build'
COPY --from=build /usr/src/app .

# Указываем, что данные n8n (воркфлоу, креды) должны храниться в этой папке.
# Это намек для Docker и платформ, что эту папку стоит выносить в volume.
VOLUME /home/node/.n8n

# Открываем порт, на котором работает n8n
EXPOSE 5678

# Устанавливаем пользователя, от которого будет работать приложение (безопасность)
USER node

# Команда для запуска n8n через 'tini' (для корректной обработки сигналов)
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["n8n"]
