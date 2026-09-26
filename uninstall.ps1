#
# Uninstall AI tooling dotfiles on Windows (remove the links install.ps1 made):
# the counterpart of uninstall.sh.
#
#     powershell -ExecutionPolicy Bypass -File uninstall.ps1
#
# Removes only links that point at this repo's dotfiles/; everything else under
# ~ is left alone.
#
# Must stay Windows PowerShell 5.1 compatible and ASCII-only.

$ErrorActionPreference = 'Stop'

$Package = Join-Path $PSScriptRoot 'dotfiles'
$Target = $env:USERPROFILE

function Uninstall-Tree([string] $SourceDir, [string] $TargetDir) {
    foreach ($entry in Get-ChildItem -LiteralPath $SourceDir -Force) {
        $path = Join-Path $TargetDir $entry.Name
        $existing = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        if (-not $existing) { continue }
        if ($existing.LinkType) {
            $linkTarget = @($existing.Target)[0]
            if ($linkTarget -and [IO.Path]::GetFullPath($linkTarget) -eq $entry.FullName) {
                # Not Remove-Item: on a directory link 5.1 can delete the
                # target's contents. These remove the link itself.
                if ($existing.PSIsContainer) {
                    [IO.Directory]::Delete($path)
                } else {
                    [IO.File]::Delete($path)
                }
                Write-Host "Removed $path"
            }
        } elseif ($existing.PSIsContainer -and $entry.PSIsContainer) {
            Uninstall-Tree $entry.FullName $path
        }
    }
}

Write-Host 'Unlinking dotfiles...'
Uninstall-Tree $Package $Target

Write-Host 'Done!'
