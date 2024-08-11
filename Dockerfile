FROM node:20.12.2-alpine3.18 AS base

# 依存関係のインストールステージ
FROM base AS deps
# alpineイメージの本番環境ではlibc6-compatの追加が推奨されている
RUN apk add --no-cache libc6-compat bash vim
WORKDIR /application
# インストール
COPY package.json package-lock.json* ./
RUN npm ci

# ビルドステージ
FROM base AS builder
WORKDIR /application
COPY --from=deps /application/node_modules ./node_modules
COPY . .
# ビルド
RUN npm run build

# 実行ステージ
FROM base AS runner
WORKDIR /application
ENV NODE_ENV production
# linuxのグループとユーザーを作成
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 remix

COPY --from=builder /application/public ./public
COPY package.json ./

RUN mkdir build
RUN chown remix:nodejs build

COPY --from=builder --chown=remix:nodejs /application/build/ ./build
COPY --from=deps /application/node_modules ./node_modules

USER remix

EXPOSE 3000

ENV PORT=3000

CMD HOSTNAME="0.0.0.0" node build/server/index.js
