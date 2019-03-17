#!/bin/bash

# /!\ fill required env vars in .env files before running this script

# setup volumes

docker volume create -d local -o type=none -o o=bind -o device=${VOLUME_PATH}seafile-db --name=seafile-db
docker volume create -d local -o type=none -o o=bind -o device=${VOLUME_PATH}seafile-data --name=seafile-data

# add block to lets encrypt nginx conf

echo ```
# seafile
server
{
	listen 443 ssl;

	root /config/www;
	index index.html index.htm index.php;

	server_name ${SEAFILE_DOMAIN};

	# all ssl related config moved to ssl.conf
	include /config/nginx/ssl.conf;

	client_max_body_size 0;

	location / {
		proxy_pass					http://seafile;
		proxy_set_header		Host $host;
		proxy_set_header		Forwarded "for=$remote_addr;proto=$scheme";
		proxy_set_header		X-Forwarded-For $remote_addr;
		proxy_set_header		X-Forwarded-Proto $scheme;
		proxy_set_header		X-Real-IP $remote_addr;
		proxy_set_header		Connection "";
		proxy_http_version	1.1;
		proxy_set_header		X-Forwarded-Proto https;
		proxy_read_timeout  1200s;

		access_log /var/log/nginx/seafile-access.log;
		error_log /var/log/nginx/seafile-error.log;
	}
}
``` >> ../reverse-proxy/nginx.conf

# run seafile docker and setup database

# fill required env vars in .env

echo "${SEAFILE_ADMIN_PASSWORD}" | docker secret create seafile_admin_password -
echo seafile && $SEAFILE_PRO_DOCKER_PASSWORD >> docker login docker.seadrive.org
docker-compose up -d
