# ИСПОЛЬЗУЕМ ТОЛЬКО ОДИН ЭТАП
# Используем требуемую версию Node.js
ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-alpine

# Устанавливаем ВСЕ системные зависимости, но БЕЗ TINI
RUN apk add --no-cache --update git openssh graphicsmagick tzdata ca-certificates msttcorefonts-installer fontconfig && \
	update-ms-fonts && \
	fc-cache -f

# Устанавливаем pnpm
RUN npm install -g pnpm

# Устанавливаем рабочую директорию
WORKDIR /home/node

# Копируем ВЕСЬ код
COPY . .

# Устанавливаем ТОЛЬКО production-зависимости
RUN pnpm install -r --prod --frozen-lockfile --ignore-scripts

# Указываем, что данные n8n (воркфлоу, креды) должны храниться в этой папке.
VOLUME /home/node/.n8n

# Открываем порт
EXPOSE 5678

# Устанавливаем пользователя
USER node

# ЗАПУСКАЕМСЯ НАПРЯМУЮ ЧЕРЕЗ NODE
CMD ["node", "./packages/cli/bin/n8n"]
