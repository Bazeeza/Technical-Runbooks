# Pester 5 tests for scripts/Test-ReadmePair.ps1
# Run from the repository root:  Invoke-Pester -Path ./scripts/tests -Output Detailed

BeforeAll {
    $script:Checker = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'Test-ReadmePair.ps1'

    # Language buttons as written in docs/STYLE.md, pointing to the given files
    function Get-Button {
        param([string]$French, [string]$English)
        "[![Francais](https://img.shields.io/badge/Langue-Francais-3fe0a0?style=for-the-badge)]($French)`n" +
        "[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)]($English)`n"
    }

    # Creates a file (and its folders) under the test repository
    function Add-TestFile {
        param([string]$Root, [string]$RelativePath, [string]$Content)
        $fullPath = Join-Path -Path $Root -ChildPath $RelativePath
        $folder = Split-Path -Path $fullPath -Parent
        if (-not (Test-Path -LiteralPath $folder)) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
        }
        [System.IO.File]::WriteAllText($fullPath, $Content, (New-Object System.Text.UTF8Encoding($false)))
    }
}

Describe 'Test-ReadmePair.ps1' {

    BeforeEach {
        # A fresh, empty repository for every test
        $script:Repo = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $script:Repo | Out-Null
    }

    Context 'Language twins' {

        It 'returns nothing for a pair with buttons and valid links' {
            $buttons = Get-Button -French 'README.fr.md' -English 'README.md'
            Add-TestFile $script:Repo 'README.md' "# Title`n`n$buttons`nSee [the guide](docs/guide.md).`n"
            Add-TestFile $script:Repo 'README.fr.md' "# Titre`n`n$buttons`nVoir [le guide](docs/guide.md).`n"
            Add-TestFile $script:Repo 'docs/guide.md' "# Guide`n"

            @(& $script:Checker -Path $script:Repo).Count | Should -Be 0
        }

        It 'accepts an English translation of a French original' {
            $buttons = Get-Button -French 'README.md' -English 'README.en.md'
            Add-TestFile $script:Repo 'README.md' "# Titre`n`n$buttons"
            Add-TestFile $script:Repo 'README.en.md' "# Title`n`n$buttons"

            @(& $script:Checker -Path $script:Repo).Count | Should -Be 0
        }

        It 'ignores a file without twin by default' {
            Add-TestFile $script:Repo 'NOTES.md' "# Notes`n"

            @(& $script:Checker -Path $script:Repo).Count | Should -Be 0
        }

        It 'reports a file without twin with -RequireTwin' {
            Add-TestFile $script:Repo 'NOTES.md' "# Notes`n"

            $result = @(& $script:Checker -Path $script:Repo -RequireTwin)
            $result | Should -HaveCount 1
            $result[0].Rule | Should -Be 'MissingTwin'
            $result[0].File | Should -Be 'NOTES.md'
        }

        It 'reports a translation whose original is missing' {
            $buttons = Get-Button -French 'GUIDE.fr.md' -English 'GUIDE.md'
            Add-TestFile $script:Repo 'GUIDE.fr.md' "# Guide`n`n$buttons"

            $result = @(& $script:Checker -Path $script:Repo | Where-Object { $_.Rule -eq 'MissingOriginal' })
            $result | Should -HaveCount 1
            $result[0].File | Should -Be 'GUIDE.fr.md'
        }
    }

    Context 'Language buttons' {

        It 'reports a translation without the badges' {
            $buttons = Get-Button -French 'README.fr.md' -English 'README.md'
            Add-TestFile $script:Repo 'README.md' "# Title`n`n$buttons"
            Add-TestFile $script:Repo 'README.fr.md' "# Titre`n`n[English](README.md)`n"

            $result = @(& $script:Checker -Path $script:Repo)
            $result | Should -HaveCount 1
            $result[0].File | Should -Be 'README.fr.md'
            $result[0].Rule | Should -Be 'MissingLanguageButtons'
        }

        It 'reports an original that does not link to its translation' {
            $buttons = Get-Button -French 'README.fr.md' -English 'README.md'
            Add-TestFile $script:Repo 'README.md' "# Title`n`n$(Get-Button -French 'OTHER.md' -English 'README.md')"
            Add-TestFile $script:Repo 'OTHER.md' "# Other`n"
            Add-TestFile $script:Repo 'README.fr.md' "# Titre`n`n$buttons"

            $result = @(& $script:Checker -Path $script:Repo)
            $result | Should -HaveCount 1
            $result[0].File | Should -Be 'README.md'
            $result[0].Detail | Should -Match 'README\.fr\.md'
        }

        It 'does not count buttons that only appear in a code block' {
            $buttons = Get-Button -French 'README.fr.md' -English 'README.md'
            Add-TestFile $script:Repo 'README.md' "# Title`n`n$buttons"
            Add-TestFile $script:Repo 'README.fr.md' "# Titre`n`n``````markdown`n$buttons``````"

            $result = @(& $script:Checker -Path $script:Repo | Where-Object { $_.File -eq 'README.fr.md' })
            $result.Count | Should -BeGreaterThan 0
        }
    }

    Context 'Relative links' {

        It 'reports a link to a missing file' {
            Add-TestFile $script:Repo 'README.md' "# Title`n`nSee [setup](docs/missing.md).`n"

            $result = @(& $script:Checker -Path $script:Repo)
            $result | Should -HaveCount 1
            $result[0].Rule | Should -Be 'BrokenLink'
            $result[0].Detail | Should -Match 'docs/missing\.md'
        }

        It 'reports a missing image and a missing HTML link' {
            $content = "# Title`n`n![Diagram](images/none.png)`n`n<a href=`"CHANGES.md`">Changes</a>`n"
            Add-TestFile $script:Repo 'README.md' $content

            $result = @(& $script:Checker -Path $script:Repo)
            $result | Should -HaveCount 2
            @($result | Where-Object { $_.Rule -ne 'BrokenLink' }).Count | Should -Be 0
        }

        It 'accepts links with an anchor, to a folder, to a parent folder and from the root' {
            Add-TestFile $script:Repo 'docs/guide.md' "# Guide`n`n[Home](../README.md#title) [Self](/docs/guide.md)`n"
            Add-TestFile $script:Repo 'README.md' "# Title`n`n[Docs](docs/) [Guide](docs/guide.md#guide) [Top](#title)`n"

            @(& $script:Checker -Path $script:Repo).Count | Should -Be 0
        }

        It 'decodes spaces and accepts angle brackets' {
            Add-TestFile $script:Repo 'my guide (v2).md' "# Guide`n"
            Add-TestFile $script:Repo 'README.md' "# Title`n`n[A](my%20guide%20%28v2%29.md) [B](<my guide (v2).md>)`n"

            @(& $script:Checker -Path $script:Repo).Count | Should -Be 0
        }

        It 'ignores external links, e-mail links and footnotes' {
            $content = "# Title`n`n[Web](https://example.com/x.md) [Mail](mailto:info@example.com)`n`n[^1]: A note, not a link.`n"
            Add-TestFile $script:Repo 'README.md' $content

            @(& $script:Checker -Path $script:Repo).Count | Should -Be 0
        }

        It 'ignores links inside fenced code blocks and inline code' {
            $content = "# Title`n`n``````markdown`n[Example](missing.md)`n```````n`nInline: ``[x](missing.md)```n"
            Add-TestFile $script:Repo 'README.md' $content

            @(& $script:Checker -Path $script:Repo).Count | Should -Be 0
        }

        It 'ignores links inside code blocks in files with Windows line endings' {
            $content = "# Title`r`n`r`n``````text`r`n[Example](missing.md)`r`n```````r`n`r`nSee [real](missing-too.md).`r`n"
            Add-TestFile $script:Repo 'README.md' $content

            $result = @(& $script:Checker -Path $script:Repo)
            $result | Should -HaveCount 1
            $result[0].Detail | Should -Match 'missing-too\.md'
        }
    }

    Context 'Excluded folders' {

        It 'skips the archive folder by default' {
            Add-TestFile $script:Repo 'archive/old.md' "# Old`n`n[Gone](nowhere.md)`n"

            @(& $script:Checker -Path $script:Repo -RequireTwin).Count | Should -Be 0
        }

        It 'skips folders given with -Exclude' {
            Add-TestFile $script:Repo 'drafts/new.md' "# New`n`n[Gone](nowhere.md)`n"

            @(& $script:Checker -Path $script:Repo -Exclude 'drafts').Count | Should -Be 0
            @(& $script:Checker -Path $script:Repo).Count | Should -Be 1
        }
    }
}
