# Использовать версию Node.js, которая рекомендуется для n8n. 20 - хороший выбор.
ARG NODE_VERSION=20

# --- ЭТАП 1: Установка системных зависимостей ---
FROM node:${NODE_VERSION}-alpine AS builder

# ДОБАВЬТЕ ЭТУ СТРОКУ, ЧТОБЫ СБРОСИТЬ КЕШ
ARG CACHE_BUSTER=1

# Установка системных зависимостей, включая tini
RUN apk add --no-cache --update git openssh graphicsmagick tini tzdata ca-certificates msttcorefonts-installer fontconfig && \
	update-ms-fonts && \
	fc-cache -f

# Установка pnpm - стандартный менеджер пакетов для n8n
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
FROM node:${NODE_VERSION}-alpine AS final

COPY --from=builder /usr/bin/tini /usr/bin/tini
COPY --from=builder /usr/share/fonts/truetype/msttcorefonts/ /usr/share/fonts/truetype/msttcorefonts/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

WORKDIR /home/node
COPY --from=build /usr/src/app .
VOLUME /home/node/.n8n
EXPOSE 5678
USER node
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["n8n"]
