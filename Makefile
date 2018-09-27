include .stub/*.mk

$(eval $(call defw,DOCKER_COMPOSE_LOCAL,docker-compose.local.yml))
$(eval $(call defw,PROJECT,sylius-standard))
$(eval $(call defw,NAME,$(PROJECT)))

UNAME_S := $(shell uname -s)

ifneq ("$(wildcard $(DOCKER_COMPOSE_LOCAL))","")
    DOCKER_COMPOSE_EXTRA_OPTIONS := -f $(DOCKER_COMPOSE_LOCAL)
endif

ifeq (Linux,$(UNAME_S))
    $(eval $(call defw,AS_UID,$(shell id -u)))
endif

# Deps
has_created_containers := $(shell docker ps -a -f "name=${NAME}" --format="{{.ID}}")


.PHONY: build
build:: ##@Docker Build the Sylius application image
	docker-compose build

.PHONY: up
up:: ##@Sylius Start the Sylius stack for development (using docker-compose)
	docker-compose \
		-f docker-compose.yml \
		-p $(PROJECT) \
		$(DOCKER_COMPOSE_EXTRA_OPTIONS) \
		up \
		--build

.PHONY: rm
rm:: ##@Compose Clean docker-compose stack
	docker-compose \
		rm \
		--force

ifneq ($(has_created_containers),)
	docker rm -f $(has_created_containers)
endif

.PHONY: install
install:: ##@Sylius Install the Sylius project
	docker exec \
        -ti \
        -u www-data \
        ${NAME}-app \
        php -d -1 /usr/local/bin/composer create-project \
        		sylius/plugin-skeleton \
        		syliusExtension \
			&& cd /var/www/syliusExtension/tests/Application \ 
			&& yarn install \
			&& yarn build \
        	&& chmod +x bin/console \
			&& bin/console assets:install public -e test \
			&& bin/console doctrine:database:create -e test \
			&& bin/console doctrine:schema:create -e test

.PHONY: shell
shell:: ##@Development Bring up a shell
	docker exec \
		-ti \
        -u www-data \
		${NAME}-app \
		bash

.PHONY: console
console:: ##@Development Call Symfony "console" with "console [<CMD>]"
	docker exec \
		-ti \
		-u www-data \
		${NAME}-app \
		sylius/bin/console $(CMD)
