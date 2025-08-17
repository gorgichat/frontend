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

# ---------- Runtime Stage ----------
FROM caddy:latest AS release
WORKDIR /usr/share/caddy

# copy built files into Caddy web root
COPY --from=build /usr/src/app/dist ./ 

# caddy automatically serves ./ on :8080
EXPOSE 80
CMD ["caddy", "file-server", "--root", ".", "--listen", ":8080"]
