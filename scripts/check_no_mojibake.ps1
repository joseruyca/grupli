$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$Targets = @(
  (Join-Path $ProjectRoot "lib"),
  (Join-Path $ProjectRoot "scripts"),
  (Join-Path $ProjectRoot "README.md"),
  (Join-Path $ProjectRoot "SECURITY.md")
)

# ASCII-only script on purpose.
# These Unicode code points catch common mojibake markers:
# U+00C3 = A with tilde (often appears in broken Spanish accents)
# U+00C2 = A with circumflex (often appears before broken spaces/symbols)
# U+FFFD = replacement character
$SuspiciousChars = @(
  [char]0x00C3,
  [char]0x00C2,
  [char]0xFFFD
)

$Files = @()

foreach ($target in $Targets) {
  if (Test-Path $target) {
    $item = Get-Item $target
    if ($item -is [System.IO.DirectoryInfo]) {
      $Files += Get-ChildItem $target -Recurse -File -Include *.dart,*.ps1,*.md,*.yaml,*.yml,*.json,*.html
    } else {
      $Files += $item
    }
  }
}

$Bad = @()

foreach ($file in $Files) {
  if ($file.Name -eq "check_no_mojibake.ps1") {
    continue
  }

  $text = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

  foreach ($ch in $SuspiciousChars) {
    if ($text.IndexOf($ch) -ge 0) {
      $code = "U+{0:X4}" -f [int][char]$ch
      $Bad += "$($file.FullName) contains suspicious encoding marker $code"
      break
    }
  }
}

if ($Bad.Count -gt 0) {
  Write-Host "Broken text encoding detected." -ForegroundColor Red
  $Bad | ForEach-Object { Write-Host $_ -ForegroundColor Red }
  throw "Fix encoding before building. Do not edit UTF-8 files with unsafe PowerShell Set-Content."
}

Write-Host "Encoding check: OK" -ForegroundColor Green
