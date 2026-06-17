FROM nginx:1.27-alpine

COPY docker/default.conf /etc/nginx/conf.d/default.conf
COPY docker/40-runtime-config.sh /docker-entrypoint.d/40-runtime-config.sh
RUN chmod +x /docker-entrypoint.d/40-runtime-config.sh

COPY . /usr/share/nginx/html

EXPOSE 80
