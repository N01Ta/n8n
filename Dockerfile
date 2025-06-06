# Использовать версию Node.js, которая рекомендуется для n8n. 20 - хороший выбор.
ARG NODE_VERSION=20

# --- ЭТАП 1: Установка системных зависимостей ---
FROM node:${NODE_VERSION}-alpine AS builder

RUN apk add --no-cache --update git openssh graphicsmagick tzdata ca-certificates msttcorefonts-installer fontconfig && \
	update-ms-fonts && \
	fc-cache -f

RUN npm install -g pnpm

# --- ЭТАП 2: Сборка приложения n8n ---
FROM builder AS build

WORKDIR /usr/src/app

# ИЗМЕНЕНИЕ: Копируем не только package.json, но и всё, что нужно для установки,
# включая папку patches, если она есть.
COPY package.json pnpm-lock.yaml* ./
# Копируем папку с патчами ПЕРЕД установкой зависимостей
COPY patches ./patches

# Теперь установка зависимостей должна пройти успешно
RUN pnpm install -r --prod --frozen-lockfile

# Копируем весь остальной исходный код
COPY . .

# Запускаем команду сборки n8n
RUN pnpm build

# --- ЭТАП 3: Финальный, легковесный образ для запуска ---
FROM node:${NODE_VERSION}-alpine AS final

COPY --from=builder /usr/share/fonts/truetype/msttcorefonts/ /usr/share/fonts/truetype/msttcorefonts/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

WORKDIR /home/node
COPY --from=build /usr/src/app .
VOLUME /home/node/.n8n
EXPOSE 5678
USER node
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["n8n"]
