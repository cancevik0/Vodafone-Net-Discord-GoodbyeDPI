#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Prepare','Install','Apply','Start','Stop','Status','Remove','Validate')]
    [string]$Action = 'Status',
    [string]$SitesPath = (Join-Path $PSScriptRoot '..\sites.txt')
)
$ErrorActionPreference = 'Stop'
$serviceName = 'GoodbyeDPI'
$installDir = Join-Path $env:ProgramFiles 'AcikHat'
$installedExe = Join-Path $installDir 'x86_64\goodbyedpi.exe'
$runtime = Join-Path $PSScriptRoot '.runtime'
$releaseDir = Join-Path $runtime 'goodbyedpi-0.2.3rc3-2'
$archiveHash = '37F96B32D050DADCC930A639EBA68E1CCD57ED5C04A5F77DFCA908F01905A4C5'

function Read-Sites {
    $result = @()
    foreach ($line in [IO.File]::ReadAllLines((Resolve-Path -LiteralPath $SitesPath).Path)) {
        $entry = $line.Trim()
        if (!$entry -or $entry.StartsWith('#')) { continue }
        if ($entry -match '^https?://') {
            $uri = [uri]$entry
            if ($uri.UserInfo) { throw 'Kullanici bilgisi iceren URL kabul edilmez.' }
            $entry = $uri.DnsSafeHost
        }
        $entry = $entry.TrimEnd('.').ToLowerInvariant()
        $entry = (New-Object Globalization.IdnMapping).GetAscii($entry)
        if ($entry.Length -gt 253 -or $entry -notmatch '^(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?$') {
            throw "Gecersiz alan adi: $entry"
        }
        $result += $entry
    }
    $result = @($result | Sort-Object -Unique)
    if (!$result.Count) { throw 'Site listesi bos olamaz.' }
    return $result
}
function Require-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    if (!(New-Object Security.Principal.WindowsPrincipal($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Bu islem icin PowerShell penceresini Yonetici olarak acin.'
    }
}
function Get-OwnedService {
    $svc = Get-CimInstance Win32_Service -Filter "Name='$serviceName'"
    if ($svc -and !$svc.PathName.StartsWith(('"' + $installedExe + '" '), [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Baska bir GoodbyeDPI kurulumu bulundu. Bu arac mevcut kurulumu devralmaz. Once eski kurulumunuzu kendi kaldirma yontemiyle kaldirin.'
    }
    return $svc
}
function Invoke-Sc([string[]]$Arguments) {
    & "$env:SystemRoot\System32\sc.exe" @Arguments | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "sc.exe basarisiz: $LASTEXITCODE" }
}
function Stop-Owned {
    $svc = Get-Service $serviceName -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -ne 'Stopped') {
        Stop-Service $serviceName
        $svc.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(20))
    }
}
function Start-Owned {
    Start-Service $serviceName
    (Get-Service $serviceName).WaitForStatus('Running', [TimeSpan]::FromSeconds(20))
}

switch ($Action) {
    'Validate' {
        Read-Sites
        return
    }
    'Prepare' {
        if (![Environment]::Is64BitOperatingSystem -or $env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {
            throw 'Bu ornek yalnizca Windows x64 icindir.'
        }
        New-Item -ItemType Directory -Force $runtime | Out-Null
        $zip = Join-Path $runtime 'official.zip'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest 'https://github.com/ValdikSS/GoodbyeDPI/releases/download/0.2.3rc3/goodbyedpi-0.2.3rc3-2.zip' -OutFile $zip -UseBasicParsing
        if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $archiveHash) {
            throw 'Arsiv SHA256 uyusmuyor; kurulum yapilmadi.'
        }
        Expand-Archive -LiteralPath $zip -DestinationPath $runtime -Force
        Write-Host 'Resmi arsiv indirildi ve sabit SHA256 ile dogrulandi.'
        return
    }
    'Status' {
        Get-CimInstance Win32_Service -Filter "Name='$serviceName'" | Select-Object Name, State, StartMode, PathName
        return
    }
}

Require-Admin
$owned = Get-OwnedService
if ($Action -eq 'Install') {
    if ($owned) { throw 'Zaten kurulu. Listeyi yenilemek icin Apply kullanin.' }
    if (Get-Process goodbyedpi -ErrorAction SilentlyContinue) { throw 'Once elle acilmis GoodbyeDPI surecini kapatin.' }
    $sites = Read-Sites
    # Re-check the archive immediately before installing; use a fresh extraction.
    $zip = Join-Path $runtime 'official.zip'
    if (!(Test-Path -LiteralPath $zip) -or (Get-FileHash -LiteralPath $zip).Hash -ne $archiveHash) {
        throw 'Once Prepare calistirin. Dogrulanmis arsiv bulunamadi.'
    }
    Expand-Archive -LiteralPath $zip -DestinationPath $runtime -Force
    if (Test-Path -LiteralPath $installDir) { throw "Kurulum klasoru zaten var: $installDir. Icerigini inceleyip yeniden adlandirin." }
    New-Item -ItemType Directory $installDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $releaseDir 'x86_64') -Destination $installDir -Recurse
    Copy-Item -LiteralPath (Join-Path $releaseDir 'licenses') -Destination $installDir -Recurse
    [IO.File]::WriteAllLines((Join-Path $installDir 'sites.txt'), [string[]]$sites, [Text.Encoding]::ASCII)
    $command = '"' + $installedExe + '" -e 2 --native-frag --frag-by-sni --wrong-seq --fake-resend 5 --blacklist "' + (Join-Path $installDir 'sites.txt') + '"'
    New-Service -Name $serviceName -BinaryPathName $command -StartupType Automatic | Out-Null
    Invoke-Sc -Arguments @('description', $serviceName, 'Acik Hat: site listeli GoodbyeDPI')
    Invoke-Sc -Arguments @('failure', $serviceName, 'reset=', '86400', 'actions=', 'restart/5000/restart/15000/restart/60000')
    Start-Owned
} elseif ($Action -eq 'Apply') {
    if (!$owned) { throw 'Once Install calistirin.' }
    $sites = Read-Sites
    $target = Join-Path $installDir 'sites.txt'
    $previous = [IO.File]::ReadAllBytes($target)
    $wasRunning = $owned.State -eq 'Running'
    Stop-Owned
    try {
        [IO.File]::WriteAllLines($target, [string[]]$sites, [Text.Encoding]::ASCII)
        if ($wasRunning) { Start-Owned }
    } catch {
        [IO.File]::WriteAllBytes($target, $previous)
        if ($wasRunning) { Start-Owned }
        throw
    }
    Write-Host 'Site listesi uygulandi. Servis kapaliysa kapali birakildi.'
} elseif ($Action -eq 'Remove') {
    if ($owned) {
        Stop-Owned
        Invoke-Sc -Arguments @('delete', $serviceName)
    }
    Write-Host "Servis kaldirildi. Dosyalar korundu: $installDir"
} else {
    if (!$owned) { throw 'Bu repo ile kurulmus servis yok.' }
    if ($Action -eq 'Start') { Start-Owned }
    if ($Action -eq 'Stop') { Stop-Owned }
}
Get-Service $serviceName -ErrorAction SilentlyContinue | Select-Object Name, Status
