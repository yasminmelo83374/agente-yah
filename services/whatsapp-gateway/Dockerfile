FROM node:20-alpine

WORKDIR /app

RUN apk add --no-cache git

COPY package.json ./
RUN npm install

COPY src ./src

ENV ORCHESTRATOR_API_URL=http://orchestrator-api:8080

CMD ["npm", "start"]
