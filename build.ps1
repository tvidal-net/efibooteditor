# SPDX-License-Identifier: LGPL-3.0-or-later
# Configure + build EFI Boot Editor on Windows (MSVC + Qt + vcpkg).
#
# Usage:
#   .\build.ps1                       # RelWithDebInfo (release) build
#   .\build.ps1 -Preset Debug         # Debug build
#   .\build.ps1 -Clean                # wipe the build dir first (full reconfigure)
#
# Requirements (defaults below match this machine):
#   - VS Build Tools with MSVC x64 toolset
#   - Qt msvc2022_64 kit
#   - git clone of vcpkg, bootstrapped (the VS-bundled vcpkg rejects the
#     baseline-less vcpkg.json manifest in this repo)
#
# Output: build\<Preset>\<Preset>\efibooteditor.exe
# Note: with the default x64-windows triplet, zlib is dynamic — copy
# build\<Preset>\vcpkg_installed\x64-windows\bin\z.dll alongside the exe.

[CmdletBinding()]
param(
    [ValidateSet('Debug', 'RelWithDebInfo')]
    [string]$Preset = 'RelWithDebInfo',

    [string]$QtDir = 'C:\Qt\6.11.1\msvc2022_64',

    [string]$VcpkgRoot = $(if ($env:VCPKG_INSTALLATION_ROOT) { $env:VCPKG_INSTALLATION_ROOT } else { 'C:\vcpkg' }),

    [string]$VcVarsAll = 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvarsall.bat',

    # x64-windows = dynamic zlib (z.dll); x64-windows-static-md = zlib linked into the exe
    [string]$Triplet = 'x64-windows',

    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

foreach ($path in $QtDir, $VcpkgRoot, $VcVarsAll) {
    if (-not (Test-Path $path)) { throw "Not found: $path" }
}

if ($Clean -and (Test-Path "$repo\build\$Preset")) {
    Remove-Item -Recurse -Force "$repo\build\$Preset"
}

# vcvarsall is a batch file, so configure + build run inside one cmd session
$command = "`"$VcVarsAll`" x64 >nul 2>&1" +
    " && cd /d `"$repo`"" +
    " && cmake --preset $Preset" +
    " -DCMAKE_TOOLCHAIN_FILE=$VcpkgRoot\scripts\buildsystems\vcpkg.cmake" +
    " -DCMAKE_PREFIX_PATH=$QtDir" +
    " -DVCPKG_TARGET_TRIPLET=$Triplet" +
    " && cmake --build --preset $Preset"
cmd /c $command

if ($LASTEXITCODE -ne 0) { throw "Build failed (exit $LASTEXITCODE)" }

Write-Host "`nBuilt: $repo\build\$Preset\$Preset\efibooteditor.exe" -ForegroundColor Green
