$ErrorActionPreference = 'Stop'
$manager = Join-Path $PSScriptRoot '..\windows\Manage.ps1'
$parseErrors = $null
[void][Management.Automation.Language.Parser]::ParseFile($manager, [ref]$null, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors | Out-String) }
$temp = Join-Path ([IO.Path]::GetTempPath()) ('acik-hat-' + [guid]::NewGuid() + '.txt')
try {
    [IO.File]::WriteAllLines($temp, [string[]]@('# comment', '', 'DISCORD.COM', 'discord.com', 'https://example.org/path?q=1', 'sub.example.net.'))
    $actual = @(& $manager -Action Validate -SitesPath $temp)
    if (($actual -join ',') -ne 'discord.com,example.org,sub.example.net') { throw 'URL normalization/deduplication failed.' }
    foreach ($bad in @('', '# only a comment', '*.example.com', 'a b.com', 'https://user:secret@example.org/', '127.0.0.1', '-bad.example', 'https://', 'example.com/path', ('a' * 64 + '.com'))) {
        [IO.File]::WriteAllText($temp, $bad)
        $rejected = $false
        try { & $manager -Action Validate -SitesPath $temp | Out-Null } catch { $rejected = $true }
        if (!$rejected) { throw "Invalid entry accepted: $bad" }
    }
    $defaults = @(& $manager -Action Validate)
    if ($defaults.Count -ne 8 -or $defaults -notcontains 'discord.com') { throw 'Unexpected default list.' }
    Write-Host 'PASS: syntax, URL normalization, duplicates, invalid entries and default domains.'
} finally {
    Remove-Item -LiteralPath $temp -ErrorAction SilentlyContinue
}
