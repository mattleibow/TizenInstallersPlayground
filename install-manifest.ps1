#
# Copyright (c) Samsung Electronics. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.
#

<#
.SYNOPSIS
Installs Tizen workload manifest.
.DESCRIPTION
Installs the WorkloadManifest.json and WorkloadManifest.targets files for Tizen to the dotnet sdk.
.PARAMETER Version
Use specific VERSION
.PARAMETER DotnetInstallDir
Dotnet SDK Location installed
#>

[cmdletbinding()]
param(
    [Alias('v')][string]$Version="<latest>",
    [Alias('d')][string]$DotnetInstallDir="<auto>",
    [Alias('t')][string]$DotnetTargetVersionBand="<auto>"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ManifestBaseName = "Samsung.NET.Sdk.Tizen.Manifest"
$SupportedDotnetVersion = "6"

$LatestVersionMap = @{
    "$ManifestBaseName-6.0.100" = "6.5.100-rc.1.120";
    "$ManifestBaseName-6.0.200" = "7.0.100-preview.13.6";
    "$ManifestBaseName-6.0.300" = "7.0.100-preview.13.30"
}

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    $name = [System.IO.Path]::GetRandomFileName()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

function Ensure-Directory([string]$TestDir) {
    Try {
        New-Item -ItemType Directory -Path $TestDir -Force -ErrorAction stop
        [io.file]::OpenWrite($(Join-Path -Path $TestDir -ChildPath ".test-write-access")).Close()
        Remove-Item -Path $(Join-Path -Path $TestDir -ChildPath ".test-write-access") -Force
    }
    Catch [System.UnauthorizedAccessException] {
        Write-Error "No permission to install. Try run with administrator mode."
    }
}

function Get-LatestVersion([string]$Id) {
    $attempts=3
    $sleepInSeconds=3
    do
    {
        try
        {
            $Response = Invoke-WebRequest -Uri https://api.nuget.org/v3-flatcontainer/$Id/index.json -UseBasicParsing | ConvertFrom-Json
            return $Response.versions | Select-Object -Last 1
        }
        catch {
            Write-Host "Id: $Id"
            Write-Host "An exception was caught: $($_.Exception.Message)"
        }

        $attempts--
        if ($attempts -gt 0) { Start-Sleep $sleepInSeconds }
    } while ($attempts -gt 0)

    if ($LatestVersionMap.ContainsKey($Id))
    {
        Write-Host "Return cached latest version."
        return $LatestVersionMap.$Id
    } else {
        Write-Error "Wrong Id: $Id"
    }
}

function Get-Package([string]$Id, [string]$Version, [string]$Destination, [string]$FileExt = "nupkg") {
    $OutFileName = "$Id.$Version.$FileExt"
    $OutFilePath = Join-Path -Path $Destination -ChildPath $OutFileName
    Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/$Id/$Version" -OutFile $OutFilePath
    return $OutFilePath
}

function Install-Manifest([string]$Id, [string]$Version) {
    $TempZipFile = $(Get-Package -Id $Id -Version $Version -Destination $TempDir -FileExt "zip")
    $TempUnzipDir = Join-Path -Path $TempDir -ChildPath "unzipped\$Id"
    Expand-Archive -Path $TempZipFile -DestinationPath $TempUnzipDir
    New-Item -Path $TizenManifestDir -ItemType "directory" -Force | Out-Null
    Copy-Item -Path "$TempUnzipDir\data\*" -Destination $TizenManifestDir -Force
}

# Check dotnet install directory.
if ($DotnetInstallDir -eq "<auto>") {
    if ($Env:DOTNET_ROOT -And $(Test-Path "$Env:DOTNET_ROOT")) {
        $DotnetInstallDir = $Env:DOTNET_ROOT
    } else {
        $DotnetInstallDir = Join-Path -Path $Env:Programfiles -ChildPath "dotnet"
    }
}
if (-Not $(Test-Path "$DotnetInstallDir")) {
    Write-Error "No installed dotnet '$DotnetInstallDir'."
}

# Check installed dotnet version
$DotnetCommand = "$DotnetInstallDir\dotnet"
if (Get-Command $DotnetCommand -ErrorAction SilentlyContinue)
{
    $DotnetVersion = Invoke-Expression "& '$DotnetCommand' --version"
    $VersionSplitSymbol = '.'
    $SplitVersion = $DotnetVersion.Split($VersionSplitSymbol);
    if ($SplitVersion[0] -ne $SupportedDotnetVersion)
    {
        Write-Host "Current .NET version is $DotnetVersion. .NET 6.0 SDK is required."
        Exit 0
    }
    $DotnetVersionBand = $SplitVersion[0] + $VersionSplitSymbol + $SplitVersion[1] + $VersionSplitSymbol + $SplitVersion[2][0] + "00"
    $ManifestName = "$ManifestBaseName-$DotnetVersionBand"
}
else
{
    Write-Error "'$DotnetCommand' occurs an error."
}

if ($DotnetTargetVersionBand -eq "<auto>") {
    $DotnetTargetVersionBand = $DotnetVersionBand
}

# Check latest version of manifest.
if ($Version -eq "<latest>") {
    $Version = Get-LatestVersion -Id $ManifestName
}

# Check workload manifest directory.
$ManifestDir = Join-Path -Path $DotnetInstallDir -ChildPath "sdk-manifests" | Join-Path -ChildPath $DotnetTargetVersionBand
$TizenManifestDir = Join-Path -Path $ManifestDir -ChildPath "samsung.net.sdk.tizen"
$TizenManifestFile = Join-Path -Path $TizenManifestDir -ChildPath "WorkloadManifest.json"
Ensure-Directory $ManifestDir

# Check already installed.
if (Test-Path $TizenManifestFile) {
    Write-Host "$Version version is already installed."
    Exit 0
}

$TempDir = $(New-TemporaryDirectory)

# Install workload manifest.
Write-Host "Installing $ManifestName/$Version to $ManifestDir..."
Install-Manifest -Id $ManifestName -Version $Version

# Clean up
Remove-Item -Path $TempDir -Force -Recurse