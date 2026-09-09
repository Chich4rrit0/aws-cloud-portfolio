[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$appPath = Join-Path $projectRoot 'app'
$distPath = Join-Path $appPath 'dist'
$stagingPath = Join-Path $distPath 'package'
$artifactPath = Join-Path $distPath 'lambda.zip'

if (Test-Path -LiteralPath $artifactPath -PathType Leaf) {
    throw "Refusing to overwrite generated artifact: $artifactPath"
}

if (Test-Path -LiteralPath $stagingPath -PathType Container) {
    throw "Refusing to overwrite generated staging directory: $stagingPath"
}

if (-not (Test-Path -LiteralPath (Join-Path $appPath 'node_modules') -PathType Container)) {
    throw 'node_modules is missing. Install the approved dependencies before packaging.'
}

New-Item -ItemType Directory -Path $stagingPath -Force | Out-Null

Copy-Item -LiteralPath (Join-Path $appPath 'src') -Destination $stagingPath -Recurse
Copy-Item -LiteralPath (Join-Path $appPath 'node_modules') -Destination $stagingPath -Recurse
Copy-Item -LiteralPath (Join-Path $appPath 'package.json') -Destination $stagingPath
Copy-Item -LiteralPath (Join-Path $appPath 'package-lock.json') -Destination $stagingPath

$archiveSources = @(
    (Join-Path $stagingPath 'src'),
    (Join-Path $stagingPath 'node_modules'),
    (Join-Path $stagingPath 'package.json'),
    (Join-Path $stagingPath 'package-lock.json')
)
Compress-Archive -LiteralPath $archiveSources -DestinationPath $artifactPath -CompressionLevel Optimal

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($artifactPath)
try {
    $entryNames = @($archive.Entries | ForEach-Object FullName)
    $requiredEntries = @(
        'src/lambda-handler.js',
        'src/http-handler.js',
        'src/dynamodb-link-repository.js',
        'node_modules/@aws-sdk/client-dynamodb/package.json',
        'package.json',
        'package-lock.json'
    )

    foreach ($entry in $requiredEntries) {
        if ($entryNames -notcontains $entry) {
            throw "Package verification failed; missing $entry"
        }
    }

    $forbiddenEntries = @($entryNames | Where-Object {
        $_ -match '(^|/)(test|\.git)(/|$)' -or $_ -match '(^|/)\.env'
    })
    if ($forbiddenEntries.Count -gt 0) {
        throw "Package verification failed; forbidden content found: $($forbiddenEntries -join ', ')"
    }
}
finally {
    $archive.Dispose()
}

Write-Output "Lambda artifact created and verified: $artifactPath"
