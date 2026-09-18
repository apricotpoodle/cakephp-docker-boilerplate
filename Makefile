# ==============================================================================
# CONFIGURATION GÉNÉRALE
# ==============================================================================
# Charge automatiquement les variables du .env s'il existe
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

SHELL               := /bin/bash
.DEFAULT_GOAL       := help
.PHONY: help menu help.all help.docker help.tests help.maintenance setup init up down clean ps logs config network.list network.inspect network.create network.delete php.bash shell composer.install composer.update ide-helper.sync ide-helper.illuminate db.migrate db.seed cache.clear tree.check tree.check.departments tree.check.menus tree.check.config tree.alert.test cs.check cs.fix lint stan analyse test.unit test.quick test.database.check test.integration test.workflow test.api test.coverage test.coverage.clean test.all test.all.report test.style check

# ==============================================================================
# VARIABLES & COULEURS
# ==============================================================================
# Couleurs pour le terminal
ifneq (,$(findstring xterm,${TERM}))
	RED             := $(shell tput -Txterm setaf 1)
	GREEN           := $(shell tput -Txterm setaf 2)
	YELLOW          := $(shell tput -Txterm setaf 3)
	BLUE            := $(shell tput -Txterm setaf 6)
	PURPLE          := $(shell tput -Txterm setaf 5)
	RESET           := $(shell tput -Txterm sgr0)
else
	# Pas de couleurs si le terminal n'est pas compatible
	RED := ""; GREEN := ""; YELLOW := ""; BLUE := ""; PURPLE := ""; RESET := ""
endif

# Variables de configuration (avec valeurs par défaut si non définies dans .env)
PROJECT_NETWORK     ?= devfab
PROJECT_SUBNET      ?= 10.210.1.0/24
PHP_SERVICE_NAME    ?= gdaetf
IDE_HELPER_PATH     ?= src

# Variables dynamiques
UID                 := $(shell id -u)
GID                 := $(shell id -g)
# On exporte UID et GID pour que docker-compose les ait toujours à disposition
# et éviter les avertissements lors de commandes comme 'make clean'.
export UID GID

# Icônes
DOCKER_ICO          := ' \U1F40B '
NETWORK_ICO         := ' \U1F310 '
BASH_ICO            := ' \U1F41A '
DB_ICO              := ' \U1F4BE '
CAKE_ICO            := ' \U1F370 '
COMP_ICO            := ' \U1F3B5 '
LINT_ICO            := ' \U1F44D '
SUCCESS_ICO         := ' \U2705 '
INFO_ICO            := ' \U2139 '
WARN_ICO            := ' \U26A0 '
DELETE_ICO          := ' \U1F5D1 '

# ==============================================================================
# CATALOGUE COMPLET (make help.all)
# ==============================================================================
help.all:
	@printf "\n$(GREEN)Gestion du projet CakePHP $(PHP_SERVICE_NAME) avec Docker$(RESET)\n\n"
	@printf "$(PURPLE)Commandes principales :$(RESET)\n"
	@printf "  $(GREEN)make setup$(RESET)            Prépare l'environnement (réseau Docker).\n"
	@printf "  $(GREEN)make init$(RESET)             Initialise le projet (setup, build et up).\n"
	@printf "  $(GREEN)make up$(RESET)               Démarre les conteneurs.\n"
	@printf "  $(GREEN)make down$(RESET)             Arrête et supprime les conteneurs.\n"
	@printf "  $(GREEN)make clean$(RESET)            Nettoie les conteneurs (n'affecte plus le réseau).\n"
	@printf "\n$(PURPLE)Utilitaires Docker :$(RESET)\n"
	@printf "  $(GREEN)make ps$(RESET)               Affiche l'état des conteneurs.\n"
	@printf "  $(GREEN)make logs$(RESET)             Affiche les logs du service PHP.\n"
	@printf "  $(GREEN)make config$(RESET)           Valide et affiche la configuration Docker Compose.\n"
	@printf "\n$(PURPLE)Gestion du Réseau :$(RESET)\n"
	@printf "  $(GREEN)make network.list$(RESET)     Liste les réseaux Docker.\n"
	@printf "  $(GREEN)make network.inspect$(RESET)  Inspecte un réseau spécifique.\n"
	@printf "  $(GREEN)make network.create$(RESET)   Crée un nouveau réseau.\n"
	@printf "  $(GREEN)make network.delete$(RESET)   Supprime un réseau spécifique.\n"
	@printf "\n$(PURPLE)Application CakePHP :$(RESET)\n"
	@printf "  $(GREEN)make php.bash$(RESET)         Ouvre un terminal Bash dans le conteneur PHP.\n"
	@printf "  $(GREEN)make db.migrate$(RESET)       Applique les migrations de la base de données.\n"
	@printf "  $(GREEN)make db.seed$(RESET)          Remplit la base de données (seeds).\n"
	@printf "  $(GREEN)make cache.clear$(RESET)      Vide tous les caches de l'application.\n"
	@printf "\n$(PURPLE)Qualité de code & Dépendances :$(RESET)\n"
	@printf "  $(GREEN)make composer.install$(RESET) Installe les dépendances PHP.\n"
	@printf "  $(GREEN)make composer.update$(RESET)  Met à jour les dépendances PHP.\n"
	@printf "  $(GREEN)make ide-helper.sync$(RESET) Synchronise annotations et fichiers d'aide IDE.\n"
	@printf "  $(GREEN)make ide-helper.illuminate$(RESET) Applique les améliorations de code IDE Helper.\n"
	@printf "  $(GREEN)make cs.check$(RESET)         Vérifie le style du code (phpcs).\n"
	@printf "  $(GREEN)make cs.fix$(RESET)           Corrige le style du code (phpcbf).\n"
	@printf "  $(GREEN)make stan$(RESET)             Lance l'analyse statique du code (PHPStan).\n"
	@printf "  $(GREEN)make test.unit$(RESET)        Lance les tests unitaires sans accès à la base de données.\n"
	@printf "  $(GREEN)make test.integration$(RESET) Lance les tests ORM sur la base MySQL daetf2_test.\n"
	@printf "  $(GREEN)make test.all$(RESET)         Lance toute la suite PHPUnit avec le détail des scénarios.\n"
	@printf "  $(GREEN)make test.workflow$(RESET)    Lance les tests du workflow et des vues SQL.\n"
	@printf "  $(GREEN)make test.coverage$(RESET)    Produit les rapports Clover XML et HTML temporaires.\n"
	@printf "  $(GREEN)make test.coverage.clean$(RESET) Supprime les rapports de couverture temporaires.\n"
	@printf "  $(GREEN)make test.all.report$(RESET)  Lance la suite et ouvre un rapport temporaire nettoyé.\n"
	@printf "  $(GREEN)make test.style$(RESET)       Vérifie le style des tests via PHP_CodeSniffer.\n"
	@printf "  $(GREEN)make test.api$(RESET)         Lance les tests HTTP sur la base MySQL daetf2_test.\n"
	@printf "  $(GREEN)make test.database.check$(RESET) Vérifie que PHPUnit cible daetf2_test.\n"
	@printf "\n$(PURPLE)Maintenance des arbres :$(RESET)\n"
	@printf "  $(GREEN)make tree.check$(RESET)       Vérifie tous les arbres TreeBehavior sans les modifier.\n"
	@printf "  $(GREEN)make tree.check.departments$(RESET) Vérifie l’arbre des départements.\n"
	@printf "  $(GREEN)make tree.check.menus$(RESET) Vérifie l’arbre des menus.\n"
	@printf "  $(GREEN)make tree.check.config$(RESET) Vérifie la configuration des alertes TreeBehavior.\n"
	@printf "  $(GREEN)make tree.alert.test$(RESET)  Envoie une alerte marquée TEST, sans accéder aux arbres.\n"
	@printf "\n$(PURPLE)Navigation et alias :$(RESET)\n"
	@printf "  $(GREEN)make help$(RESET) / $(GREEN)menu$(RESET) / $(GREEN)help.tests$(RESET) / $(GREEN)help.maintenance$(RESET) / $(GREEN)help.docker$(RESET)\n"
	@printf "  $(GREEN)make shell$(RESET) (php.bash) / $(GREEN)make lint$(RESET) (cs.check) / $(GREEN)make analyse$(RESET) (stan)\n"
	@printf "  $(GREEN)make test.quick$(RESET) (test.unit) / $(GREEN)make check$(RESET)\n"

## menu: Alias de help, conserve la compatibilité avec les usages existants
menu: help

## help: Affiche les commandes les plus fréquentes
help:
	@printf "\n$(GREEN)GDAETF2 · environnement CakePHP/Docker$(RESET)\n\n"
	@printf "$(PURPLE)Démarrage :$(RESET)\n"
	@printf "  $(GREEN)make init$(RESET)        Construire et démarrer l'environnement.\n"
	@printf "  $(GREEN)make up$(RESET)          Démarrer les conteneurs.\n"
	@printf "  $(GREEN)make down$(RESET)        Arrêter les conteneurs.\n"
	@printf "  $(GREEN)make ps$(RESET)          Afficher leur état.\n"
	@printf "  $(GREEN)make logs$(RESET)        Suivre les journaux PHP.\n"
	@printf "\n$(PURPLE)Développement :$(RESET)\n"
	@printf "  $(GREEN)make shell$(RESET)       Ouvrir un shell dans le conteneur PHP.\n"
	@printf "  $(GREEN)make db.migrate$(RESET)  Appliquer les migrations.\n"
	@printf "  $(GREEN)make cache.clear$(RESET) Vider les caches CakePHP.\n"
	@printf "  $(GREEN)make ide-helper.sync$(RESET) Synchroniser les annotations et fichiers d'aide IDE.\n"
	@printf "  $(GREEN)make ide-helper.illuminate$(RESET) Appliquer les améliorations de code IDE Helper.\n"
	@printf "\n$(PURPLE)Vérifier avant livraison :$(RESET)\n"
	@printf "  $(GREEN)make check$(RESET)       Style, analyse statique et tests unitaires.\n"
	@printf "  $(GREEN)make test.quick$(RESET)  Lancer les tests unitaires.\n"
	@printf "  $(GREEN)make test.all$(RESET)    Lancer la suite PHPUnit complète.\n"
	@printf "\n$(PURPLE)Maintenance des arbres :$(RESET)\n"
	@printf "  $(GREEN)make tree.check.config$(RESET) Vérifier la configuration des alertes.\n"
	@printf "  $(GREEN)make tree.alert.test$(RESET)   Envoyer un courriel de test.\n"
	@printf "  $(GREEN)make tree.check$(RESET)        Vérifier les arbres sans les modifier.\n"
	@printf "\n$(PURPLE)Aide thématique :$(RESET)\n"
	@printf "  $(GREEN)make help.tests$(RESET)        Tests et rapports.\n"
	@printf "  $(GREEN)make help.maintenance$(RESET)  Maintenance et dépendances.\n"
	@printf "  $(GREEN)make help.docker$(RESET)       Docker et réseau.\n"
	@printf "  $(GREEN)make help.all$(RESET)          Catalogue complet.\n"

## help.tests: Affiche les commandes de test et de vérification
help.tests:
	@printf "\n$(GREEN)Tests et vérifications$(RESET)\n\n"
	@printf "  $(GREEN)make check$(RESET)            Style, PHPStan et tests unitaires.\n"
	@printf "  $(GREEN)make lint$(RESET)             Vérifie le style PHP (phpcs).\n"
	@printf "  $(GREEN)make analyse$(RESET)          Lance PHPStan.\n"
	@printf "  $(GREEN)make test.quick$(RESET)       Tests unitaires sans MySQL.\n"
	@printf "  $(GREEN)make test.integration$(RESET) Tests ORM sur daetf2_test.\n"
	@printf "  $(GREEN)make test.workflow$(RESET)    Tests workflow et vues SQL sur daetf2_test.\n"
	@printf "  $(GREEN)make test.api$(RESET)         Tests HTTP sur daetf2_test.\n"
	@printf "  $(GREEN)make test.all$(RESET)         Suite PHPUnit complète sur daetf2_test.\n"
	@printf "  $(GREEN)make test.coverage$(RESET)    Rapport de couverture PCOV temporaire.\n"
	@printf "  $(GREEN)make test.all.report$(RESET)  Suite complète avec rapport temporaire.\n"
	@printf "  $(GREEN)make test.style$(RESET)       Style des tests.\n"
	@printf "\n$(YELLOW)Les tests MySQL utilisent uniquement la base dédiée daetf2_test.\n$(RESET)"

## help.maintenance: Affiche les opérations occasionnelles ou sensibles
help.maintenance:
	@printf "\n$(GREEN)Maintenance et dépendances$(RESET)\n\n"
	@printf "  $(GREEN)make db.migrate$(RESET)          Applique les migrations de la base applicative.\n"
	@printf "  $(GREEN)make db.seed$(RESET)             Charge les jeux de données.\n"
	@printf "  $(GREEN)make cache.clear$(RESET)         Vide les caches CakePHP.\n"
	@printf "  $(GREEN)make composer.install$(RESET)    Installe les dépendances verrouillées.\n"
	@printf "  $(GREEN)make composer.update$(RESET)     Met à jour les dépendances Composer.\n"
	@printf "  $(GREEN)make ide-helper.sync$(RESET)     Synchronise annotations et fichiers d'aide IDE.\n"
	@printf "  $(GREEN)make ide-helper.illuminate$(RESET) Applique les améliorations de code IDE Helper.\n"
	@printf "  $(GREEN)make cs.fix$(RESET)              Corrige automatiquement le style PHP.\n"
	@printf "  $(GREEN)make test.coverage.clean$(RESET) Supprime les rapports PCOV temporaires.\n"
	@printf "\n$(PURPLE)Intégrité des arbres (lecture seule) :$(RESET)\n"
	@printf "  $(GREEN)make tree.check$(RESET)             Vérifie tous les arbres TreeBehavior.\n"
	@printf "  $(GREEN)make tree.check.departments$(RESET) Vérifie l'arbre des départements.\n"
	@printf "  $(GREEN)make tree.check.menus$(RESET)       Vérifie l'arbre des menus.\n"
	@printf "  $(GREEN)make tree.check.config$(RESET)      Vérifie la configuration des alertes.\n"
	@printf "  $(GREEN)make tree.alert.test$(RESET)        Envoie un courriel de test sans contrôler les données.\n"
	@printf "\n$(YELLOW)La récupération sera ajoutée séparément après validation humaine du diagnostic.\n$(RESET)"

## help.docker: Affiche les commandes Docker et réseau
help.docker:
	@printf "\n$(GREEN)Docker et réseau$(RESET)\n\n"
	@printf "  $(GREEN)make setup$(RESET)           Crée le réseau Docker externe si nécessaire.\n"
	@printf "  $(GREEN)make init$(RESET)            Construit l'image et démarre les conteneurs.\n"
	@printf "  $(GREEN)make up$(RESET)              Démarre les conteneurs.\n"
	@printf "  $(GREEN)make down$(RESET)            Arrête et supprime les conteneurs.\n"
	@printf "  $(GREEN)make clean$(RESET)           Arrête les conteneurs.\n"
	@printf "  $(GREEN)make ps$(RESET)              Affiche l'état des conteneurs.\n"
	@printf "  $(GREEN)make logs$(RESET)            Suit les journaux du service PHP.\n"
	@printf "  $(GREEN)make config$(RESET)          Valide la configuration Docker Compose.\n"
	@printf "  $(GREEN)make network.list$(RESET)    Liste les réseaux Docker.\n"
	@printf "  $(GREEN)make network.inspect$(RESET) Inspecte un réseau.\n"
	@printf "  $(GREEN)make network.create$(RESET)  Crée un réseau.\n"
	@printf "  $(GREEN)make network.delete$(RESET)  Supprime un réseau.\n"
	@printf "\n$(YELLOW)network.delete est destructif et demande une saisie interactive.\n$(RESET)"

# ==============================================================================
# COMMANDES DE GESTION DU PROJET
# ==============================================================================
## setup: Crée le réseau Docker externe si nécessaire, de manière automatique
setup:
	@printf "$(NETWORK_ICO)$(BLUE) Vérification du réseau Docker du projet...$(RESET)\n"
	@if [ -z "$$(docker network ls --filter name=^${PROJECT_NETWORK}$$ --format="{{ .Name }}")" ]; then \
		printf "$(INFO_ICO) Le réseau '${PROJECT_NETWORK}' n'existe pas. Création...\n"; \
		docker network create --driver=bridge --subnet=${PROJECT_SUBNET} ${PROJECT_NETWORK}; \
	else \
		printf "$(SUCCESS_ICO) Le réseau '${PROJECT_NETWORK}' existe déjà.\n"; \
	fi

## init: Initialise complètement le projet (dépend de setup)
init: setup
	@printf "$(DOCKER_ICO)$(BLUE) Construction et démarrage des conteneurs...$(RESET)\n"
	@docker compose build --build-arg UID=$(UID) --build-arg GID=$(GID)
	@docker compose up -d --remove-orphans

## up: Démarre les conteneurs
up:
	@printf "$(DOCKER_ICO)$(BLUE) Démarrage des conteneurs...$(RESET)\n"
	@docker compose up -d --remove-orphans

## down: Arrête et supprime les conteneurs
down:
	@printf "$(DOCKER_ICO)$(YELLOW) Arrêt et suppression des conteneurs...$(RESET)\n"
	@docker compose down

## clean: Arrête les conteneurs (NE supprime PAS le réseau)
clean: down
	@printf "$(DELETE_ICO)$(YELLOW) Nettoyage des conteneurs terminé.$(RESET)\n"

## ps: Affiche l'état des conteneurs du projet
ps:
	@printf "$(INFO_ICO)$(BLUE) État des conteneurs :$(RESET)\n"
	@docker compose ps

## logs: Affiche les logs du service principal
logs:
	@docker compose logs -f $(PHP_SERVICE_NAME)

## config: Valide et affiche la configuration Docker Compose
config:
	@printf "$(INFO_ICO)$(BLUE) Visualisation de la configuration Docker Compose compilée :$(RESET)\n"
	@docker compose config

# ==============================================================================
# COMMANDES DE GESTION DU RÉSEAU
# ==============================================================================
## network.list: Liste les réseaux Docker
network.list:
	@printf "$(NETWORK_ICO)$(BLUE) Liste des réseaux Docker actifs...$(RESET)\n"
	@docker network ls

## network.inspect: Inspecte un réseau Docker spécifique
network.inspect:
	@printf "$(NETWORK_ICO)$(BLUE) Inspection d'un réseau Docker...$(RESET)\n"
	@docker network ls
	@printf "\n"
	@read -p "Entrez le nom ou l'ID du réseau à inspecter: " network_name; \
	if [ -n "$$network_name" ]; then \
		docker network inspect $$network_name; \
	else \
		printf "$(WARN_ICO) Aucune saisie. Opération annulée.\n"; \
	fi

## network.create: Crée un nouveau réseau Docker
network.create:
	@printf "$(NETWORK_ICO)$(BLUE) Création d'un nouveau réseau Docker...$(RESET)\n"
	@read -p "Entrez le nom du nouveau réseau: " network_name; \
	if [ -n "$$network_name" ]; then \
		read -p "Entrez le sous-réseau (ex: 10.210.1.0/24) [défaut: ${PROJECT_SUBNET}]: " subnet; \
		subnet=$${subnet:-${PROJECT_SUBNET}}; \
		printf "$(INFO_ICO) Création du réseau '$$network_name' avec le sous-réseau '$$subnet'...\n"; \
		docker network create --driver=bridge --subnet=$$subnet $$network_name; \
	else \
		printf "$(WARN_ICO) Le nom du réseau ne peut pas être vide. Opération annulée.\n"; \
	fi

## network.delete: Supprime un réseau Docker
network.delete:
	@printf "$(DELETE_ICO)$(RED) Suppression d'un réseau Docker...$(RESET)\n"
	@docker network ls
	@printf "\n"
	@read -p "Entrez le nom ou l'ID du réseau à supprimer: " network_name; \
	if [ -n "$$network_name" ]; then \
		docker network rm $$network_name; \
	else \
		printf "$(WARN_ICO) Aucune saisie. Opération annulée.\n"; \
	fi

# ==============================================================================
# COMMANDES APPLICATIVES (CakePHP & Composer)
# ==============================================================================
## php.bash: Ouvre un terminal Bash dans le conteneur PHP
php.bash:
	@printf "$(BASH_ICO)$(BLUE) Ouverture d'un shell Bash dans le conteneur $(PHP_SERVICE_NAME)...$(RESET)\n"
	@docker compose exec -e XDEBUG_MODE=off -u www-data $(PHP_SERVICE_NAME) bash -l

## shell: Alias lisible de php.bash
shell: php.bash

## composer.install: Installe les dépendances Composer
composer.install:
	@printf "$(COMP_ICO)$(BLUE) Installation des dépendances Composer...$(RESET)\n"
	@docker compose exec -e XDEBUG_MODE=off -u www-data $(PHP_SERVICE_NAME) composer install --no-interaction --prefer-dist

## composer.update: Met à jour les dépendances Composer
composer.update:
	@printf "$(COMP_ICO)$(BLUE) Mise à jour des dépendances Composer...$(RESET)\n"
	@docker compose exec -e XDEBUG_MODE=off -u www-data $(PHP_SERVICE_NAME) composer update

## ide-helper.sync: Synchronise les annotations et fichiers d'aide IDE
ide-helper.sync:
	@printf "$(INFO_ICO)$(BLUE) Synchronisation des annotations IDE Helper...$(RESET)\n"
	@docker compose exec -u www-data $(PHP_SERVICE_NAME) bin/cake annotate all -r
	@docker compose exec -u www-data $(PHP_SERVICE_NAME) bin/cake generate code_completion
	@docker compose exec -u www-data $(PHP_SERVICE_NAME) bin/cake generate phpstorm

## ide-helper.illuminate: Applique les améliorations de code IDE Helper dans src/
ide-helper.illuminate:
	@printf "$(WARN_ICO)$(YELLOW) Application des améliorations de code IDE Helper dans $(IDE_HELPER_PATH)...$(RESET)\n"
	@docker compose exec -u www-data $(PHP_SERVICE_NAME) bin/cake illuminate code $(IDE_HELPER_PATH)

## db.migrate: Applique les migrations de la base de données
db.migrate:
	@printf "$(DB_ICO)$(BLUE) Application des migrations...$(RESET)\n"
	@docker compose exec -u www-data $(PHP_SERVICE_NAME) bin/cake migrations migrate

## db.seed: Remplit la base de données avec les données de test
db.seed:
	@printf "$(DB_ICO)$(BLUE) Remplissage de la base de données (seeding)...$(RESET)\n"
	@docker compose exec -u www-data $(PHP_SERVICE_NAME) bin/cake seed

## cache.clear: Vide tous les caches de l'application
cache.clear:
	@printf "$(DELETE_ICO)$(BLUE) Vidage des caches CakePHP...$(RESET)\n"
	@docker compose exec -u www-data $(PHP_SERVICE_NAME) bin/cake cache clear_all

# ==============================================================================
# MAINTENANCE DES ARBRES
# ==============================================================================
## tree.check: Vérifie toutes les tables utilisant TreeBehavior sans les modifier
tree.check:
	@docker compose exec -e XDEBUG_MODE=off -u www-data $(PHP_SERVICE_NAME) bin/cake tree integrity check

## tree.check.departments: Vérifie l'arbre des départements sans le modifier
tree.check.departments:
	@docker compose exec -e XDEBUG_MODE=off -u www-data $(PHP_SERVICE_NAME) bin/cake tree integrity check --table=departments

## tree.check.menus: Vérifie l'arbre des menus sans le modifier
tree.check.menus:
	@docker compose exec -e XDEBUG_MODE=off -u www-data $(PHP_SERVICE_NAME) bin/cake tree integrity check --table=menus

## tree.check.config: Vérifie la configuration des alertes TreeBehavior sans accéder aux données
tree.check.config:
	@docker compose exec -e XDEBUG_MODE=off -u www-data $(PHP_SERVICE_NAME) bin/cake tree integrity check --check-config

## tree.alert.test: Envoie une alerte de test sans interroger ni modifier les arbres
tree.alert.test:
	@docker compose exec -e XDEBUG_MODE=off -u www-data $(PHP_SERVICE_NAME) bin/cake tree integrity alert-test

# ==============================================================================
# COMMANDES DE QUALITÉ DE CODE
# ==============================================================================
## cs.check: Vérifie le style du code (PHP_CodeSniffer)
cs.check:
	@printf "$(INFO_ICO)$(BLUE) Vérification du style de code (phpcs)...$(RESET)\n"
	@docker compose exec -u www-data $(PHP_SERVICE_NAME) ./vendor/bin/phpcs

## lint: Alias lisible de cs.check
lint: cs.check

## cs.fix: Corrige automatiquement le style du code (PHP Code Beautifier)
cs.fix:
	@printf "$(LINT_ICO)$(BLUE) Correction automatique du style de code (phpcbf)...$(RESET)\n"
	@docker compose exec -u www-data $(PHP_SERVICE_NAME) ./vendor/bin/phpcbf

## stan: Lance l'analyse statique du code (PHPStan)
stan:
	@printf "$(INFO_ICO)$(BLUE) Lancement de l'analyse statique (PHPStan)...$(RESET)\n"
	@docker compose exec -u www-data $(PHP_SERVICE_NAME) test -x ./vendor/bin/phpstan || { echo "Erreur : PHPStan est absent du volume applicatif. Exécutez 'make composer.install' dans le conteneur, puis relancez cette commande."; exit 1; }
	@docker compose exec -u www-data $(PHP_SERVICE_NAME) ./vendor/bin/phpstan analyse

## analyse: Alias lisible de stan
analyse: stan

# ==============================================================================
# TESTS
# ==============================================================================
## test.unit: Lance les tests unitaires sans migration ni accès à la base de données
test.unit:
	@printf "$(CAKE_ICO)$(BLUE) Lancement des tests unitaires...$(RESET)\n"
	@docker compose exec -e XDEBUG_MODE=off -e APP_DEFAULT_LOCALE=fr_FR -u www-data $(PHP_SERVICE_NAME) ./vendor/bin/phpunit --no-configuration --bootstrap config/bootstrap.php --testdox tests/TestCase/Policy tests/TestCase/Model/Entity tests/TestCase/Model/Table/ApplicationformsValidationTest.php tests/TestCase/Model/Table/UsersValidationTest.php tests/TestCase/Model/Table/CommentsValidationTest.php tests/TestCase/Model/Table/DepartmentsTreeSelectTest.php tests/TestCase/Service

## test.quick: Alias lisible de test.unit
test.quick: test.unit

## check: Vérifie style, analyse statique et tests unitaires
check: lint analyse test.quick

## test.database.check: Vérifie que PHPUnit cible exclusivement la base MySQL daetf2_test
test.database.check:
	@docker compose exec -e XDEBUG_MODE=off -u www-data $(PHP_SERVICE_NAME) sh -lc 'case "$$DATABASE_TEST_URL" in */daetf2_test|*/daetf2_test\?*) ;; *) echo "Refus : DATABASE_TEST_URL doit cibler la base daetf2_test."; exit 1;; esac'
	@printf "$(SUCCESS_ICO) Base de test MySQL daetf2_test confirmée.\n"

## test.integration: Lance les tests ORM avec fixtures et migrations sur daetf2_test
test.integration: test.database.check
	@printf "$(CAKE_ICO)$(BLUE) Lancement des tests d'intégration ORM...$(RESET)\n"
	@docker compose exec -e XDEBUG_MODE=off -e APP_DEFAULT_LOCALE=fr_FR -u www-data $(PHP_SERVICE_NAME) ./vendor/bin/phpunit --testdox tests/TestCase/Model/Table

## test.workflow: Lance les tests du workflow de validation et des vues SQL sur daetf2_test
test.workflow: test.database.check
	@printf "$(CAKE_ICO)$(BLUE) Lancement des tests du workflow et des vues SQL...$(RESET)\n"
	@docker compose exec -e XDEBUG_MODE=off -e APP_DEFAULT_LOCALE=fr_FR -u www-data $(PHP_SERVICE_NAME) ./vendor/bin/phpunit --testdox tests/TestCase/Model/Table/ValidationWorkflowViewsTest.php

## test.api: Lance les tests d'intégration HTTP des API et contrôleurs web sur daetf2_test
test.api: test.database.check
	@printf "$(CAKE_ICO)$(BLUE) Lancement des tests d'intégration HTTP (API et web)...$(RESET)\n"
	@docker compose exec -e XDEBUG_MODE=off -e APP_DEFAULT_LOCALE=fr_FR -u www-data $(PHP_SERVICE_NAME) ./vendor/bin/phpunit --testdox tests/TestCase/Controller

## test.coverage: Produit les rapports Clover XML et HTML avec PCOV sur daetf2_test
test.coverage: test.database.check
	@find /tmp -mindepth 1 -maxdepth 1 -type d -name 'daetf2-coverage.*' -mmin +1440 -exec rm -rf -- {} +; \
	host_report_dir=$$(mktemp -d /tmp/daetf2-coverage.XXXXXX); \
	container_report_dir=$$(docker compose exec -T -e XDEBUG_MODE=off -e PCOV_ENABLED=1 -u www-data $(PHP_SERVICE_NAME) mktemp -d /tmp/daetf2-coverage.XXXXXX); \
	trap 'docker compose exec -T -u www-data $(PHP_SERVICE_NAME) rm -rf "$$container_report_dir" >/dev/null 2>&1' EXIT HUP INT TERM; \
	printf "$(CAKE_ICO)$(BLUE) Mesure de couverture avec PCOV...$(RESET)\n"; \
	docker compose exec -T -e XDEBUG_MODE=off -e PCOV_ENABLED=1 -e APP_DEFAULT_LOCALE=fr_FR -u www-data $(PHP_SERVICE_NAME) ./vendor/bin/phpunit --testdox --coverage-clover "$$container_report_dir/clover.xml" --coverage-html "$$container_report_dir/html"; \
	test_status=$$?; \
	if ! docker cp "$$(docker compose ps -q $(PHP_SERVICE_NAME)):$$container_report_dir/." "$$host_report_dir"; then \
		echo "Erreur : impossible de copier les rapports de couverture sur l'hôte."; \
		exit 1; \
	fi; \
	printf "$(SUCCESS_ICO) Rapports disponibles dans %s (clover.xml et html/index.html).\n" "$$host_report_dir"; \
	browser=$${BROWSER:-xdg-open}; \
	if command -v "$$browser" >/dev/null 2>&1; then \
		"$$browser" "$$host_report_dir/html/index.html" >/dev/null 2>&1 & \
		printf "$(INFO_ICO) Ouverture du rapport HTML avec %s.\n" "$$browser"; \
	else \
		printf "$(WARN_ICO) Navigateur introuvable : ouvrez %s manuellement.\n" "$$host_report_dir/html/index.html"; \
	fi; \
	exit "$$test_status"

## test.coverage.clean: Supprime les rapports PCOV temporaires présents sur l'hôte
test.coverage.clean:
	@find /tmp -mindepth 1 -maxdepth 1 -type d -name 'daetf2-coverage.*' -exec rm -rf -- {} +
	@printf "$(SUCCESS_ICO) Rapports de couverture temporaires supprimés.\n"

## test.all: Lance toute la suite PHPUnit avec le détail lisible des scénarios
test.all: test.database.check
	@printf "$(CAKE_ICO)$(BLUE) Lancement de la suite complète PHPUnit...$(RESET)\n"
	@docker compose exec -e XDEBUG_MODE=off -e APP_DEFAULT_LOCALE=fr_FR -u www-data $(PHP_SERVICE_NAME) ./vendor/bin/phpunit --testdox

## test.all.report: Lance toute la suite et ouvre un rapport temporaire nettoyé dans $EDITOR
test.all.report: test.database.check
	@raw_file=$$(mktemp /tmp/daetf2-phpunit-raw.XXXXXX.txt); \
	report_file=$$(mktemp /tmp/daetf2-phpunit.XXXXXX.txt); \
	trap 'rm -f "$$raw_file" "$$report_file"' EXIT HUP INT TERM; \
	printf "$(CAKE_ICO)$(BLUE) Lancement de la suite complète PHPUnit (rapport : %s)...$(RESET)\n" "$$report_file"; \
	docker compose exec -e XDEBUG_MODE=off -e APP_DEFAULT_LOCALE=fr_FR -u www-data $(PHP_SERVICE_NAME) ./vendor/bin/phpunit --testdox 2>&1 | tee "$$raw_file"; \
	test_status=$${PIPESTATUS[0]}; \
	if ! sed -E $$'s|\033\\[[0-9;?]*[[:alpha:]]||g' "$$raw_file" > "$$report_file"; then \
		echo "Erreur : impossible de nettoyer le rapport PHPUnit."; \
		exit 1; \
	fi; \
	rm -f "$$raw_file"; \
	if [ -z "$$EDITOR" ]; then \
		echo "Refus : configurez EDITOR avec un éditeur bloquant (ex. export EDITOR='code --wait')."; \
		exit 1; \
	fi; \
	printf "$(INFO_ICO) Ouverture du rapport nettoyé ; il sera supprimé à la fermeture de l'éditeur.\n"; \
	$$EDITOR "$$report_file"; \
	exit "$$test_status"

## test.style: Vérifie le style des fichiers de test via PHP_CodeSniffer
test.style:
	@printf "$(LINT_ICO)$(BLUE) Vérification du style des tests...$(RESET)\n"
	@docker compose exec -e XDEBUG_MODE=off -u www-data $(PHP_SERVICE_NAME) ./vendor/bin/phpcs --standard=phpcs.xml tests
