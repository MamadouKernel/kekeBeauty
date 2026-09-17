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
| `Integrations__Payments__InitiatePath` | Chemin d'initiation attendu par l'adaptateur JSON générique |
| `Integrations__Payments__ApiKeyHeader` | En-tête de clé, `Authorization` par défaut |

Point bloquant : fournisseur, compte marchand, canaux autorisés, environnement de test et format de signature non fournis.

L'adaptateur attend une réponse JSON contenant `reference` et `paymentUrl`. Il vérifie les notifications par HMAC-SHA256 avec `WebhookSecret`. Un fournisseur utilisant un format différent nécessite un adaptateur spécialisé avant activation.

## Stockage privé KYC

| Variable | Valeur à renseigner |
|---|---|
| `Integrations__KycStorage__Enabled` | `true` après validation sécurité et juridique |
| `Integrations__KycStorage__Provider` | Fournisseur de stockage privé |
| `Integrations__KycStorage__Bucket` | Conteneur privé, sans accès public |
| `Integrations__KycStorage__Endpoint` | URL HTTPS du service |
| `Integrations__KycStorage__ApiKey` | Secret serveur du stockage |
| `Integrations__KycStorage__ApiKeyHeader` | En-tête d'authentification |
| `Integrations__KycStorage__MaxFileBytes` | Taille maximale, 8 Mio par défaut et 20 Mio maximum |
| `Integrations__KycStorage__AllowedContentTypes__0...` | Liste blanche MIME : JPEG, PNG et PDF par défaut |
| `Integrations__KycStorage__RetentionDays` | Durée de conservation validée |

Points bloquants : fournisseur, durée de conservation, personnes habilitées, procédure de suppression et base juridique à confirmer. Les pièces ne doivent pas être stockées dans le cache PWA ni servies par une URL publique permanente.

## Hébergement

À renseigner dans la plateforme retenue :

- `ConnectionStrings__KekeBeauty` ;
- URL publique HTTPS et domaine ;
- stockage persistant des clés de protection ASP.NET ;
- variables d'intégration ci-dessus ;
- sauvegardes PostgreSQL, supervision et alertes ;
- comptes PostgreSQL à privilèges limités.

| Variable | Valeur à renseigner |
|---|---|
| `Operations__PublicBaseUrl` | Origine publique HTTPS |
| `Operations__DataProtectionKeysDirectory` | Stockage persistant et protégé des clés ASP.NET |
| `Operations__BackupsConfigured` | `true` après test de sauvegarde et restauration |
| `Operations__MonitoringConfigured` | `true` après activation des alertes |

En dehors du développement, l'application refuse de démarrer si l'une de ces protections manque.

## Règles métier

| Variable | Valeur initiale configurable |
|---|---|
| `BusinessRules__LaunchCountryCode` | `CI` |
| `BusinessRules__Currency` | `XOF` |
| `BusinessRules__SubscriptionMinimumMonths` | `12`, jamais inférieur à l'exigence d'un an |
| `BusinessRules__BookingChangeDeadlineMinutes` | `60` |
| `BusinessRules__MaximumBookingChanges` | `2` |
| `BusinessRules__PaymentGraceDays` | `0`, conformément à la décision métier actuelle |

Point bloquant : hébergeur, domaine, environnement de recette et responsables d'exploitation non choisis.
