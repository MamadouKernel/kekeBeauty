# Configuration des intégrations externes

Les intégrations sont désactivées par défaut. Les secrets ne doivent jamais être ajoutés à `appsettings.json`, au dépôt Git ou à une interface cliente. En production, ils sont fournis par le gestionnaire de secrets de l'hébergeur sous forme de variables d'environnement.

## SMS et OTP

Implémentation disponible : envoi HTTPS d'un message OTP au format JSON `{ to, sender, message }`. L'application refuse de démarrer si l'intégration est activée sans paramètres complets.

| Variable | Valeur à renseigner |
|---|---|
| `Integrations__Sms__Enabled` | `true` après validation du compte fournisseur |
| `Integrations__Sms__Provider` | Nom contractuel du fournisseur, par exemple Infobip ou Twilio |
| `Integrations__Sms__Endpoint` | URL HTTPS d'envoi compatible avec l'adaptateur |
| `Integrations__Sms__ApiKey` | Secret fourni par le fournisseur |
| `Integrations__Sms__ApiKeyHeader` | `Authorization` pour un jeton Bearer, ou le nom d'en-tête demandé |
| `Integrations__Sms__SenderId` | Expéditeur validé par le fournisseur |

Point bloquant : le fournisseur et le contrat ne sont pas encore choisis. L'adaptateur devra éventuellement être spécialisé si son API n'accepte pas le format générique documenté ci-dessus.

## Cartographie et itinéraire

Implémentation disponible : génération d'un lien d'itinéraire à partir des coordonnées PostgreSQL de l'établissement.

| Variable | Valeur à renseigner |
|---|---|
| `Integrations__Maps__Enabled` | `true` lorsque le service est retenu |
| `Integrations__Maps__DirectionsUrlTemplate` | URL HTTPS contenant `{latitude}` et `{longitude}` |

Le modèle Google Maps sans clé est fourni comme valeur initiale. Un lien Yango ne doit être activé qu'après validation officielle de son schéma de lien sur les appareils cibles.

## Paiement des abonnements

Le contrat de configuration et sa validation sont en place. L'activation des droits reste interdite tant que la vérification authentique des retours fournisseur et le rapprochement idempotent ne sont pas raccordés.

| Variable | Valeur à renseigner |
|---|---|
| `Integrations__Payments__Enabled` | `true` seulement après recette en environnement de test |
| `Integrations__Payments__Provider` | CinetPay, TouchPay ou fournisseur retenu |
| `Integrations__Payments__ApiBaseUrl` | URL HTTPS de l'API |
| `Integrations__Payments__PublicKey` | Identifiant public éventuel |
| `Integrations__Payments__SecretKey` | Clé secrète serveur |
| `Integrations__Payments__WebhookSecret` | Secret de vérification des notifications |
| `Integrations__Payments__CallbackBaseUrl` | Origine HTTPS publique des URL de retour |

Point bloquant : fournisseur, compte marchand, canaux autorisés, environnement de test et format de signature non fournis.

## Stockage privé KYC

| Variable | Valeur à renseigner |
|---|---|
| `Integrations__KycStorage__Enabled` | `true` après validation sécurité et juridique |
| `Integrations__KycStorage__Provider` | Fournisseur de stockage privé |
| `Integrations__KycStorage__Bucket` | Conteneur privé, sans accès public |
| `Integrations__KycStorage__Endpoint` | URL HTTPS du service |

Points bloquants : fournisseur, durée de conservation, personnes habilitées, procédure de suppression et base juridique à confirmer. Les pièces ne doivent pas être stockées dans le cache PWA ni servies par une URL publique permanente.

## Hébergement

À renseigner dans la plateforme retenue :

- `ConnectionStrings__KekeBeauty` ;
- URL publique HTTPS et domaine ;
- stockage persistant des clés de protection ASP.NET ;
- variables d'intégration ci-dessus ;
- sauvegardes PostgreSQL, supervision et alertes ;
- comptes PostgreSQL à privilèges limités.

Point bloquant : hébergeur, domaine, environnement de recette et responsables d'exploitation non choisis.
