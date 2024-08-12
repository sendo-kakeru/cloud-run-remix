FROM node:20-slim AS base
WORKDIR /application
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV NODE_ENV=production

RUN corepack enable

# 依存関係のインストールステージ
FROM base AS deps
WORKDIR /application

# インストール
COPY package.json pnpm-lock.yaml* ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

# ビルドステージ
FROM base AS builder
WORKDIR /application
COPY . .
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
# ビルド
RUN pnpm run build

# 実行ステージ
FROM base AS runner
WORKDIR /application
# linuxのグループとユーザーを作成
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 remix

COPY package.json ./
COPY --from=builder /application/public ./public

RUN mkdir build
RUN chown remix:nodejs build

COPY --from=builder --chown=remix:nodejs /application/build/ ./build
COPY --from=deps /application/node_modules ./node_modules

USER remix

EXPOSE 3000

ENV PORT=3000

CMD ["pnpm", "run", "start"]
