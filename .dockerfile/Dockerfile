
# /.dockerfile/Dockerfile

# Utilisation de l'image officielle PHP 8.3 avec Apache
FROM php:8.3-apache

# Récupération des arguments UID et GID passés par le docker-compose / Makefile
ARG UID=1000
ARG GID=1000

# ---------------------------------------------------------
# 1. Gestion des droits utilisateurs (KISS & DRY)
# ---------------------------------------------------------
# On modifie l'utilisateur natif 'www-data' (celui d'Apache)
# pour qu'il ait le même UID/GID que votre utilisateur Linux hôte.
RUN groupmod -g ${GID} www-data \
    && usermod -u ${UID} -g ${GID} www-data

# ---------------------------------------------------------
# 2. Dépendances système
# ---------------------------------------------------------
# Installation des librairies requises par les extensions PHP
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------
# 3. Extensions PHP (Spécifiques CakePHP 5.3)
# ---------------------------------------------------------
# Configuration et installation de l'extension 'intl' (obligatoire pour CakePHP)
RUN docker-php-ext-configure intl \
    && docker-php-ext-install intl pdo_mysql zip

# ---------------------------------------------------------
# 4. Outils de développement : Xdebug et PCOV
# ---------------------------------------------------------
# Xdebug sert au débogage interactif ; PCOV est réservé aux rapports de couverture.
# PCOV reste désactivé par défaut pour ne pas ralentir les commandes courantes.
RUN pecl install xdebug pcov \
    && docker-php-ext-enable xdebug pcov \
    && echo 'pcov.enabled=${PCOV_ENABLED}' > /usr/local/etc/php/conf.d/zz-pcov.ini

# Configuration de Xdebug pour se connecter automatiquement à VSCodium
RUN echo "xdebug.mode=debug,develop" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Rend Xdebug silencieux s'il ne trouve pas VSCodium
RUN echo "xdebug.log_level=0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# ---------------------------------------------------------
# 5. Serveur Web Apache
# ---------------------------------------------------------
# Activation de mod_rewrite, indispensable pour le routage de CakePHP
RUN a2enmod rewrite

# ---------------------------------------------------------
# 6. Composer
# ---------------------------------------------------------
# Installation globale de Composer en copiant le binaire depuis son image officielle
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# ---------------------------------------------------------
# 7. Finalisation
# ---------------------------------------------------------
# On s'assure que le dossier web appartient bien à notre utilisateur remappé
RUN chown -R www-data:www-data /var/www
