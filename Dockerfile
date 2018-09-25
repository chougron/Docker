FROM sylius/nginx-php-fpm:latest
MAINTAINER Sylius Docker Team <docker@sylius.org>

ARG AS_UID=33

ENV BASE_DIR /var/www
ENV SYLIUS_DIR ${BASE_DIR}/sylius

#Modify UID of www-data into UID of local user
RUN usermod -u ${AS_UID} www-data

# Operate as www-data in SYLIUS_DIR per default
WORKDIR ${BASE_DIR}

USER root

# entrypoint.d scripts
COPY entrypoint.d/* /entrypoint.d/

# nginx configuration
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/sylius_params /etc/nginx/sylius_params

RUN chown www-data.www-data /etc/nginx/sylius_params

# Install yarn
RUN curl -sS http://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN curl -sL http://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs
RUN apt-get install yarn

# Install GD
RUN apt-get install -y libwebp-dev libjpeg-dev
RUN apt-get install -y libpng-dev
RUN apt-get install -y libxpm-dev
RUN apt-get install -y libfreetype6-dev
RUN docker-php-ext-configure gd \
    --with-freetype-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ \
    --with-xpm-dir=/usr/include \
    --with-webp-dir=/usr/include/
RUN docker-php-ext-install gd