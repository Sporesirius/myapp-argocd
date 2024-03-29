# Rebuild the source code only when needed
FROM node:16-alpine AS builder
RUN apk add --no-cache libc6-compat curl
RUN curl -f https://get.pnpm.io/v6.16.js | node - add --global pnpm

WORKDIR /app
COPY pnpm-lock.yaml ./

RUN pnpm fetch --prod

ADD . ./
RUN pnpm install -r --offline --prod

ENV NEXT_TELEMETRY_DISABLED 1

RUN pnpm build

# Production image, copy all the files and run next
FROM node:16-alpine AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
