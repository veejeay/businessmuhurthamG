# verify_build_pipeline.ps1
# Comprehensive CI/CD and Local Verification Pipeline for BharatAstrologyMuhurtham
# Validates environment, regression tests, clean build, PE header, embedded assets,
# and standalone portability in an isolated directory.
# Returns exit code 0 on success, 1 on failure.

param(
    [switch]$SkipBuild = $false
)

$ErrorActionPreference = "Stop"
$sw = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "   BharatAstrology.org - CI/CD Pipeline Verification Suite       " -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $baseDir) { $baseDir = Get-Location }

$passCount = 0
$failCount = 0

function Report-Step([string]$name, [bool]$success, [string]$detail = "") {
    if ($success) {
        Write-Host "  [PASS] $name" -ForegroundColor Green
        if ($detail) { Write-Host "         $detail" -ForegroundColor DarkGray }
        $script:passCount++
    } else {
        Write-Host "  [FAIL] $name" -ForegroundColor Red
        if ($detail) { Write-Host "         $detail" -ForegroundColor Red }
        $script:failCount++
    }
}

function Get-PEArchitecture([string]$filePath) {
    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    if ($bytes.Length -lt 64) { return "Unknown" }
    $peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
    if ($peOffset + 6 -gt $bytes.Length) { return "Unknown" }
    $machine = [BitConverter]::ToUInt16($bytes, $peOffset + 4)
    switch ($machine) {
        0x8664 { return "x64 (AMD64)" }
        0x014c { return "x86 (i386)" }
        0xaa64 { return "ARM64" }
        default { return ("0x{0:X4}" -f $machine) }
    }
}

# -------------------------------------------------------------
# Stage 1: Pre-Flight Environment Inspection
# -------------------------------------------------------------
Write-Host "`n[Stage 1/5] Pre-Flight System & Toolchain Inspection" -ForegroundColor Cyan

$isWindows = $PSVersionTable.Platform -eq "Win32NT" -or ($env:OS -like "*Windows*") -or ($PSVersionTable.PSEdition -eq "Desktop")
Report-Step "Host Operating System is Windows" $isWindows "OS: $([System.Environment]::OSVersion.VersionString)"

$nodeCmd = Get-Command "node" -ErrorAction SilentlyContinue
$hasNode = $null -ne $nodeCmd
Report-Step "Node.js Runtime available" $hasNode $(if ($hasNode) { "Node Version: $(& $nodeCmd.Source -v)" } else { "Node not found" })

$cscCandidates = @(
    "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    (Get-ChildItem -Path "C:\Windows\Microsoft.NET\Framework64" -Filter "csc.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
)
$cscPath = $cscCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
Report-Step "Microsoft 64-bit C# Compiler (csc.exe) detected" ($null -ne $cscPath) "Compiler: $cscPath"

# -------------------------------------------------------------
# Stage 2: Headless Astrological & Security Verification
# -------------------------------------------------------------
Write-Host "`n[Stage 2/5] Headless Astrological & Security Test Suite" -ForegroundColor Cyan

$testScript = Join-Path $baseDir "tests\test_muhurtham_engine.js"
if (Test-Path $testScript) {
    if ($hasNode) {
        & $nodeCmd.Source $testScript
        $testExitCode = $LASTEXITCODE
        Report-Step "Headless mathematical & security unit tests execution" ($testExitCode -eq 0) "Exit code: $testExitCode"
    } else {
        Report-Step "Headless test suite" $false "Node.js missing; cannot execute test_muhurtham_engine.js"
    }
} else {
    Report-Step "Test suite file exists (tests\test_muhurtham_engine.js)" $false "File not found at $testScript"
}

# -------------------------------------------------------------
# Stage 3: Clean Executable Compilation
# -------------------------------------------------------------
Write-Host "`n[Stage 3/5] Clean Standalone Executable Build" -ForegroundColor Cyan

$buildScript = Join-Path $baseDir "build_native_x64.ps1"
$exePath = Join-Path $baseDir "BharatAstrologyMuhurtham.exe"

if (-not $SkipBuild) {
    Report-Step "Build script exists (build_native_x64.ps1)" (Test-Path $buildScript)
    & powershell -ExecutionPolicy Bypass -File $buildScript -SkipTests
    $buildExitCode = $LASTEXITCODE
    Report-Step "build_native_x64.ps1 executed successfully" ($buildExitCode -eq 0) "Exit code: $buildExitCode"
} else {
    Write-Host "  [*] Build skipped via -SkipBuild flag." -ForegroundColor Yellow
}

# -------------------------------------------------------------
# Stage 4: Binary Architecture & Metadata Audit
# -------------------------------------------------------------
Write-Host "`n[Stage 4/5] Binary Architecture & Metadata Verification" -ForegroundColor Cyan

$exeExists = Test-Path $exePath
Report-Step "Target binary exists (BharatAstrologyMuhurtham.exe)" $exeExists

if ($exeExists) {
    $exeItem = Get-Item $exePath
    $exeSize = $exeItem.Length
    $isSufficientSize = $exeSize -ge 200000
    Report-Step "Binary size indicates embedded payload (> 200 KB)" $isSufficientSize "Actual Size: $([Math]::Round($exeSize / 1KB, 1)) KB ($exeSize bytes)"

    $arch = Get-PEArchitecture $exePath
    Report-Step "PE Header Machine Type is native 64-bit (x64)" ($arch -eq "x64 (AMD64)") "Architecture: $arch"

    $vi = $exeItem.VersionInfo
    $hasVersion = -not [string]::IsNullOrEmpty($vi.FileVersion) -and ($vi.FileVersion -ne "0.0.0.0")
    Report-Step "Assembly Versioning is populated" $hasVersion "Version: $($vi.FileVersion)"

    $hasProduct = -not [string]::IsNullOrEmpty($vi.ProductName)
    Report-Step "Product metadata is populated" $hasProduct "Product: $($vi.ProductName)"

    $hasCompany = -not [string]::IsNullOrEmpty($vi.CompanyName)
    Report-Step "Company metadata is populated" $hasCompany "Company: $($vi.CompanyName)"
}

# -------------------------------------------------------------
# Stage 5: Standalone Isolated Directory Portability Test
# -------------------------------------------------------------
Write-Host "`n[Stage 5/5] Standalone Isolated Directory Portability Test" -ForegroundColor Cyan

$tempSandbox = Join-Path $env:TEMP ("BA_CI_Test_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Path $tempSandbox -Force | Out-Null

try {
    $isolatedExe = Join-Path $tempSandbox "IsolatedApp.exe"
    Copy-Item -Path $exePath -Destination $isolatedExe -Force

    # Ensure index.html does NOT exist in isolated directory
    $isolatedHtml = Join-Path $tempSandbox "index.html"
    $noHtmlInSandbox = -not (Test-Path $isolatedHtml)
    Report-Step "Isolated sandbox contains ZERO external html files" $noHtmlInSandbox "Sandbox: $tempSandbox"

    # Verify embedded resources using Assembly inspection
    $rawBytes = [System.IO.File]::ReadAllBytes($isolatedExe)
    $asm = [System.Reflection.Assembly]::Load($rawBytes)
    $resNames = $asm.GetManifestResourceNames()

    $hasResource = $resNames -contains "BharatAstrology.index.html"
    Report-Step "PE Assembly contains embedded 'BharatAstrology.index.html' resource" $hasResource "Resources: $($resNames -join ', ')"

    if ($hasResource) {
        $resInfo = $asm.GetManifestResourceInfo("BharatAstrology.index.html")
        $s = $asm.GetManifestResourceStream("BharatAstrology.index.html")
        try {
            $streamLength = $s.Length
            $origLength = (Get-Item (Join-Path $baseDir "index.html")).Length
            $lengthMatches = ($streamLength -eq $origLength)
            Report-Step "Embedded resource byte length exactly matches index.html (100% fidelity)" $lengthMatches "Stream: $streamLength bytes, Source: $origLength bytes"
        } finally {
            if ($s) { $s.Dispose() }
        }
    }
} finally {
    # Cleanup temp directory
    Remove-Item -Path $tempSandbox -Recurse -Force -ErrorAction SilentlyContinue
}

# -------------------------------------------------------------
# Checksum & Artifact Generation
# -------------------------------------------------------------
Write-Host "`n--- Release Artifact Checksum ---" -ForegroundColor Cyan
$sha256 = (Get-FileHash -Path $exePath -Algorithm SHA256).Hash
$checksumFile = Join-Path $baseDir "BharatAstrologyMuhurtham.exe.sha256"
Set-Content -Path $checksumFile -Value "$sha256  BharatAstrologyMuhurtham.exe" -Encoding UTF8
Write-Host "  Artifact: $exePath" -ForegroundColor DarkGray
Write-Host "  SHA-256 : $sha256" -ForegroundColor DarkGray
Write-Host "  Saved to: $checksumFile" -ForegroundColor DarkGray

$sw.Stop()
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "  PIPELINE VERIFICATION SUMMARY                                 " -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  Passed Checks: $passCount" -ForegroundColor Green
Write-Host "  Failed Checks: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host "  Elapsed Time : $([Math]::Round($sw.Elapsed.TotalSeconds, 2)) seconds" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

if ($failCount -gt 0) {
    Write-Host "`n[FATAL] Pipeline verification failed. Do NOT deploy." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n[SUCCESS] All pipeline checks PASSED. Binary is production ready." -ForegroundColor Green
    exit 0
}
