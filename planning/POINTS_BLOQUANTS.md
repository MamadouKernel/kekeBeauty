# Points bloquants

Mise à jour : 17 septembre 2026.

Ce registre distingue un blocage externe d'un travail de développement restant. Un blocage n'empêche pas les autres lots d'avancer. Les secrets sont renseignés uniquement dans le gestionnaire de secrets de l'environnement cible.

| Domaine | Blocage actuel | Impact | Informations ou décision attendues | Travail possible en parallèle |
|---|---|---|---|---|
| SMS / OTP | Fournisseur et compte non choisis | Aucun SMS réel en production | Fournisseur, endpoint, clé, en-tête d'authentification, expéditeur autorisé | Adaptateur configurable réalisé ; OTP et quotas testés en développement |
| Paiement | Compte marchand et protocole de signature absents | Impossible d'encaisser ou d'activer les droits après preuve fournisseur | Fournisseur, clés, webhook, URL publique, canaux et devise autorisés | Modèle PostgreSQL et contrat de configuration disponibles ; écrans d'offres et échéancier peuvent avancer |
| Cartographie | Service final et lien Yango officiel non validés | Itinéraire non garanti sur tous les appareils | Google Maps/Mapbox/Yango, modèle de lien et appareils cibles | Lien paramétrable réalisé ; Google Maps HTTPS proposé par défaut |
| KYC | Stockage privé et politique de conservation non choisis | Aucun dépôt de pièce d'identité autorisé | Fournisseur, conteneur privé, durée, suppression, habilitations et base juridique | Modèle de données et contrat de configuration disponibles ; formulaires sans upload peuvent avancer |
| Hébergement | Hébergeur, domaine et environnements non choisis | Pas de recette publique ni de production | Hébergeur, domaine, HTTPS, région, sauvegardes, supervision, responsables | Application locale, tests et documentation continuent |
| Données catalogue | Base locale principale sans catégorie ni établissement publié | Accueil vide hors bases de recette | Contenu réel validé ou jeu de démonstration explicitement isolé | Recherche texte/catégorie et fiches peuvent être testées dans les bases isolées |
| Règles métier | Prix des offres, responsables KYC et règles de report à confirmer | Écrans définitifs et automatisations non validables | Décision du responsable produit et des métiers concernés | Composants et services paramétrables peuvent être préparés |

## Paramètres disponibles

Les variables exactes et leurs contraintes sont décrites dans [CONFIGURATION_INTEGRATIONS.md](CONFIGURATION_INTEGRATIONS.md). Une intégration incomplète reste désactivée ou empêche le démarrage lorsqu'elle est explicitement activée avec une configuration invalide.
