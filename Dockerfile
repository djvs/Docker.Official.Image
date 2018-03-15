FROM node:8.9-slim

# crafted and tuned by pierre@ozoux.net and sing.li@rocket.chat
MAINTAINER buildmaster@rocket.chat

RUN groupadd -r rocketchat \
&&  useradd -r -g rocketchat rocketchat \
&&  mkdir -p /app/uploads \
&&  chown rocketchat.rocketchat /app/uploads

VOLUME /app/uploads

# gpg: key 4FD08014: public key "Rocket.Chat Buildmaster <buildmaster@rocket.chat>" imported
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 0E163286C20D07B9787EBE9FD7F9D0414FD08104

ENV RC_VERSION 0.62.2
ENV DIFF_COMMIT c2ae44f1ed978075a1314778a05d5ee14bf7fe26.diff

WORKDIR /app

RUN apt-get update
RUN apt-get install --yes git bsdtar
RUN export tar='bsdtar'

RUN curl -fSL "https://releases.rocket.chat/${RC_VERSION}/download" -o rocket.chat.tgz 
RUN curl -fSL "https://releases.rocket.chat/${RC_VERSION}/asc" -o rocket.chat.tgz.asc 
RUN gpg --batch --verify rocket.chat.tgz.asc rocket.chat.tgz
RUN tar zxf rocket.chat.tgz
RUN rm rocket.chat.tgz rocket.chat.tgz.asc

WORKDIR /app/bundle/programs
RUN wget "https://github.com/RocketChat/Rocket.Chat/commit/${DIFF_COMMIT}"
RUN git apply ${DIFF_COMMIT}

WORKDIR /app/bundle/programs/server
RUN npm install

USER rocketchat

WORKDIR /app/bundle

# needs a mongoinstance - defaults to container linking with alias 'db'
ENV DEPLOY_METHOD=docker-official \
    MONGO_URL=mongodb://db:27017/meteor \
    HOME=/tmp \
    PORT=3000 \
    ROOT_URL=http://localhost:3000 \
    Accounts_AvatarStorePath=/app/uploads

EXPOSE 3000

CMD ["node", "main.js"]
