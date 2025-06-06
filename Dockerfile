# Используем требуемую версию Node.js
ARG NODE_VERSION=22

# --- ЭТАП 1: Установка системных зависимостей ---
FROM node:${NODE_VERSION}-alpine AS builder

RUN apk add --no-cache --update git openssh graphicsmagick tzdata ca-certificates msttcorefonts-installer fontconfig && \
	update-ms-fonts && \
	fc-cache -f

RUN npm install -g pnpm

# --- ЭТАП 2: Установка зависимостей ---
FROM builder AS dependencies

WORKDIR /usr/src/app

COPY package.json pnpm-lock.yaml* ./
COPY patches ./patches
COPY scripts ./scripts

# Устанавливаем ТОЛЬКО production-зависимости, игнорируя dev-скрипты
RUN pnpm install -r --prod --frozen-lockfile --ignore-scripts

# --- ЭТАП 3: Финальный, легковесный образ для запуска ---
FROM node:${NODE_VERSION}-alpine AS final

# Копируем системные зависимости
COPY --from=builder /usr/share/fonts/truetype/msttcorefonts/ /usr/share/fonts/truetype/msttcorefonts/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

WORKDIR /home/node

# Копируем УЖЕ собранный код из вашего репозитория
COPY . .

# Копируем установленные на прошлом этапе зависимости
COPY --from=dependencies /usr/src/app/node_modules ./node_modules
# Копируем зависимости из всех под-пакетов
COPY --from=dependencies /usr/src/app/packages ./packages

VOLUME /home/node/.n8n
EXPOSE 5678
USER node
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["n8n"]
