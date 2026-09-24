FROM node:24-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY server.js ./
ARG APP_VERSION=dev
ENV APP_VERSION=$APP_VERSION PORT=3000
USER node
EXPOSE 3000
CMD ["node", "server.js"]
