# Используем требуемую версию Node.js
ARG NODE_VERSION=22

# --- ЭТАП 1: Установка системных зависимостей, ВКЛЮЧАЯ TINI ---
FROM node:${NODE_VERSION}-alpine AS builder

# Устанавливаем ВСЁ, что нужно, включая tini. Сами.
RUN apk add --no-cache --update git openssh graphicsmagick tini tzdata ca-certificates msttcorefonts-installer fontconfig && \
	update-ms-fonts && \
	fc-cache -f

RUN npm install -g pnpm

# --- ЭТАП 2: Сборка и установка ---
FROM builder AS build

WORKDIR /usr/src/app
COPY . .
RUN pnpm install -r --prod --frozen-lockfile --ignore-scripts

# --- ЭТАП 3: Финальный, легковесный образ для запуска ---
# Начинаем с чистого node:alpine, чтобы он был маленьким
FROM node:${NODE_VERSION}-alpine AS final

# КОПИРУЕМ TINI ИЗ BUILDER-А. Теперь мы ТОЧНО знаем, что он там есть.
COPY --from=builder /usr/bin/tini /usr/bin/tini
# Копируем и остальные системные зависимости
COPY --from=builder /usr/share/fonts/truetype/msttcorefonts/ /usr/share/fonts/truetype/msttcorefonts/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

WORKDIR /home/node
# Копируем наше приложение, собранное на этапе 'build'
COPY --from=build /usr/src/app .

VOLUME /home/node/.n8n
EXPOSE 5678
USER node

# Указываем ENTRYPOINT на тот путь, куда мы ТОЛЬКО ЧТО скопировали tini
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["n8n"]
