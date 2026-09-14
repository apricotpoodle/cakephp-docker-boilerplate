# Boilerplate Docker pour CakePHP

Ce répertoire fournit l'infrastructure locale d'une application CakePHP : PHP 8.3 avec Apache, Composer, Xdebug, PCOV, Mailpit, Docker Compose et commandes Make. Le code applicatif est monté dans `app/` et peut conserver son dépôt Git indépendant.

> Cette racine n'est pas encore un dépôt Git. Pour en faire un boilerplate réutilisable, initialisez un dépôt dédié après avoir vérifié son contenu et ajouté une politique adaptée pour le répertoire `app/`.

## Architecture

```text
.
├── .dockerfile/Dockerfile  Image PHP 8.3, Apache, Composer, Xdebug et PCOV
├── .env                   Configuration locale et secrets (non versionnée)
├── .env.example           Modèle de configuration sans secret
├── docker-compose.yml     Services PHP/Apache et Mailpit
├── Makefile               Commandes d'exploitation, qualité et tests
└── app/                   Application CakePHP et son dépôt Git propre
```

La base MySQL n'est volontairement pas définie dans `docker-compose.yml`. Elle est un service externe ou partagé, accessible avec les variables `DATABASE_URL` et `DATABASE_TEST_URL` du fichier `.env`.

## Prérequis

- Docker Engine et Docker Compose v2 ;
- GNU Make ;
- Git ;
- un serveur MySQL compatible avec l'application, accessible depuis le réseau Docker configuré ;
- les certificats locaux `localhost.crt` et `localhost.key` à la racine si HTTPS est utilisé.

## Installation

1. Créer la configuration locale et remplacer toutes les valeurs `CHANGE_ME_*` :

   ```bash
   cp .env.example .env
   ```

2. Placer ou cloner l'application CakePHP dans `app/`.

3. Vérifier que les bases de développement et de test existent et que leurs accès sont corrects. La base de test doit être distincte de toute base de développement, recette ou production.

4. Construire l'image et démarrer les services :

   ```bash
   make init
   ```

L'application est accessible sur `http://localhost:${FORWARD_APACHE_PORT}` et, si les certificats sont présents, sur `https://localhost:${FORWARD_APACHE_PORT_HTTPS}`. Mailpit est disponible sur `http://localhost:8025`.

## Configuration d'environnement

Le fichier `.env` est local et ne doit jamais être commité. Il contient notamment les accès MySQL, les paramètres SMTP et les clés CakePHP.

| Variable | Rôle |
| --- | --- |
| `PROJECT_NETWORK` / `PROJECT_SUBNET` | Réseau Docker externe du projet. |
| `FORWARD_APACHE_PORT` / `FORWARD_APACHE_PORT_HTTPS` | Ports HTTP et HTTPS publiés sur l'hôte. |
| `DATABASE_URL` | Connexion MySQL utilisée par l'application. |
| `DATABASE_TEST_URL` | Connexion MySQL réservée à PHPUnit ; elle doit viser `daetf2_test`. |
| `MAIL_*` | Paramètres du serveur SMTP ; Mailpit est proposé en local. |
| `SECURITY_SALT` / `SECURITY_CIPHERSEED` | Secrets CakePHP à générer pour chaque environnement. |

Exemples de génération de secrets :

```bash
openssl rand -hex 32
openssl rand -hex 16
```

Ne réutilisez jamais les valeurs fictives de `.env.example` et ne copiez jamais un fichier `.env` d'un autre environnement.

## Commandes courantes

| Commande | Effet |
| --- | --- |
| `make help` / `make menu` | Affiche toutes les commandes disponibles. |
| `make init` | Crée le réseau si nécessaire, construit l'image et démarre les services. |
| `make up` / `make down` | Démarre / arrête les conteneurs. |
| `make ps` / `make logs` | Affiche l'état / les journaux du service PHP. |
| `make php.bash` | Ouvre un shell dans le conteneur PHP. |
| `make composer.install` | Installe les dépendances de l'application. |
| `make db.migrate` / `make db.seed` | Applique les migrations / jeux de données CakePHP. |
| `make cs.check` / `make stan` | Lance PHP_CodeSniffer / PHPStan. |

## Tests

Les tests utilisant la base de données doivent impérativement viser MySQL `daetf2_test`. Chaque cible concernée applique ce garde-fou avant son exécution.

| Commande | Portée |
| --- | --- |
| `make test.unit` | Entités, politiques et services sans accès MySQL. |
| `make test.integration` | Tests ORM et fixtures MySQL. |
| `make test.api` | Tests HTTP des API et contrôleurs web. |
| `make test.workflow` | Workflow de validation et vues SQL. |
| `make test.all` | Suite PHPUnit complète avec le détail TestDox. |
| `make test.all.report` | Suite complète et rapport texte temporaire ouvert dans `$EDITOR`. |
| `make test.coverage` | Suite complète avec PCOV, rapports Clover et HTML. |
| `make test.coverage.clean` | Supprime les rapports de couverture temporaires. |
| `make test.style` | Vérifie le style des fichiers de test. |

### Couverture de code

`make test.coverage` active PCOV uniquement pour la durée de la mesure. Il produit :

- `clover.xml`, pour l'intégration continue et les outils d'analyse ;
- `html/index.html`, ouvert automatiquement avec `$BROWSER` ou `xdg-open`.

Les rapports sont copiés dans un répertoire `/tmp/daetf2-coverage.*` sur l'hôte. Les rapports âgés de plus de 24 heures sont supprimés au lancement suivant ; `make test.coverage.clean` les efface tous immédiatement.

Les commandes courantes désactivent Xdebug et PCOV afin de préserver leurs performances. Xdebug est réservé au débogage interactif.

## Git et réutilisation

Deux stratégies sont possibles :

1. garder `app/` comme dépôt Git imbriqué et versionner séparément l'infrastructure de cette racine ;
2. déclarer `app/` comme sous-module Git si l'infrastructure doit référencer une révision applicative précise.

Dans les deux cas, ne versionnez jamais `.env`, les certificats privés, les rapports de couverture ou les dépendances générées. Avant le premier commit du boilerplate, ajoutez un `.gitignore` correspondant à cette politique.

## Sécurité et exploitation

- Ne dirigez jamais `DATABASE_TEST_URL` vers une base non dédiée aux tests : PHPUnit peut reconstruire son schéma.
- Remplacez les secrets fictifs avant tout démarrage hors poste local.
- Limitez l'exposition des ports à l'environnement de développement.
- Renouvelez les clés CakePHP et identifiants de bases lors de la création d'un nouvel environnement.
- Reconstruisez l'image (`make init` ou `docker compose build`) après toute modification de `.dockerfile/Dockerfile`.
