# Builder image
FROM node:16-alpine3.17 as builder

WORKDIR /app

COPY . .

RUN npm install && npm run build

# Runner image
FROM nginx:1.23-alpine as runner

COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 8081