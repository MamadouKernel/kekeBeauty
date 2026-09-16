param(
    [string]$Docker = 'docker'
)
$ErrorActionPreference = 'Stop'
$taskRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$taskCompose = Join-Path $PSScriptRoot 'compose.yaml'
$taskEnv = Join-Path $PSScriptRoot '.env'
$taskArgs = @('compose', '-f', $taskCompose, '--env-file', $taskEnv)
function Invoke-TaskDocker {
    & $Docker @taskArgs @args
    if ($LASTEXITCODE -ne 0) { throw "Docker command failed ($LASTEXITCODE)." }
}
Invoke-TaskDocker up -d --wait
$taskSchema = Invoke-TaskDocker exec -T db psql -U keke_owner -d keke_merise -Atc "SELECT count(*) FROM pg_namespace WHERE nspname='kb'"
if ($taskSchema.Trim() -eq '0') {
    Invoke-TaskDocker cp (Join-Path $taskRoot 'merise/mpd/020_modele_v2.sql') db:/tmp/020_modele_v2.sql
    Invoke-TaskDocker exec -T db psql -v ON_ERROR_STOP=1 -U keke_owner -d keke_merise -f /tmp/020_modele_v2.sql
} else {
    $taskVersionTable = Invoke-TaskDocker exec -T db psql -U keke_owner -d keke_merise -Atc "SELECT to_regclass('kb.version_schema') IS NOT NULL"
    if ($taskVersionTable.Trim() -ne 't') { throw 'Unversioned existing schema; explicit migration required.' }
    $taskVersion = Invoke-TaskDocker exec -T db psql -U keke_owner -d keke_merise -Atc 'SELECT max(version) FROM kb.version_schema'
    if ($taskVersion.Trim() -ne '2') { throw 'Schema version mismatch; no changes applied.' }
    Write-Output 'Existing V2 schema retained; no migration applied.'
}
Invoke-TaskDocker cp (Join-Path $taskRoot 'merise/mpd/021_tests_contraintes_v2.sql') db:/tmp/021_tests_contraintes_v2.sql
Invoke-TaskDocker exec -T db psql -v ON_ERROR_STOP=1 -U keke_owner -d keke_merise -f /tmp/021_tests_contraintes_v2.sql
Invoke-TaskDocker exec -T db psql -U keke_owner -d keke_merise -c "SELECT version(); SELECT count(*) AS tables FROM information_schema.tables WHERE table_schema='kb' AND table_type='BASE TABLE'; SELECT count(*) AS residual_test_salons FROM kb.etablissement WHERE nom LIKE 'TEST V2%';"
