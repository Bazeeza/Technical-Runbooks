<#
.SYNOPSIS
    Checks the bilingual Markdown documents of a repository.

.DESCRIPTION
    Test-ReadmePair.ps1 applies the machine-checkable rules of docs/STYLE.md:

    - MissingOriginal        X.fr.md or X.en.md exists, but the original X.md does not.
    - MissingTwin            X.md has no X.fr.md or X.en.md (only with -RequireTwin).
    - MissingLanguageButtons A document of a pair does not show both language
                             badges (Langue / Language) or does not link to its twin.
    - BrokenLink             A relative link or image points to a file that does not exist.

    Links inside code blocks and inline code are ignored, as are external links
    (http, https, mailto...) and links to an anchor of the same page. The anchor of a
    link to another file is not checked, only the file.

    The script only reads files. It writes one object per problem found, with the
    properties File, Rule and Detail, and nothing when the repository is clean.
    Compatible with Windows PowerShell 5.1 and PowerShell 7.

.PARAMETER Path
    Root folder of the repository to check. Default: the current folder.

.PARAMETER Exclude
    Folders to skip, relative to Path, with forward slashes.
    Default: archive, .git, node_modules.

.PARAMETER RequireTwin
    Every Markdown file must have a twin in the other language. Use it on a
    repository that is fully translated, so a new untranslated file is reported.

.EXAMPLE
    .\scripts\Test-ReadmePair.ps1 -Path .

    Lists every problem found in the current repository.

.EXAMPLE
    $problems = .\scripts\Test-ReadmePair.ps1 -Path . -RequireTwin
    $problems | Format-Table -AutoSize
    if ($problems) { exit 1 }

    Strict check for a fully translated repository, as used in continuous integration.

.LINK
    https://github.com/Bazeeza/Technical-Runbooks/blob/main/docs/STYLE.md
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Path = '.',

    [string[]]$Exclude = @('archive', '.git', 'node_modules'),

    [switch]$RequireTwin
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-RelativePath {
    # Path of a file relative to the root, with forward slashes (same output on Windows and Linux)
    param([string]$Root, [string]$FullName)
    $relative = $FullName.Substring($Root.Length).TrimStart([char[]]@('\', '/'))
    return $relative.Replace('\', '/')
}

function Get-MarkdownProse {
    # Fenced code blocks and inline code are examples: their links are not real links.
    # \r? keeps the closing fence recognized in files with Windows line endings.
    param([string]$Text)
    $withoutFences = [regex]::Replace($Text, '(?ms)^[ \t]*(`{3,}|~{3,}).*?^[ \t]*\1[ \t]*\r?$', '')
    return [regex]::Replace($withoutFences, '`[^`\r\n]+`', '')
}

function Get-MarkdownLinkTarget {
    # Targets of inline links and images, reference definitions, and HTML href / src attributes
    param([string]$Text)
    $patterns = @(
        '\]\(\s*(<[^>\r\n]+>|[^)\s]+)(?:\s+"[^"\r\n]*")?\s*\)',
        '(?m)^[ \t]{0,3}\[(?!\^)[^\]\r\n]+\]:[ \t]*(<[^>\r\n]+>|\S+)',
        '(?i)\b(?:href|src)[ \t]*=[ \t]*"([^"\r\n]*)"'
    )
    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($Text, $pattern)) {
            $target = $match.Groups[1].Value.Trim()
            if ($target.StartsWith('<') -and $target.EndsWith('>')) {
                $target = $target.Substring(1, $target.Length - 2)
            }
            $target
        }
    }
}

function Resolve-LinkTarget {
    # Full path of the file a relative link points to, or $null for links that are not checked
    param([string]$Root, [string]$Directory, [string]$Target)

    if ([string]::IsNullOrWhiteSpace($Target)) { return $null }
    if ($Target -match '^[a-zA-Z][a-zA-Z0-9+.\-]*:') { return $null }   # http:, https:, mailto:, tel:...
    if ($Target.StartsWith('//')) { return $null }                       # protocol-relative URL

    $filePart = ($Target -split '[#?]', 2)[0]
    if ($filePart -eq '') { return $null }                               # anchor on the same page

    $filePart = [System.Uri]::UnescapeDataString($filePart)
    if ($filePart.StartsWith('/')) {
        $base = $Root
        $filePart = $filePart.TrimStart('/')
    }
    else {
        $base = $Directory
    }
    $combined = [System.IO.Path]::Combine($base, $filePart.Replace('\', '/'))
    return [System.IO.Path]::GetFullPath($combined)
}

function Write-Finding {
    param([string]$File, [string]$Rule, [string]$Detail)
    [pscustomobject]@{
        File   = $File
        Rule   = $Rule
        Detail = $Detail
    }
}

# --- Collect the Markdown files -------------------------------------------------

$rootPath = (Resolve-Path -LiteralPath $Path).ProviderPath
$rootPath = [System.IO.Path]::GetFullPath($rootPath).TrimEnd([char[]]@('\', '/'))
$excluded = @($Exclude | ForEach-Object { $_.Replace('\', '/').Trim('/') } | Where-Object { $_ -ne '' })

$markdownFiles = @(
    Get-ChildItem -LiteralPath $rootPath -Recurse -File -Force -Filter '*.md' |
        Where-Object {
            $relative = Get-RelativePath -Root $rootPath -FullName $_.FullName
            $skip = $false
            foreach ($folder in $excluded) {
                if ($relative -eq $folder -or $relative.StartsWith($folder + '/')) { $skip = $true }
            }
            -not $skip
        } |
        Sort-Object -Property FullName
)

# --- Check each file ------------------------------------------------------------

foreach ($file in $markdownFiles) {
    $relative = Get-RelativePath -Root $rootPath -FullName $file.FullName
    $directory = $file.DirectoryName

    $raw = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    if ($null -eq $raw) { $raw = '' }
    $text = Get-MarkdownProse -Text $raw

    $targets = @(Get-MarkdownLinkTarget -Text $text)
    $resolvedTargets = @()

    # Rule: every relative link points to an existing file or folder
    foreach ($target in $targets) {
        try {
            $resolved = Resolve-LinkTarget -Root $rootPath -Directory $directory -Target $target
            if ($null -eq $resolved) { continue }
            $resolvedTargets += $resolved
            $exists = Test-Path -LiteralPath $resolved
        }
        catch {
            # Characters that are not allowed in a path (Windows PowerShell 5.1 throws on them)
            $exists = $false
        }
        if (-not $exists) {
            Write-Finding -File $relative -Rule 'BrokenLink' -Detail "Link target not found: $target"
        }
    }

    # Find the twin of the file
    $twins = @()
    if ($file.Name -match '^(.+)\.(fr|en)\.md$') {
        $originalName = $Matches[1] + '.md'
        $originalPath = Join-Path -Path $directory -ChildPath $originalName
        if (Test-Path -LiteralPath $originalPath) {
            $twins += $originalPath
        }
        else {
            Write-Finding -File $relative -Rule 'MissingOriginal' -Detail "Translation without its original: $originalName"
        }
    }
    else {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        foreach ($language in @('fr', 'en')) {
            $twinPath = Join-Path -Path $directory -ChildPath ($baseName + '.' + $language + '.md')
            if (Test-Path -LiteralPath $twinPath) { $twins += $twinPath }
        }
        if ($twins.Count -eq 0 -and $RequireTwin) {
            Write-Finding -File $relative -Rule 'MissingTwin' -Detail "No $baseName.fr.md or $baseName.en.md next to this file"
        }
    }

    # Rule: both documents of a pair show the two language badges and link to each other
    foreach ($twin in $twins) {
        $twinFull = [System.IO.Path]::GetFullPath($twin)
        $twinName = Split-Path -Path $twinFull -Leaf
        $hasBadges = ($text -match 'img\.shields\.io/badge/Langue-') -and ($text -match 'img\.shields\.io/badge/Language-')
        $linksToTwin = @($resolvedTargets | Where-Object { $_ -eq $twinFull }).Count -gt 0
        if (-not $hasBadges) {
            Write-Finding -File $relative -Rule 'MissingLanguageButtons' -Detail 'The Langue and Language badges are not both present'
        }
        if (-not $linksToTwin) {
            Write-Finding -File $relative -Rule 'MissingLanguageButtons' -Detail "No link to the other language: $twinName"
        }
    }
}

Write-Verbose ("Checked {0} Markdown file(s) under {1}" -f $markdownFiles.Count, $rootPath)
