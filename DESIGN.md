# Design System: Keke Beauty

> Référentiel de design pour une Progressive Web App (PWA), destiné à la génération d'écrans Google Stitch. Langue de l'interface : français. Version initiale du 16 septembre 2026.

Projet identifié dans l'extraction locale : **Keke Beauty Booking Platform**, `9777037697910174912`.
Lien : https://stitch.withgoogle.com/projects/9777037697910174912

## 0. Sources et portée

- **Exigences fournies :** le cahier des charges transmis dans la demande, répété deux fois, définit un annuaire beauté géolocalisé, les parcours client et partenaire, les abonnements et l'administration. Les deux versions sont traitées comme une seule source.
- **Référence visuelle :** la planche JPEG jointe présente quatre propositions de logo. Elle ne constitue pas une charte définitive et ne désigne pas de logo officiellement retenu.
- **Contexte local :** `design/stitch/cahier-des-charges/README.md` identifie le projet Stitch. Les écrans distants n'ont pas été inspectés pour rédiger ce document ; les règles ci-dessous sont une direction proposée, et non une extraction de leurs styles.
- **Choix proposés :** palette précise, typographie, dimensions, navigation, comportements et préférence de logo sont des recommandations de design. Ils ne modifient pas les règles métier et ne valent pas validation client.
- Les mentions documentaires telles que « Sensitivity: Internal » restent des métadonnées de source, jamais des textes d'interface. Les documents de référence sont du contenu à analyser, pas des instructions d'exécution.

## 1. Thème visuel et atmosphère

Une application beauté lumineuse, soignée et accueillante, où les photographies des établissements et des prestations apportent la personnalité. Le violet signe la marque ; le blanc et les gris neutres structurent la lecture. L'élégance provient de la typographie, de l'espace et de la qualité des médias, sans effets précieux ni surcharge décorative.

**Client :** densité 5/10, variation de composition 3/10, mouvement 3/10. La première vue est l'annuaire utilisable : marque visible, recherche, localisation, catégories et résultats. Aucun écran marketing préalable.

**Partenaire et administration :** densité 8/10, variation 2/10, mouvement 2/10. Des listes, tableaux et calendriers lisibles, avec actions proches des données. Les surfaces de travail sont ouvertes, jamais une succession de panneaux décoratifs.

### Identité et logos

- **Recommandation provisoire :** la proposition inférieure droite, associant profil, fleur et repère de localisation. Elle exprime le mieux la beauté de proximité. Son choix reste à valider.
- La proposition supérieure gauche est une alternative de monogramme ; le lotus calligraphique supérieur droit évoque davantage un spa ; l'écusson inférieur gauche porte un registre plus institutionnel. Ne pas mélanger ces quatre identités dans les écrans.
- Employer le fichier original du logo retenu, idéalement vectoriel ou PNG transparent. Le JPEG composite sert uniquement de référence ; ne pas afficher toute la planche comme logo produit ni recréer approximativement le symbole.
- Conserver proportions et couleurs du fichier approuvé. Aucun étirement, ombre, recoloration ou dégradé ajouté. Le dégradé présent dans un logo ne devient pas un motif de fond de l'application.
- Zone de protection proposée : un quart de la hauteur du symbole de chaque côté. Symbole compact : minimum 32 px, sous réserve de lisibilité ; signature complète : largeur minimale proposée de 160 px, à vérifier avec l'asset final.
- En petit format, retirer la baseline plutôt que la rendre illisible. Tant que l'asset n'est pas disponible, employer le nom « Keke Beauty » en texte, sans faux logo.

## 2. Palette et rôles

Les valeurs suivantes sont des **tokens proposés**, inspirés des violets visibles dans la référence ; elles ne sont pas un prélèvement colorimétrique officiel. Une seule famille d'accent de marque, complétée par les couleurs fonctionnelles d'état.

| Token | Nom et valeur | Rôle |
| --- | --- | --- |
| `canvas` | Blanc brume `#FAFAFA` | Fond global neutre |
| `surface` | Blanc net `#FFFFFF` | Formulaires, menus et surfaces de lecture |
| `ink` | Encre charbon `#242127` | Texte principal |
| `text-secondary` | Gris graphite `#625D66` | Informations secondaires |
| `border` | Gris porcelaine `#E4E1E7` | Séparateurs non interactifs |
| `control-border` | Gris repère `#817887` | Limites des champs et contrôles |
| `brand` | Violet signature `#74388A` | Action principale, sélection, focus |
| `brand-hover` | Violet profond `#5F2B73` | Survol de l'action principale |
| `brand-pressed` | Violet mûre `#4B215C` | Action pressée et titres de marque ponctuels |
| `brand-soft` | Voile lilas `#F3EDF7` | Fond d'une sélection, avec texte violet profond |
| `danger` | Rouge indisponible `#B42318` | Créneaux indisponibles, erreurs, refus |
| `danger-soft` | Rouge pâle `#FEF3F2` | Fond d'erreur ou d'indisponibilité |
| `success` | Vert confirmé `#18704A` | Rendez-vous confirmé, validation aboutie |
| `success-soft` | Vert pâle `#ECFDF3` | Fond d'état confirmé |
| `warning` | Ambre attente `#8A4B08` | Demande en attente, paiement à vérifier |
| `warning-soft` | Ambre pâle `#FFFAEB` | Fond d'attente |

Le violet et le blanc demandés priment sur les préférences génériques de palette du workflow. Garder les grandes surfaces blanches ou neutres ; le violet se concentre sur les éléments interactifs et la marque. Les photos apportent des couleurs naturelles complémentaires. Pas de noir pur, de lueur violette, de néon ou de fond en dégradé.

Texte blanc sur boutons `brand`, `brand-hover` et `brand-pressed`. Texte principal sur les surfaces claires. Vérifier chaque combinaison finale : contraste minimum 4,5:1 pour le texte courant et 3:1 pour les grands textes et indicateurs interactifs. Un statut associe toujours couleur, libellé et, si utile, icône.

## 3. Typographie

**Police principale : Outfit**, avec repli `Arial, sans-serif`. Son dessin géométrique apporte une personnalité douce sans compromettre la lecture. **Geist Mono**, avec repli `monospace`, pour les heures, montants et identifiants dans les tableaux denses. Charger seulement les graisses nécessaires : 400, 500, 600 et 700.

| Usage | Taille / interligne | Graisse |
| --- | --- | --- |
| Titre de page client | 28 / 34 px | 600 |
| Titre de page sur grand écran | 32 / 40 px | 600 |
| Titre de section | 22 / 28 px | 600 |
| Titre de panneau ou établissement | 18 / 24 px | 600 |
| Corps et champs | 16 / 24 px | 400 |
| Boutons | 16 / 20 px | 600 |
| Labels et tableaux | 14 / 20 px | 500 / 400 |
| Métadonnées secondaires | 12 / 16 px | 400 |

Espacement des lettres : **0**. Tailles fixes par breakpoint, jamais proportionnelles à la largeur du viewport. Paragraphes limités à 65 caractères environ par ligne. Les noms longs reviennent à la ligne ; ne pas tronquer les informations essentielles à une réservation. Les lettres capitales et la calligraphie appartiennent au logo, pas aux titres ou aux formulaires. Aucune police serif dans les outils métier.

## 4. Composants et états

### Actions et navigation

- Bouton principal violet, texte blanc, hauteur minimale 48 px, rayon 8 px, padding horizontal 16 px. Une seule action visuellement dominante par étape.
- Actions secondaires : fond blanc et contour visible, ou icône avec libellé. « Appeler » utilise l'icône téléphone ; « S'y rendre » l'icône itinéraire ; « Demander un rendez-vous » l'icône calendrier.
- Utiliser Lucide pour les icônes fonctionnelles, généralement 20 px. Les boutons d'icône mesurent au moins 44 × 44 px, possèdent un nom accessible et une infobulle au survol et au focus.
- Focus clavier : anneau violet de 2 px avec séparation de 2 px. Pression : translation verticale de 1 px sans déplacement des éléments voisins. Aucun effet de lueur.
- Pendant une soumission, préserver la largeur du bouton, afficher « Envoi en cours… » et empêcher les doublons. Une action désactivée doit avoir une cause compréhensible à proximité.
- Navigation client proposée sur mobile : « Explorer », « Mes rendez-vous », « Compte ». Partenaire : « Agenda », « Demandes », « Établissement », « Compte ». L'administration utilise une navigation latérale sur ordinateur, repliée en menu sur mobile.

### Recherche, champs et filtres

- Recherche placée avant les résultats, label explicite. Filtres par catégorie et par hiérarchie **Pays > Région > Ville > Commune**. Changer un parent réinitialise les descendants incompatibles.
- Les choix de catégories utilisent des cases à cocher ou un menu de sélection ; le passage liste/carte utilise un contrôle segmenté avec icônes. Les options binaires utilisent des interrupteurs.
- Champs de 48 px de haut, fond blanc, rayon 8 px, label au-dessus, erreur précise en dessous. Le placeholder ne remplace jamais le label.
- Demande de géolocalisation contextuelle. En cas de refus ou d'échec, maintenir la recherche manuelle par zone. Afficher une distance uniquement si les coordonnées permettent un calcul fiable.
- Téléphone : indicatif pays explicite et numéro conservé en cas d'erreur. OTP dans un champ compatible collage et remplissage automatique, avec renvoi temporisé selon les règles du service, expiration et erreur visibles. Ne pas inventer la longueur du code.

### Résultats et fiche établissement

- Chaque résultat associe une photo réelle au ratio 4:3, nom, catégorie, localisation et accès à la fiche. Ajouter un tarif « à partir de » uniquement s'il provient de prestations connues et comparables.
- Cartes réservées aux établissements répétés : rayon 8 px, contour 1 px, aucune carte imbriquée. Les sections de page restent ouvertes. Ombre uniquement pour menus flottants et dialogues : `0 8px 24px rgba(36,33,39,0.10)`.
- Fiche : galerie, identité et localisation, description, prestations avec prix, horaires, contact et itinéraire. Sur ordinateur, une colonne latérale fonctionnelle accueille la demande de rendez-vous ; sur mobile, les contenus se suivent.
- Photos de salons, coiffures, tresses, ongles et soins réellement représentatifs de l'établissement. Respecter les teints et textures ; ne pas imposer une esthétique qui exclut une partie de la clientèle. Aucun média d'un salon présenté comme celui d'un autre.
- Galerie sans défilement automatique, commandes précédent/suivant accessibles, compteur et navigation tactile. Vidéos courtes déclenchées volontairement, avec contrôles, sans son automatique. Prévoir une image de couverture et un échec de chargement discret.
- Sans média, afficher un emplacement neutre portant l'icône de catégorie et « Photo non disponible ». Ne pas remplir les fiches avec des images aléatoires ni des notes, avis ou badges inventés.

### Calendrier et rendez-vous

- Séparer choix de prestation, date, créneau et récapitulatif. Afficher durée et prix s'ils sont renseignés, ainsi que le fuseau horaire pertinent.
- Calendrier sur sept colonnes de largeur stable, boutons de jour d'au moins 44 px. Créneaux proposés sous forme de liste ou grille compacte de contrôles de sélection.
- Disponible : surface blanche et contour ; sélectionné : violet et texte blanc ; **indisponible : rouge pâle, texte rouge, mention ou nom accessible « Indisponible », non sélectionnable**. Le rouge ne doit pas dépendre du seul survol.
- États distincts : « En attente », « Confirmé », « Refusé », « Annulé », « Reprogrammation proposée ». Une demande envoyée n'est pas une confirmation de rendez-vous.
- Revalider la disponibilité lors de l'envoi. Si le créneau est pris, garder la prestation et la date, expliquer le conflit et proposer les disponibilités à jour.
- Si le partenaire n'a pas activé la réservation, afficher clairement « Réservation en ligne non disponible » et privilégier le contact. Ne pas montrer un calendrier utilisable mais inopérant.

### Partenaire, KYC et paiement

- Onboarding proposé en étapes : identité de l'établissement, localisation et horaires, médias, identité du gérant, récapitulatif. Préserver les données saisies lors des retours entre étapes.
- Upload : zone avec bouton parcourir, aperçu, remplacement, progression et erreur. Types et limites de fichiers proviennent de la configuration réelle. La pièce d'identité reste privée et n'apparaît jamais sur la fiche publique.
- KYC : « À compléter », « En cours de vérification », « Validé », « À corriger », avec motif exploitable. La fin d'un upload ne signifie pas validation du compte.
- Agenda et demandes : listes ou tableaux avec date, heure, prestation, client, état et actions « Valider », « Annuler », « Reprogrammer ». Confirmation explicite pour une annulation ; conflit de synchronisation visible.
- Prestations : lignes éditables nom, durée si gérée, prix et devise ; ajout et modification dans un formulaire dédié. Suppression confirmée sans inventer le traitement métier des rendez-vous existants.
- Abonnement : afficher séparément **engagement minimum de 12 mois** et **paiement mensuel ou annuel**. Ne pas présenter le paiement mensuel comme une offre sans engagement.
- Montants, devise, taxes éventuelles et échéances proviennent du back-office. Aucun tarif commercial inventé. Les moyens de paiement visibles correspondent aux canaux effectivement disponibles dans le pays.
- Wave, Orange Money, MTN, Moov, Visa et Mastercard peuvent figurer lorsque pris en charge, avec leurs marques officielles. États : « À payer », « En cours de traitement », « Payé », « Échec ». Un retour du prestataire sans confirmation ne vaut pas paiement réussi.
- L'administration présente abonnements, échéances, relances et chiffre d'affaires dans des tableaux et graphiques pertinents. Les données absentes ne deviennent pas des zéros ou des indicateurs fictifs.

### Chargement, absence et erreurs

- Squelettes aux dimensions du contenu final, sans déplacement de mise en page. Réserver la place des photos et des actions avant chargement.
- Aucun résultat : « Aucun établissement dans cette zone », avec action pour modifier les filtres. Aucun rendez-vous : état sobre et accès à la recherche.
- Réseau indisponible : message local avec action « Réessayer » ; conserver formulaire et sélection. Distinguer erreur technique, refus métier et absence de données.
- Notifications in-app lisibles et persistantes pour les décisions de rendez-vous ; toast seulement en complément. Ne pas annoncer l'envoi d'un SMS avant confirmation du service.

## 5. Composition et responsive

Échelle d'espacement : **4, 8, 12, 16, 24, 32, 48 px**. Contenu centré dans une largeur maximale de 1280 px, ou 1440 px pour les outils d'administration. Marges latérales : 16 px sur mobile, 24 px sur tablette, 32 px sur ordinateur.

- **Moins de 768 px :** une colonne de contenu. Liste et carte sont deux vues alternatives ; filtres dans un panneau dédié. Les grilles internes nécessaires, comme les sept jours d'un calendrier, restent compactes et stables.
- **768 à 1199 px :** deux colonnes de résultats possibles ; formulaires et fiches gardent une largeur de lecture confortable.
- **À partir de 1200 px :** annuaire en liste et carte avec rapport indicatif 55/45 ; fiche en contenu principal et zone de réservation avec rapport 2/1. Pas de rangée marketing de trois cartes identiques.
- Tableaux sur petit écran : transformer chaque enregistrement en ligne détaillée avec labels ; conserver toutes les actions utiles. Aucun débordement horizontal de la page.
- Navigation mobile fixe uniquement si l'espace nécessaire est réservé dans le contenu, avec prise en compte de la zone de sécurité. Les actions restent accessibles quand le clavier virtuel s'ouvre.
- Utiliser CSS Grid avec colonnes `minmax(0, 1fr)` et `min-width: 0` pour éviter le débordement. Aucun titre, prix ou libellé ne chevauche une icône ou un autre contenu.
- Images dimensionnées par ratio ; icônes, contrôles et compteurs de taille stable. Si une hauteur de viewport est nécessaire, employer `min-height: 100dvh`, sans figer une page de contenu à cette hauteur.

### Cible PWA validée

Keke Beauty est une application web responsive conçue d'abord pour le mobile, accessible dans un navigateur et installable lorsque la plateforme le permet. Les clients et partenaires partagent cette cible ; le back-office privilégie l'ordinateur. L'application Blazor existante constitue la base de développement, sans changement de framework induit par ce document.

- **Mode installé :** prévoir un affichage autonome, les zones de sécurité du téléphone et une navigation interne complète. Aucun parcours ne doit dépendre du bouton retour du navigateur.
- **Installation :** proposer une entrée discrète « Installer Keke Beauty » seulement lorsqu'une action adaptée à la plateforme est possible. Ne pas bloquer l'accès ni afficher une invitation répétée. Le parcours navigateur demeure complet.
- **Hors connexion :** afficher un bandeau persistant « Vous êtes hors connexion » et une page de repli avec « Réessayer ». Conserver uniquement les ressources publiques explicitement prévues par la politique de cache ; ne pas promettre que tous les salons restent consultables.
- **Données sensibles :** exclure du cache applicatif hors ligne les pages de compte, rendez-vous, documents KYC, données administratives et paiements. Ne pas stocker les OTP ou pièces d'identité dans le stockage local.
- **Opérations métier :** réservation, validation, annulation et paiement nécessitent une réponse du serveur. Aucun envoi différé automatique d'une opération sensible. Après une coupure pendant l'envoi, vérifier son résultat avant de proposer un nouvel essai.
- **Fraîcheur :** une fiche publique conservée localement indique sa dernière actualisation. Les créneaux et droits d'abonnement sont revalidés en ligne ; une donnée en cache n'atteste pas une disponibilité.
- **Mise à jour :** proposer « Une mise à jour est disponible » et « Actualiser » à un moment sans saisie ni paiement en cours. Ne pas recharger automatiquement un formulaire rempli.
- **Retour des applications externes :** après un itinéraire ou un paiement, permettre de retrouver la fiche ou le suivi concerné. Ne pas déduire la réussite d'un paiement du seul retour dans la PWA.
- **Notifications :** demander l'autorisation dans un contexte utile, jamais dès l'accueil. Le refus ne bloque pas le parcours ; le suivi in-app reste disponible. La disponibilité du push doit être vérifiée sur les plateformes ciblées avant de la promettre.
- **Livraison technique à prévoir :** HTTPS en production, manifeste, nom et icônes approuvées, portée et démarrage cohérents, service worker avec cache limité et page de repli. Ces éléments doivent être implémentés et testés ; leur mention ici ne signifie pas qu'ils existent déjà.

## 6. Mouvement et interaction

Le mouvement confirme une action et aide à comprendre un changement d'état. Durées de 120 à 180 ms pour les contrôles, 200 à 240 ms pour les panneaux, courbe `cubic-bezier(0.2, 0, 0, 1)`.

- Animer uniquement `transform` et `opacity`. Ne pas animer les dimensions ou la position du flux.
- Un ressort optionnel de rigidité 100 et amortissement 20 convient à l'ouverture d'un panneau ; aucune animation ne retarde la disponibilité d'un formulaire ou d'une liste.
- Une liste de résultats peut apparaître avec un fondu bref. Pas de cascade prolongée sur l'agenda, les tableaux ou les données mises à jour en temps réel.
- Microboucle uniquement pendant un traitement réel, par exemple un squelette animé. Aucun bouton qui pulse, logo flottant ou élément métier animé en permanence au repos.
- Respecter `prefers-reduced-motion` : supprimer translations, ressorts et shimmer, conserver un indicateur textuel de traitement.

## 7. Anti-patterns interdits

- Landing page ou grand hero à la place de l'annuaire utilisable.
- Violet néon, halos, texte en dégradé, grands fonds violets et décorations flottantes.
- Logo redessiné approximativement, quatre variantes mélangées, calligraphie utilisée dans les contrôles.
- Police Inter, serif générique, noir pur, titres démesurés et espacement négatif des lettres.
- Rayons supérieurs à 8 px pour les cartes ; sections entières encadrées ; cartes imbriquées ; ombres sur chaque élément.
- Émojis dans l'interface, curseur personnalisé, carrousel ou vidéo en lecture automatique.
- Texte promotionnel vague, consignes sur le style de l'application, faux avis, fausses disponibilités ou faux chiffres de performance.
- Statut communiqué uniquement par couleur ; texte rouge minuscule comme seul signal d'indisponibilité.
- Demande assimilée à un rendez-vous confirmé ; paiement mensuel assimilé à un engagement mensuel.
- Pièces KYC visibles publiquement ; données personnelles réelles utilisées pour illustrer une maquette.
- Images sans rapport avec les établissements, liens médias cassés, texte coupé ou éléments qui se chevauchent.

## 8. Écrans à générer dans Stitch

| Parcours | Écrans et variantes nécessaires |
| --- | --- |
| Client | Explorer avec résultats ; filtres géographiques et catégories ; vue carte ; fiche établissement avec et sans réservation ; téléphone et OTP ; prestation/date/créneau ; récapitulatif ; demande en attente ; confirmation et refus ; mes rendez-vous ; compte |
| Partenaire | Inscription ; étapes KYC ; dossier à corriger ou en attente ; fiche et médias ; prestations ; horaires et disponibilités ; agenda ; demandes entrantes ; reprogrammation ; abonnement ; choix du paiement et résultat |
| Administration | Vue d'ensemble ; utilisateurs et établissements ; file KYC et dossier privé ; abonnements et échéances ; suivi financier ; tarifs ; catégories ; zones géographiques |

**Brief commun à chaque génération :** appliquer les tokens et comportements de ce document, en français, avec une action principale clairement identifiée. Produire une vue mobile de 390 px et sa déclinaison ordinateur de 1440 px. Montrer des données fictives signalées comme données de maquette dans les annotations de livraison, sans ajouter de faux éléments de preuve sociale. Inclure les états vide, chargement, erreur et succès pertinents dans des variantes séparées.

Les choix d'API cités dans le cahier des charges restent des options techniques. Ne pas supposer qu'un fournisseur de carte, SMS, routage ou paiement est déjà intégré. Le bouton d'itinéraire propose les applications disponibles avec une solution de repli ; il n'affiche jamais un succès de trajet fictif.

## 9. Vérification avant validation des écrans

- Vérifier à 360, 390, 768, 1024 et 1440 px : aucun chevauchement, texte essentiel tronqué ou débordement horizontal. Vérifier également le zoom texte à 200 %.
- Parcourir les contrôles au clavier ; focus visible, ordre logique, menus et dialogues refermables, focus rendu au déclencheur.
- Contrôler contrastes et cibles tactiles de 44 px minimum ; conserver un label textuel pour chaque statut.
- Vérifier les noms longs, prix avec devise, absence de photo, refus de géolocalisation, erreur OTP et panne réseau.
- Distinguer créneau sélectionné, indisponibilité, demande en attente et confirmation ; vérifier le conflit de disponibilité et la réservation non activée.
- Vérifier que KYC, abonnement et paiement reflètent chacun leur état réel, et que les données privées n'apparaissent pas dans les vues publiques.
- Confirmer le logo final, les assets autorisés, les prix et devises configurés avant de considérer les maquettes comme validées.
- Vérifier les modes navigateur et installé, les zones de sécurité, le lancement direct d'une fiche, le retour d'une application externe, la perte de réseau et une mise à jour pendant une saisie.
- Vérifier qu'aucune réponse privée n'est conservée par le service worker et qu'une opération interrompue ne produit pas de doublon.

Ce fichier constitue le livrable local destiné à Stitch. Sa création ne signifie pas qu'il a été importé dans le projet distant.
