# Référentiel des communes (zone de service)

`communes_fr.csv.gz` : une ligne par commune française (code INSEE, nom, codes postaux, latitude/longitude du
CENTRE de la commune). Ces coordonnées appartiennent au référentiel géographique : ce ne sont PAS des positions
d'utilisateurs, et aucune coordonnée d'utilisateur n'est jamais collectée ni stockée.

- **Source** : API « Découpage administratif » — https://geo.api.gouv.fr/communes (Etalab / DINUM), récupérée le 2026-10-06
  par `tools/build_service_area_data.py`.
- **Licence** : Licence Ouverte / Open Licence Etalab 2.0 pour les données de communes ; les rattachements aux codes
  postaux proviennent de la base de La Poste (voir les conditions de réutilisation sur
  https://geo.api.gouv.fr/decoupage-administratif). À reconfirmer avant toute diffusion commerciale élargie.
- **Mise à jour** : relancer le script ; le fichier est versionné pour que la soumission d'une demande ne dépende
  d'aucun service distant.
