# Configuration de l'image Docker (PHP 8.3 + Apache)

Ce dossier contient la recette de construction (`Dockerfile`) pour l'environnement de développement CakePHP 5.3.

## Principes (KISS & SOLID)
* **Responsabilité Unique :** Ce conteneur ne gère que PHP et le serveur web. La base de données est gérée séparément.
* **Image de base :** Nous utilisons `php:8.3-apache` (officielle) pour simplifier la configuration du serveur web avec CakePHP (`mod_rewrite` activé nativement).

## Gestion des droits (UID/GID)
Pour éviter que les fichiers générés par le conteneur (via Composer ou la console CakePHP) n'appartiennent à `root` sur la machine hôte, le `Dockerfile` remappe l'utilisateur `www-data` avec l'UID et le GID de l'utilisateur exécutant la commande `make`.

Ces arguments sont passés dynamiquement lors du build via le `Makefile`.
