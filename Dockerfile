# Используем требуемую версию Node.js
ARG NODE_VERSION=22

# --- ЭТАП 1: Установка системных зависимостей ---
FROM node:${NODE_VERSION}-alpine AS builder

RUN apk add --no-cache --update git openssh graphicsmagick tzdata ca-certificates msttcorefonts-installer fontconfig && \
	update-ms-fonts && \
	fc-cache -f

RUN npm install -g pnpm

# --- ЭТАП 2: Сборка и установка ---
# Мы будем делать всё на одном этапе для простоты
FROM builder AS build

WORKDIR /usr/src/app

# Копируем ВЕСЬ код СРАЗУ. Это решает все проблемы с поиском файлов.
COPY . .

# Устанавливаем ТОЛЬКО production-зависимости, игнорируя dev-скрипты.
# Turbo и lefthook не будут установлены.
RUN pnpm install -r --prod --frozen-lockfile --ignore-scripts

# ВАЖНО: Мы НЕ ЗАПУСКАЕМ `pnpm build`, так как `turbo` не установлен,
# и предполагается, что код в репозитории уже собран.

# --- ЭТАП 3: Финальный, легковесный образ для запуска ---
FROM node:${NODE_VERSION}-alpine AS final

# Копируем системные зависимости из первого этапа
COPY --from=builder /usr/share/fonts/truetype/msttcorefonts/ /usr/share/fonts/truetype/msttcorefonts/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

WORKDIR /home/node

# Копируем всё собранное приложение с установленными зависимостями из этапа 'build'
COPY --from=build /usr/src/app .

VOLUME /home/node/.n8n
EXPOSE 5678
USER node
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["n8n"]
