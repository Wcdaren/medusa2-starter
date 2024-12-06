FROM node:20-alpine AS base

FROM base AS builder
RUN apk update
RUN apk add --no-cache libc6-compat
WORKDIR /app
RUN yarn global add turbo@^2.1.2
COPY . .
RUN turbo prune medusa --docker

FROM base AS installer
WORKDIR /app
COPY --from=builder /app/out/json/ .
COPY --from=builder /app/out/yarn.lock ./yarn.lock
COPY --from=builder /app/.yarnrc.yml ./.yarnrc.yml 
COPY --from=builder /app/.yarn ./.yarn

RUN yarn install

COPY --from=builder /app/out/full/ .
RUN yarn turbo build --filter=medusa
RUN rm -rf node_modules/.cache .yarn/cache

FROM base AS runner
WORKDIR /app
COPY --chown=node:node --from=installer /app/ .

USER 1000
WORKDIR /app/apps/medusa
ENV PORT=80
CMD ["yarn", "start:prod"]