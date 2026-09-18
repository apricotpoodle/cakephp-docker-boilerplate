# Instructions de contribution — GDAETF2

## Périmètre du dépôt

Ce workspace contient :

- l’infrastructure locale Docker Compose et le `Makefile` à la racine ;
- l’application CakePHP 5.3 dans `app/`, qui constitue un dépôt Git imbriqué ;
- les décisions d’architecture dans `app/docs/adr/`.

Avant toute modification applicative, consulter les ADR pertinents dans
`app/docs/adr/`. Les ADR au statut **Accepté** constituent les conventions
d’architecture en vigueur. Les ADR au statut **Proposé** donnent la direction
souhaitée ; signaler explicitement tout conflit, ambiguïté ou besoin de
validation avant de les appliquer largement.

## Commandes terminal et RTK

- Les agents Codex préfixent chaque commande shell par `rtk` afin de condenser
  les sorties sans changer le comportement ni le code de retour de la commande.
  Par exemple : `rtk git status`, `rtk make test.api` ou
  `rtk git -C app diff --check`.
- Dans une chaîne de commandes, conserver le préfixe sur chaque commande :
  `rtk git status && rtk git -C app status --short`.
- Si `rtk` n’est pas disponible dans l’environnement d’un contributeur, le
  signaler avant d’exécuter la commande sans ce préfixe ; ne pas référencer de
  chemin personnel ou de configuration locale dans les instructions versionnées.

## Principes généraux

- Employer le français pour l’interface utilisateur, les messages métier, les
  courriels, les descriptions TestDox, les assertions et les messages de commit.
  La locale applicative par défaut est `fr_FR`.
- Respecter DRY, KISS, SOLID et la séparation des responsabilités.
- Préférer une solution simple, cohérente avec les abstractions existantes,
  plutôt que du code dupliqué ou une nouvelle abstraction non justifiée.
- Ajouter PHPDoc aux éléments PHP publics ou complexes et JSDoc aux modules
  JavaScript publics ou complexes. Le typage doit satisfaire PHPStan.
- Respecter strictement PSR-4 : namespace, nom de classe et nom de fichier
  doivent correspondre, y compris dans leur casse.
- Ne pas modifier les dépendances (`composer.json`, lockfiles, assets tiers)
  ni lancer une mise à jour Composer sans nécessité explicite.
- Ne jamais introduire ou exposer de secret. Les paramètres sensibles viennent
  du fichier `.env` racine, non versionné, et des variables d’environnement.
- Ne jamais modifier le schéma, les migrations ou les vues SQL sans vérifier
  les ADR 0005 et 0006. Les vues MySQL sont gérées manuellement par SQL dans
  les migrations, jamais par génération automatique Phinx.

## Architecture CakePHP

- Utiliser une architecture « fat models, skinny controllers ».
- Les règles métier, validations, associations et filtrages de données
  appartiennent prioritairement aux Models / Tables / Services, pas aux
  contrôleurs ni aux templates.
- Les contrôleurs Web rendent les pages HTML ; les contrôleurs `Api`
  exposent les données et mutations JSON.
- Toute route, mutation ou donnée protégée doit appliquer l’autorisation
  serveur via les Policies ; un contrôle visuel côté interface ne suffit pas.
- Les restrictions de périmètre de données (départements, utilisateurs,
  formulaires) sont centralisées dans les custom finders ORM. Ne pas recréer
  ces filtres dans les contrôleurs.
- Les relations ORM multiples ou ambiguës nécessitent des alias sémantiques
  distincts ; ne pas dégrader le schéma pour contourner une limite de Bake.
- Après une modification importante d’associations ORM, prévoir une vérification
  d’intégrité appropriée, notamment via les tests d’intégration ou le REPL
  CakePHP décrit par l’ADR 0010.

## API, grilles et interface

- Pour les grilles Tabulator, conserver le traitement distant : pagination,
  tri et filtrage sont exécutés côté serveur via les adaptateurs dédiés.
- Réutiliser les abstractions existantes : `TabulatorAdapter`, Builder,
  Factory, Observer, fabriques de boutons et mécanismes de routage par
  métadonnées. Ne pas dupliquer cette logique dans une vue.
- Les scripts de comportement de page sont stockés dans
  `app/webroot/js/views/{domaine}/`. Les scripts inline dans les templates
  sont interdits.
- Dans les templates, utiliser la variable `$identity` fournie par `AppView`
  et son annotation de type appropriée ; ne pas relire directement l’identité
  depuis la requête.
- Les actions métier d’interface passent par les fabriques d’actions du domaine
  et `ActionHelper::render()`. Un template ne construit pas directement une
  route, un bouton métier ou une instance de `UiAction`.
- Les dépendances front-end sont hébergées localement dans
  `app/webroot/assets/`. Ne pas ajouter de CDN.
- Les messages Web et API destinés à l’utilisateur sont en français.
  Les erreurs de validation API suivent le contrat
  `{success, message, errors}` et utilisent HTTP 422 lorsque pertinent.
- Toute action liée à l’usurpation d’identité, à l’ACL, aux rôles, aux
  départements ou aux autorisations de champs doit recevoir une revue de
  sécurité particulièrement attentive.

## Documentation et ADR

- Documenter les changements structurants dans le README local pertinent
  (`src/`, `Controller/`, `Api/`, `Mailer/`, `Model/Table/`, JavaScript, etc.).
- Toute décision architecturale nouvelle ou évolution importante d’un patron
  existant doit être proposée sous forme d’ADR dans `app/docs/adr/`.
- Un nouvel ADR est numéroté séquentiellement, ajouté à
  `app/docs/adr/README.md`, créé avec le statut `Proposé`, puis soumis à revue.
- Ne pas modifier rétroactivement un ADR accepté pour masquer une divergence :
  créer un nouvel ADR qui l’amende ou le rend obsolète.

## Environnement et sécurité des tests

- Les commandes PHP, qualité et tests s’exécutent via le `Makefile` racine,
  donc dans le conteneur Docker `gdaetf`.
- Ne pas exécuter les outils PHP de qualité directement sur l’hôte lorsque
  l’équivalent `make` existe.
- Les tests unitaires ne doivent pas accéder à MySQL ni au réseau.
- Les tests d’intégration, fonctionnels HTTP et de workflow utilisent
  exclusivement la base MySQL dédiée `daetf2_test`, fournie par
  `DATABASE_TEST_URL`.
- Ne jamais exécuter une commande de test susceptible de reconstruire un
  schéma si `DATABASE_TEST_URL` ne cible pas explicitement la base de test.
- Ne pas utiliser SQLite comme substitut pour valider les comportements MySQL
  spécifiques, notamment les index et recherches FULLTEXT.

## Définition de « travail terminé »

Un changement est terminé uniquement lorsque :

1. le besoin utilisateur est couvert et les ADR applicables sont respectés ;
2. le code est typé, documenté et ne duplique pas une abstraction existante ;
3. les tests de non-régression nécessaires ont été ajoutés au niveau le plus
   bas pertinent :
   - entité, policy ou service : test unitaire ;
   - validation, association, finder ou requête : test d’intégration ORM ;
   - route, autorisation, réponse API ou contrôleur : test fonctionnel HTTP ;
4. les commandes de vérification adaptées au périmètre réussissent :
   - toujours pour une modification applicative : `make test.unit` ;
   - si PHP est modifié : `make cs.check` et `make stan` ;
   - si les tests sont modifiés : `make test.style` ;
   - si Models, migrations, finders ou SQL sont modifiés :
     `make test.integration` ;
   - si workflow ou vues SQL sont modifiés : `make test.workflow` ;
   - si contrôleurs Web ou API sont modifiés : `make test.api` ;
   - avant livraison d’une évolution transversale ou si le risque le justifie :
     `make test.all`.
5. les résultats des commandes exécutées, ou la raison précise de leur
   non-exécution, sont rapportés ;
6. la documentation locale et les ADR nécessaires sont mis à jour ;
7. le diff final ne contient aucun secret, fichier généré, cache, log ou
   modification étrangère à la demande.

## Git

- Le dépôt applicatif `app/` suit le Feature Branch Flow : ne pas développer
  directement sur `main`.
- Les branches suivent notamment `feature/`, `fix/` ou `refactor/`.
- Les commits sont atomiques et utilisent Conventional Commits, avec une
  description en français, par exemple :
  `feat(utilisateurs): ajoute le filtre par département`.
- Ne pas créer de branche, commit, push, pull request, fusion ou exécuter
  `finish_feature` sans confirmation explicite de l’utilisateur.
