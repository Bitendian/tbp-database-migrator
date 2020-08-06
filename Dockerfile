FROM node:10-alpine

COPY config/database.json /usr/src/app/database.json

COPY config/package.json /usr/src/app/package.json

RUN npm install
