# ADR 0001 — Séparation des dépôts et propriété de leur documentation

**Date :** 23 octobre 2026

**Statut :** Proposé

## Contexte

La racine versionne l’infrastructure locale Docker Compose et les commandes
Make. Le répertoire `app/` est un dépôt Git imbriqué, indépendant, qui versionne
l’application CakePHP et ses ADR. Le README racine décrivait encore la racine
comme un répertoire non versionné, ce qui rendait la propriété des décisions
d’infrastructure peu claire.

L’ADR applicatif 0021
(`app/docs/adr/0021-arborescence-documentation-applicative.md`) place les
décisions applicatives dans `app/docs/adr/`.

## Décision proposée

Conserver les deux dépôts Git indépendants. Versionner dans la racine les
documents qui décrivent son infrastructure et son organisation, notamment
les ADR dans `docs/adr/`. Conserver dans `app/docs/adr/` les décisions qui
concernent l’application et son architecture métier.

Chaque dépôt tient son propre index et sa propre numérotation d’ADR. Les
changements qui touchent les deux dépôts sont préparés et livrés sur des
branches distinctes, avec des commits propres à chaque historique.

## Conséquences

- Une décision d’infrastructure peut évoluer sans imposer une révision du
  dépôt applicatif.
- Les références entre dépôts sont documentaires : leur disponibilité dépend
  de la présence du répertoire `app/` dans le workspace.
- Les contributeurs consultent les ADR du dépôt concerné avant de modifier son
  contenu.
