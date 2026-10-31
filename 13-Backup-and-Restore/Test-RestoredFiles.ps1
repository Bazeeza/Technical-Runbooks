<#
.SYNOPSIS
    Proves that a restore test worked: compares a restored folder with the original, file by file, by SHA-256 hash.

.DESCRIPTION
    Use it at the end of a restore test (see runbook 13, step 5). A restore that
    "finished without error" is not proof: this script checks that every file came back
    and that its content is identical.

    For each file under -SourcePath it reports one status:
      Match    : same relative path, same SHA-256 hash
      Different: present in both, but the content differs
      Missing  : in the source, not in the restored folder
      Extra    : in the restored folder, not in the source

    The script only reads files. It never changes the source or the restored folder.
    Compare with a source that has not changed since the backup, or with the same
    snapshot exported elsewhere: files edited after the backup appear as Different.

.PARAMETER SourcePath
    The original folder (or a copy of it taken at backup time).

.PARAMETER RestoredPath
    The folder where the backup was restored for the test.

.PARAMETER ReportPath
    Optional CSV file that receives one line per file (RelativePath, Status, SourceHash,
    RestoredHash). Attach it to the restore test record.

.EXAMPLE
    .\Test-RestoredFiles.ps1 -SourcePath D:\Data\Finance -RestoredPath E:\RestoreTest\Finance
    Prints a summary. Exit code 0 when every file matches, 1 otherwise.

.EXAMPLE
    .\Test-RestoredFiles.ps1 -SourcePath D:\Data\Finance -RestoredPath E:\RestoreTest\Finance -ReportPath .\restore-test.csv
    Same check, and saves the detail of every file in a CSV report.

.NOTES
    Author : Bariu Azeez
    Compatible with Windows PowerShell 5.1 and PowerShell 7. No administrator rights
    needed, only read access to both folders.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $SourcePath,

    [Parameter(Mandatory)]
    [string] $RestoredPath,

    [string] $ReportPath
)

function Get-FileHashTable {
    # Returns a hashtable: relative path (lower case) -> object with the path as written and its SHA-256 hash
    param([string] $Root)

    $rootFull = (Resolve-Path -LiteralPath $Root).ProviderPath.TrimEnd('\', '/')
    $table = @{}
    Get-ChildItem -LiteralPath $rootFull -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $relative = $_.FullName.Substring($rootFull.Length).TrimStart('\', '/')
        $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        # Windows paths are not case-sensitive: compare them in lower case
        $table[$relative.ToLowerInvariant()] = [pscustomobject]@{ Path = $relative; Hash = $hash }
    }
    return $table
}

foreach ($folder in @($SourcePath, $RestoredPath)) {
    if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
        Write-Error "Folder not found: $folder"
        exit 2
    }
}

Write-Host "Hashing source  : $SourcePath"
$source = Get-FileHashTable -Root $SourcePath
Write-Host "Hashing restored: $RestoredPath"
$restored = Get-FileHashTable -Root $RestoredPath

$results = New-Object System.Collections.Generic.List[object]

foreach ($key in $source.Keys) {
    $src = $source[$key]
    if (-not $restored.ContainsKey($key)) {
        $results.Add([pscustomobject]@{ RelativePath = $src.Path; Status = 'Missing'; SourceHash = $src.Hash; RestoredHash = '' })
    }
    elseif ($restored[$key].Hash -ne $src.Hash) {
        $results.Add([pscustomobject]@{ RelativePath = $src.Path; Status = 'Different'; SourceHash = $src.Hash; RestoredHash = $restored[$key].Hash })
    }
    else {
        $results.Add([pscustomobject]@{ RelativePath = $src.Path; Status = 'Match'; SourceHash = $src.Hash; RestoredHash = $src.Hash })
    }
}

foreach ($key in $restored.Keys) {
    if (-not $source.ContainsKey($key)) {
        $rst = $restored[$key]
        $results.Add([pscustomobject]@{ RelativePath = $rst.Path; Status = 'Extra'; SourceHash = ''; RestoredHash = $rst.Hash })
    }
}

$sorted = @($results | Sort-Object Status, RelativePath)
$count = @{}
foreach ($status in 'Match', 'Different', 'Missing', 'Extra') {
    $count[$status] = @($sorted | Where-Object { $_.Status -eq $status }).Count
}

Write-Host ''
Write-Host "Files in source : $($source.Count)"
Write-Host "Match           : $($count['Match'])"
Write-Host "Different       : $($count['Different'])"
Write-Host "Missing         : $($count['Missing'])"
Write-Host "Extra           : $($count['Extra'])"

$problems = @($sorted | Where-Object { $_.Status -ne 'Match' })
if ($problems.Count -gt 0) {
    Write-Host ''
    $problems | Select-Object -First 20 Status, RelativePath | Format-Table -AutoSize | Out-String | Write-Host
    if ($problems.Count -gt 20) { Write-Host "... and $($problems.Count - 20) more (use -ReportPath for the full list)" }
}

if ($ReportPath) {
    $sorted | Export-Csv -LiteralPath $ReportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Report saved    : $ReportPath"
}

if ($source.Count -eq 0) {
    Write-Warning 'The source folder contains no file: nothing was proven.'
    exit 1
}
if ($problems.Count -gt 0) {
    Write-Warning 'Restore test FAILED: the restored data is not identical to the source.'
    exit 1
}
Write-Host 'Restore test PASSED: every file came back with identical content.' -ForegroundColor Green
exit 0
