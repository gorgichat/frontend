# ---------- Build Stage ----------
FROM oven/bun:1 AS build
WORKDIR /usr/src/app

# install deps
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

# copy source
COPY . .

# build React app into dist/
RUN bun build ./src/index.html --outdir=dist --sourcemap --target=browser --minify

# ---------- Builder Stage ----------
FROM caddy:builder AS builder
RUN xcaddy build --with github.com/corazawaf/coraza-caddy/v2

# ---------- Runtime Stage ----------
FROM caddy:latest AS release
WORKDIR /usr/share/caddy

# Copy built Caddy binary (Coraza included)
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# Copy frontend files & configs
COPY --from=build /usr/src/app/dist ./ 
COPY Caddyfile /etc/caddy/Caddyfile
COPY ./coraza /etc/coraza/rules

# Format Caddyfile
RUN caddy fmt --overwrite /etc/caddy/Caddyfile

EXPOSE 80 8080 443
CMD ["caddy", "file-server", "--root", ".", "--listen", ":8080"]
