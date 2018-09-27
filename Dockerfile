FROM php:7.1-fpm-jessie
MAINTAINER Camille Hougron <camille.hougron@gmail.com>

ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_CODENAME jessie
ENV TZ UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
	&& echo $TZ > /etc/timezone \
	&& dpkg-reconfigure -f noninteractive tzdata

# All things PHP
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
        git \
        vim \
        zlib1g-dev \
		libicu52 \
        libicu-dev \
		libpng-dev \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
		libmcrypt4 \
		libmcrypt-dev \
	&& apt-get clean all \
	&& docker-php-ext-enable \
		opcache \
	&& docker-php-ext-install \
		intl \
		zip \
		exif \
		gd \
		pdo \
		pdo_mysql \
		mcrypt \
	&& apt-get purge -y \
		zlib1g-dev \
		libicu-dev \
		libpng-dev \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
		libmcrypt-dev \
	&& apt-get autoremove -y

COPY php/sylius.ini /usr/local/etc/php/conf.d/sylius.ini

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

# All things composer
RUN php -r 'readfile("https://getcomposer.org/installer");' > composer-setup.php \
	&& php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
	&& rm -f composer-setup.php \
	&& chown www-data.www-data /var/www

ARG AS_UID=33

ENV BASE_DIR /var/www

#Modify UID of www-data into UID of local user
RUN usermod -u ${AS_UID} www-data

# Speedup composer
USER www-data
RUN composer global require hirak/prestissimo
USER root

WORKDIR ${BASE_DIR}

USER root

# Install yarn
RUN curl -sS http://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN curl -sL http://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs
RUN apt-get install yarn

COPY php/php-fpm.conf $PHP_INI_DIR/conf.d/