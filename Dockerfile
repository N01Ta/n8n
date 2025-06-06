# Использовать версию Node.js, которая рекомендуется для n8n. 20 - хороший выбор.
ARG NODE_VERSION=20

# --- ЭТАП 1: Установка системных зависимостей ---
FROM node:${NODE_VERSION}-alpine AS builder

# Устанавливаем системные зависимости. Tini уже есть в базовом образе,
# поэтому убираем его из списка apk add, чтобы избежать конфликтов.
RUN apk add --no-cache --update git openssh graphicsmagick tzdata ca-certificates msttcorefonts-installer fontconfig && \
	update-ms-fonts && \
	fc-cache -f

# Установка pnpm
RUN npm install -g pnpm

# --- ЭТАП 2: Сборка приложения n8n ---
FROM builder AS build

WORKDIR /usr/src/app
COPY package.json pnpm-lock.yaml* ./
RUN pnpm fetch --prod
RUN pnpm install -r --prod --offline
COPY . .
RUN pnpm build

# --- ЭТАП 3: Финальный, легковесный образ для запуска ---
# Используем тот же самый базовый образ, в котором уже есть tini
FROM node:${NODE_VERSION}-alpine AS final

# Нам больше не нужно копировать tini, так как он уже есть в этом образе по пути /sbin/tini.
# Просто скопируем остальные нужные вещи из builder.
COPY --from=builder /usr/share/fonts/truetype/msttcorefonts/ /usr/share/fonts/truetype/msttcorefonts/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

WORKDIR /home/node
COPY --from=build /usr/src/app .
VOLUME /home/node/.n8n
EXPOSE 5678
USER node

# ИЗМЕНЕНИЕ: Указываем правильный путь к tini, который есть в базовом образе
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["n8n"]
