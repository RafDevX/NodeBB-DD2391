FROM ghcr.io/nodebb/nodebb:3.4.3

USER root

# Create directory to store config.json
RUN mkdir -p /etc/nodebb && chown node:node /etc/nodebb

USER node
