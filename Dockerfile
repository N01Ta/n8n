# ИСПОЛЬЗУЕМ ТОЛЬКО ОДИН ЭТАП
# Используем требуемую версию Node.js
ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-alpine

# Устанавливаем системные зависимости, НО БЕЗ TINI, чтобы обойти баг платформы
RUN apk add --no-cache --update git openssh graphicsmagick tzdata ca-certificates msttcorefonts-installer fontconfig && \
	update-ms-fonts && \
	fc-cache -f

# Устанавливаем pnpm и FULL-ICU
RUN npm install -g pnpm full-icu

# Устанавливаем рабочую директорию
WORKDIR /home/node

# Копируем ВЕСЬ код
COPY . .

# Устанавливаем ТОЛЬКО production-зависимости
RUN pnpm install -r --prod --frozen-lockfile --ignore-scripts

# ВАЖНО: Устанавливаем переменную для интернационализации
ENV NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu

# Указываем, что данные n8n (воркфлоу, креды) должны храниться в этой папке.
VOLUME /home/node/.n8n

# Открываем порт
EXPOSE 5678

# Устанавливаем пользователя
USER node

# ЗАПУСКАЕМСЯ НАПРЯМУЮ, БЕЗ TINI, чтобы обойти баг платформы
CMD ["node", "./packages/cli/bin/n8n"]
