FROM ghcr.io/nodebb/nodebb:3.4.3

USER root

# Create directory to store config.json
RUN mkdir -p /etc/nodebb && chown node:node /etc/nodebb
ENV config=/etc/nodebb/config.json

RUN mkdir -p /usr/src/nodebb-plugin-passkeys
COPY --chown=node:node ./nodebb-plugin-passkeys /usr/src/nodebb-plugin-passkeys
RUN cd /usr/src/nodebb-plugin-passkeys && npm install

USER node

RUN npm install /usr/src/nodebb-plugin-passkeys

CMD test -e /etc/nodebb/config.json && ./nodebb build || (launchCmd='exit 0' ./nodebb build); ./nodebb start
