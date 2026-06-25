param(
  [string]$ElasticsearchContainer = "coze-elasticsearch",
  [string]$SchemaDir = "docker/volumes/elasticsearch/es_index_schema"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$schemaRoot = Join-Path $repoRoot $SchemaDir

if (-not (Test-Path $schemaRoot)) {
  throw "Elasticsearch schema directory not found: $schemaRoot"
}

function Invoke-Es {
  param(
    [Parameter(Mandatory = $true)][string]$Method,
    [Parameter(Mandatory = $true)][string]$Path,
    [string]$ContainerFile
  )

  $args = @("exec", $ElasticsearchContainer, "sh", "-lc")

  if ($ContainerFile) {
    $args += "curl -sS -X $Method 'http://localhost:9200$Path' -H 'Content-Type: application/json' --data-binary '@$ContainerFile'"
  } else {
    $args += "curl -sS -X $Method 'http://localhost:9200$Path'"
  }

  & docker @args
}

function Ensure-IndexFromTemplate {
  param(
    [Parameter(Mandatory = $true)][string]$IndexName
  )

  $templateFile = Join-Path $schemaRoot "$IndexName.index-template.json"
  if (-not (Test-Path $templateFile)) {
    throw "Index template not found: $templateFile"
  }

  Write-Host "Ensuring Elasticsearch template: $IndexName"
  $containerTemplateFile = "/tmp/$IndexName.index-template.json"
  & docker cp $templateFile "${ElasticsearchContainer}:$containerTemplateFile"
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to copy template into container: $templateFile"
  }
  Invoke-Es -Method "PUT" -Path "/_index_template/$IndexName" -ContainerFile $containerTemplateFile | Out-Host

  $status = & docker exec $ElasticsearchContainer sh -lc "curl -s -o /dev/null -w '%{http_code}' 'http://localhost:9200/$IndexName'"
  if ($status -eq "200") {
    Write-Host "Index already exists: $IndexName"
    return
  }

  Write-Host "Creating Elasticsearch index: $IndexName"
  Invoke-Es -Method "PUT" -Path "/$IndexName" | Out-Host
}

Ensure-IndexFromTemplate -IndexName "project_draft"
Ensure-IndexFromTemplate -IndexName "coze_resource"

Write-Host "Elasticsearch indices are ready."
