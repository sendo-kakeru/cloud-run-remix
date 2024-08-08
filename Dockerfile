FROM node:20.12.2-alpine3.18 AS base

# 依存関係のインストールステージ
FROM base AS deps
# alpineイメージの本番環境ではlibc6-compatの追加が推奨されている
RUN apk add --no-cache libc6-compat
WORKDIR /okashibu
# インストール
COPY package.json package-lock.json* ./
RUN npm ci

# ビルドステージ
FROM base AS builder
WORKDIR /okashibu
COPY --from=deps /okashibu/node_modules ./node_modules
COPY . .
# ビルド
RUN npm run build

# 実行ステージ
FROM base AS runner
WORKDIR /okashibu
ENV NODE_ENV production
# linuxのグループとユーザーを作成
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 remix

COPY --from=builder /okashibu/public ./public

RUN mkdir build
RUN chown remix:nodejs build

COPY --from=builder --chown=remix:nodejs /okashibu/build/ ./build

USER remix

EXPOSE 3000

ENV PORT=3000

CMD HOSTNAME="0.0.0.0" node /okashibu/build/server/index.js