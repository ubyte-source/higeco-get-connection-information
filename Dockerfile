FROM amd64/alpine:3.17

ENV STARTUP_COMMAND_RUN_FASTCGIWRAP="fcgiwrap -c 5 -f -s unix:/home/www/fcgiwrap.socket" \
    STARTUP_COMMAND_RUN_PHP="php-fpm81 -F" \
    STARTUP_COMMAND_RUN_NGINX="nginx"

ARG PHP_FPM_USER="www" \
    PHP_FPM_GROUP="www" \
    PHP_FPM_LISTEN_MODE="0660" \
    PHP_MEMORY_LIMIT="128M" \
    PHP_MAX_UPLOAD="16M" \
    PHP_MAX_FILE_UPLOAD="1" \
    PHP_MAX_POST="32M" \
    PHP_DISPLAY_ERRORS="On" \
    PHP_DISPLAY_STARTUP_ERRORS="On" \
    PHP_ERROR_REPORTING="E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR" \
    PHP_FPM_CLEAR_ENVIRONMENT="no" \
    PHP_CGI_FIX_PATHINFO="0" \
    TIMEZONE="UTC"

RUN apk update && \
    apk add --no-cache nginx tzdata && \
    apk add --no-cache fcgiwrap bash jq curl openssl wget mysql-client ipcalc sshpass openssh && \
    apk add --no-cache php81 php81-fpm php81-openssl php81-zip php81-bcmath php81-curl php81-ctype php81-phar php81-common php81-mbstring php81-fileinfo php81-pecl-redis && \
    rm -rf /var/cache/apk/*

COPY ./source /app
COPY ./configurations /app/configurations
COPY ./handlers /app/handlers
COPY ./www /app/www
COPY ./ssl/certificate.key /etc/ssl/certificate.key
COPY ./ssl/certificate.pem /etc/ssl/certificate.pem
COPY nginx.conf /etc/nginx/nginx.conf
COPY wrapper.sh /

RUN adduser -D -g www www && \
    chown -R www:www /var/lib/nginx /var/log/nginx /app /var/log/php81 && \
    chmod +x /wrapper.sh /app && \
    rm -Rf /app/ssl /app/wrapper.sh /app/nginx.conf /etc/nginx/sites-enabled /etc/nginx/sites-available && \
    cp -r /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone

RUN sed -i "s|;*listen.owner\s*=\s*.*|listen.owner = ${PHP_FPM_USER}|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|;*listen.group\s*=\s*.*|listen.group = ${PHP_FPM_GROUP}|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|;*listen.mode\s*=\s*.*|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|;*clear_env\s*=\s*.*|clear_env = ${PHP_FPM_CLEAR_ENVIRONMENT}|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|;*user\s*=\s*.*|user = ${PHP_FPM_USER}|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|;*group\s*=\s*.*|group = ${PHP_FPM_GROUP}|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|;*log_level\s*=\s*.*|log_level = notice|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|;*display_errors\s*=\s*.*|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php81/php.ini && \
    sed -i "s|;*display_startup_errors\s*=\s*.*|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php81/php.ini && \
    sed -i "s|;*error_reporting\s*=\s*.*|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php81/php.ini && \
    sed -i "s|;*memory_limit\s*=\s*.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php81/php.ini && \
    sed -i "s|;*upload_max_filesize\s*=\s*.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php81/php.ini && \
    sed -i "s|;*max_file_uploads\s*=\s*.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php81/php.ini && \
    sed -i "s|;*post_max_size\s*=\s*.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php81/php.ini && \
    sed -i "s|;*cgi.fix_pathinfo\s*=\s*.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php81/php.ini && \
    sed -i "s|;*date.timezone\s*=\s*.*|date.timezone = ${TIMEZONE}|i" /etc/php81/php.ini

EXPOSE 8080/TCP 8443/TCP

USER www

ENTRYPOINT /wrapper.sh