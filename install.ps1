#
# Install AI tooling dotfiles on Windows: the counterpart of install.sh, which
# needs GNU Stow and so only runs on Linux and macOS.
#
#     powershell -ExecutionPolicy Bypass -File install.ps1
#
# Links dotfiles/ into the home directory the way `stow -t ~ dotfiles` does:
# each entry becomes a symlink at the same path under ~, except where ~ already
# has a real directory, which is descended into and filled link by link (so
# ~/.claude keeps Claude Code's own state next to the links). Names matching a
# .stow-local-ignore pattern are skipped. An existing file, or a link pointing
# anywhere else, is a conflict: reported, never replaced. Safe to re-run.
#
# Needs Developer Mode (Settings > System > For developers), which lets a
# non-elevated user create symlinks, or an elevated shell.
#
# Must stay Windows PowerShell 5.1 compatible and ASCII-only: 5.1 reads a
# BOM-less UTF-8 file as the legacy code page.

$ErrorActionPreference = 'Stop'

$Package = Join-Path $PSScriptRoot 'dotfiles'
$Target = $env:USERPROFILE

# Matched against each entry's name, whole-name, at every depth. (Stow itself
# reads its ignore list from the package directory, dotfiles/, so the root file
# is honoured here only; for README.md that means ~/.claude/README.md, which
# nothing reads, is linked on Linux and macOS but not here.)
$ignore = @(Get-Content (Join-Path $PSScriptRoot '.stow-local-ignore') |
    Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') } |
    ForEach-Object { '^(?:' + $_.Trim() + ')$' })

# CreateSymbolicLink directly, not New-Item -ItemType SymbolicLink: 5.1's
# New-Item never passes SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE (0x2), so
# it needs admin even with Developer Mode on.
if (-not ('Win32.Symlink' -as [type])) {  # Add-Type fails on a second definition
    Add-Type -Namespace Win32 -Name Symlink -MemberDefinition @'
[DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
[return: MarshalAs(UnmanagedType.I1)]
public static extern bool CreateSymbolicLink(string lpSymlinkFileName, string lpTargetFileName, int dwFlags);
'@
}

function New-Symlink([string] $Path, [string] $Source, [bool] $Directory) {
    $flags = 0x2
    if ($Directory) { $flags = $flags -bor 0x1 }  # SYMBOLIC_LINK_FLAG_DIRECTORY
    if (-not [Win32.Symlink]::CreateSymbolicLink($Path, $Source, $flags)) {
        $code = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
        if ($code -eq 1314) {  # ERROR_PRIVILEGE_NOT_HELD
            throw 'Cannot create symlinks: turn on Developer Mode (Settings > System > For developers) or run elevated.'
        }
        throw ('Cannot link {0}: {1}' -f $Path, (New-Object ComponentModel.Win32Exception $code).Message)
    }
}

$script:conflicts = @()

function Install-Tree([string] $SourceDir, [string] $TargetDir) {
    foreach ($entry in Get-ChildItem -LiteralPath $SourceDir -Force) {
        $name = $entry.Name
        if ($ignore | Where-Object { $name -match $_ }) { continue }
        $path = Join-Path $TargetDir $name
        # Get-Item, not Test-Path: Test-Path follows links and reports a broken
        # one as missing, which would then fail to be created.
        $existing = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        if (-not $existing) {
            New-Symlink $path $entry.FullName $entry.PSIsContainer
            Write-Host "Linked $path -> $($entry.FullName)"
        } elseif ($existing.LinkType) {
            $linkTarget = @($existing.Target)[0]
            if ($linkTarget -and [IO.Path]::GetFullPath($linkTarget) -eq $entry.FullName) {
                Write-Host "$path already linked"
            } else {
                $script:conflicts += "$path is a link to $linkTarget"
            }
        } elseif ($existing.PSIsContainer -and $entry.PSIsContainer) {
            Install-Tree $entry.FullName $path
        } else {
            $script:conflicts += "$path exists"
        }
    }
}

Write-Host 'Linking dotfiles...'
Install-Tree $Package $Target

if ($script:conflicts.Count -gt 0) {
    throw ("Left alone (move each aside, e.g. to <name>.bak, and re-run):`n  " + ($script:conflicts -join "`n  "))
}

Write-Host 'Done!'
