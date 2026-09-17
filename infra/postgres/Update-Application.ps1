param([string]$Docker = 'docker')
$ErrorActionPreference = 'Stop'
$repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
# Additive scripts only: never drop a schema or erase project data.
foreach ($name in @('030_acceptation_rdv.sql','040_identite.sql','050_actions_rdv.sql','060_creation_rdv.sql','061_annuaire.sql','070_expiration_rdv.sql','080_report_rdv.sql')) {
    $sql = Get-Content -LiteralPath (Join-Path $repo "merise/mpd/$name") -Raw -Encoding UTF8
    $sql | & $Docker exec -i kekebeauty-merise-db-1 psql -X -v ON_ERROR_STOP=1 -U keke_owner -d keke_merise
    if ($LASTEXITCODE -ne 0) { throw "Echec de la migration $name. Aucune suppression automatique." }
}
