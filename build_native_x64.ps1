# build_native_x64.ps1
# Compiles a 100% self-contained, standalone native 64-bit Windows executable (.exe)
# for BharatAstrologyMuhurtham with embedded payload, application icon, manifest,
# and high-DPI Edge Application host mode.
# Zero external 3rd-party dependencies required.

param(
    [switch]$SkipTests = $false,
    [string]$OutFile = "BharatAstrologyMuhurtham.exe",
    [string]$Version = "1.0.0.0"
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  BharatAstrology.org - Native Windows x64 Executable Builder   " -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan

$currentDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $currentDir) { $currentDir = Get-Location }

$htmlFile = Join-Path $currentDir "index.html"
if (-not (Test-Path $htmlFile)) {
    Write-Error "Error: index.html not found in $currentDir. Please place build_native_x64.ps1 adjacent to index.html."
    exit 1
}

$htmlLength = (Get-Item $htmlFile).Length
Write-Host "[1/5] Verified source payload: index.html ($([Math]::Round($htmlLength / 1KB, 1)) KB)" -ForegroundColor Green

# Optional: Run headless verification tests prior to compilation
if (-not $SkipTests) {
    $testScript = Join-Path $currentDir "tests\test_muhurtham_engine.js"
    if (Test-Path $testScript) {
        $nodeCmd = Get-Command "node" -ErrorAction SilentlyContinue
        if ($nodeCmd) {
            Write-Host "[*] Executing automated pre-build test suite via Node.js..." -ForegroundColor Cyan
            & $nodeCmd.Source $testScript
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Pre-build test suite FAILED with exit code $LASTEXITCODE. Aborting compilation."
                exit 1
            }
            Write-Host "[*] All regression & security tests PASSED." -ForegroundColor Green
        } else {
            Write-Host "[!] Node.js not detected in PATH; skipping script-level VM tests." -ForegroundColor Yellow
        }
    }
}

# Locate 64-bit csc.exe compiler
$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) {
    $found = Get-ChildItem -Path "C:\Windows\Microsoft.NET\Framework64" -Filter "csc.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $csc = $found.FullName }
}

if (-not (Test-Path $csc)) {
    $roslynCsc = Get-ChildItem -Path "${env:ProgramFiles}\dotnet" -Filter "csc.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($roslynCsc) { $csc = $roslynCsc.FullName }
}

if (-not (Test-Path $csc)) {
    Write-Error "Microsoft .NET 64-bit C# compiler (csc.exe) was not found on this system. Please ensure .NET Framework 4.5+ is enabled."
    exit 1
}

Write-Host "[2/5] Located 64-bit C# compiler: $csc" -ForegroundColor Green

# Generate High-Resolution Application Icon (app.ico) if missing
$iconFile = Join-Path $currentDir "app.ico"
if (-not (Test-Path $iconFile)) {
    Write-Host "[*] Generating high-resolution Vedic Chakra icon (app.ico)..." -ForegroundColor Cyan
    Add-Type -AssemblyName System.Drawing
    $size = 256
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    # Obsidian Navy circle background
    $bgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 15, 23, 42))
    $g.FillEllipse($bgBrush, 8, 8, 240, 240)
    $bgBrush.Dispose()

    # Outer Royal Gold Ring
    $goldPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 217, 119, 6)), 6
    $g.DrawEllipse($goldPen, 16, 16, 224, 224)

    # Inner Amber Glow Ring
    $goldInnerPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 251, 191, 36)), 3
    $g.DrawEllipse($goldInnerPen, 36, 36, 184, 184)

    # 12 Surya Rays (12 Rashis / Solar months)
    $rayPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 245, 158, 11)), 3
    $center = 128
    for ($i = 0; $i -lt 12; $i++) {
        $angle = $i * [Math]::PI / 6.0
        $x1 = $center + 50 * [Math]::Cos($angle)
        $y1 = $center + 50 * [Math]::Sin($angle)
        $x2 = $center + 90 * [Math]::Cos($angle)
        $y2 = $center + 90 * [Math]::Sin($angle)
        $g.DrawLine($rayPen, [float]$x1, [float]$y1, [float]$x2, [float]$y2)
    }
    $rayPen.Dispose()

    # Central Surya / Bindu Sun
    $sunBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 251, 191, 36))
    $g.FillEllipse($sunBrush, 96, 96, 64, 64)
    $sunBrush.Dispose()
    
    $coreBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 217, 119, 6))
    $g.FillEllipse($coreBrush, 112, 112, 32, 32)
    $coreBrush.Dispose()

    $goldPen.Dispose()
    $goldInnerPen.Dispose()
    $g.Dispose()

    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBytes = $ms.ToArray()
    $ms.Dispose()
    $bmp.Dispose()

    $fs = [System.IO.File]::Create($iconFile)
    $bw = New-Object System.IO.BinaryWriter $fs
    $bw.Write([uint16]0) # Reserved
    $bw.Write([uint16]1) # Type (1 = ICO)
    $bw.Write([uint16]1) # Count (1 image)
    $bw.Write([byte]0)   # Width (0 = 256)
    $bw.Write([byte]0)   # Height (0 = 256)
    $bw.Write([byte]0)   # ColorCount
    $bw.Write([byte]0)   # Reserved
    $bw.Write([uint16]1) # Planes
    $bw.Write([uint16]32)# BitCount
    $bw.Write([uint32]$pngBytes.Length) # Image Size
    $bw.Write([uint32]22) # Offset (6 + 16 = 22)
    $bw.Write($pngBytes)
    $bw.Flush()
    $fs.Dispose()
}
Write-Host "[3/5] Application icon verified: $iconFile" -ForegroundColor Green

# Generate High-DPI Application Manifest if missing
$manifestFile = Join-Path $currentDir "app.manifest"
if (-not (Test-Path $manifestFile)) {
    $manifestXml = @'
<?xml version="1.0" encoding="utf-8"?>
<assembly manifestVersion="1.0" xmlns="urn:schemas-microsoft-com:asm.v1">
  <assemblyIdentity version="1.0.0.0" name="BharatAstrology.Muhurtham"/>
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v2">
    <security>
      <requestedPrivileges xmlns="urn:schemas-microsoft-com:asm.v3">
        <requestedExecutionLevel level="asInvoker" uiAccess="false" />
      </requestedPrivileges>
    </security>
  </trustInfo>
  <compatibility xmlns="urn:schemas-microsoft-com:compatibility.v1">
    <application>
      <!-- Windows 10 & 11 -->
      <supportedOS Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}" />
      <!-- Windows 8.1 -->
      <supportedOS Id="{1f676c76-80e1-4239-95bb-83d0f6d0da78}" />
      <!-- Windows 8 -->
      <supportedOS Id="{4a2f28e3-53b9-4441-ba9c-d69d4a4a6e38}" />
      <!-- Windows 7 -->
      <supportedOS Id="{35138b9a-5d96-4fbd-8e2d-a2440225f93a}" />
    </application>
  </compatibility>
  <application xmlns="urn:schemas-microsoft-com:asm.v3">
    <windowsSettings>
      <dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">true/pm</dpiAware>
      <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2, PerMonitor</dpiAwareness>
    </windowsSettings>
  </application>
</assembly>
'@
    Set-Content -Path $manifestFile -Value $manifestXml -Encoding UTF8
}
Write-Host "[4/5] DPI-Aware application manifest verified: $manifestFile" -ForegroundColor Green

# Generate Self-Contained Native C# Launcher Source
$csharpSource = @"
using System;
using System.IO;
using System.Reflection;
using System.Diagnostics;
using System.Windows.Forms;
using Microsoft.Win32;

[assembly: AssemblyTitle("BharatAstrology.org Muhurtham Calculation Engine")]
[assembly: AssemblyDescription("Commercial Muhurtham & Electional Astrology Calculation Engine")]
[assembly: AssemblyCompany("BharatAstrology.org")]
[assembly: AssemblyProduct("BharatAstrology Muhurtham Desktop")]
[assembly: AssemblyCopyright("Copyright © 2026 BharatAstrology.org")]
[assembly: AssemblyVersion("$Version")]
[assembly: AssemblyFileVersion("$Version")]

namespace BharatAstrology {
    static class Program {
        private const string AppGuid = "BharatAstrology_SingleInstance_App_2026";
        private const string ResourceName = "BharatAstrology.index.html";

        [STAThread]
        static void Main(string[] args) {
            bool createdNew;
            using (System.Threading.Mutex mutex = new System.Threading.Mutex(true, AppGuid, out createdNew)) {
                try {
                    string targetHtmlPath = ResolveHtmlPayload();
                    if (string.IsNullOrEmpty(targetHtmlPath) || !File.Exists(targetHtmlPath)) {
                        MessageBox.Show("Fatal Error: Could not extract or locate application bundle.", "BharatAstrology Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                        return;
                    }

                    LaunchNativeAppWindow(targetHtmlPath);
                } catch (Exception ex) {
                    MessageBox.Show("Unexpected launch error: " + ex.Message + "\n\n" + ex.StackTrace, "BharatAstrology Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private static string ResolveHtmlPayload() {
            // Check 1: Prioritize adjacent local index.html if present (for developer workflow)
            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            string adjacentFile = Path.Combine(baseDir, "index.html");
            if (File.Exists(adjacentFile)) {
                return adjacentFile;
            }

            // Check 2: Extract embedded assembly resource into isolated LocalAppData directory
            string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string appDir = Path.Combine(localAppData, "BharatAstrology");
            Directory.CreateDirectory(appDir);
            string cachedHtmlPath = Path.Combine(appDir, "BharatAstrology_index.html");

            Assembly asm = Assembly.GetExecutingAssembly();
            using (Stream resourceStream = asm.GetManifestResourceStream(ResourceName)) {
                if (resourceStream == null) {
                    return null;
                }

                bool rewrite = true;
                if (File.Exists(cachedHtmlPath)) {
                    FileInfo fi = new FileInfo(cachedHtmlPath);
                    if (fi.Length == resourceStream.Length) {
                        rewrite = false;
                    }
                }

                if (rewrite) {
                    using (FileStream fs = new FileStream(cachedHtmlPath, FileMode.Create, FileAccess.Write, FileShare.None)) {
                        resourceStream.CopyTo(fs);
                    }
                }
            }

            return cachedHtmlPath;
        }

        private static void LaunchNativeAppWindow(string htmlFilePath) {
            string fileUri = "file:///" + htmlFilePath.Replace("\\", "/");
            string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string userDataDir = Path.Combine(localAppData, "BharatAstrology", "UserData");

            string browserExe = LocateChromiumBrowser();
            if (!string.IsNullOrEmpty(browserExe)) {
                ProcessStartInfo psi = new ProcessStartInfo {
                    FileName = browserExe,
                    Arguments = string.Format("--app=\"{0}\" --user-data-dir=\"{1}\" --window-size=1360,900", fileUri, userDataDir),
                    UseShellExecute = false
                };
                Process.Start(psi);
                return;
            }

            // Fallback: Default system browser
            ProcessStartInfo defaultPsi = new ProcessStartInfo {
                FileName = fileUri,
                UseShellExecute = true
            };
            Process.Start(defaultPsi);
        }

        private static string LocateChromiumBrowser() {
            string p86 = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86);
            string p64 = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);

            // 1. Microsoft Edge (standard Windows 10/11)
            string[] edgeCandidates = new string[] {
                Path.Combine(p86, @"Microsoft\Edge\Application\msedge.exe"),
                Path.Combine(p64, @"Microsoft\Edge\Application\msedge.exe")
            };
            foreach (string path in edgeCandidates) {
                if (File.Exists(path)) return path;
            }

            // 2. Microsoft Edge via Registry App Paths
            try {
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe")) {
                    if (key != null) {
                        object val = key.GetValue("");
                        if (val != null && File.Exists(val.ToString())) return val.ToString();
                    }
                }
            } catch { }

            // 3. Google Chrome fallback
            string[] chromeCandidates = new string[] {
                Path.Combine(p64, @"Google\Chrome\Application\chrome.exe"),
                Path.Combine(p86, @"Google\Chrome\Application\chrome.exe")
            };
            foreach (string path in chromeCandidates) {
                if (File.Exists(path)) return path;
            }

            return null;
        }
    }
}
"@

$runnerCsPath = Join-Path $currentDir "runner_build_temp.cs"
Set-Content -Path $runnerCsPath -Value $csharpSource -Encoding UTF8

$outputExe = Join-Path $currentDir $OutFile

# Gracefully terminate running instance if locked
$runningProcs = Get-Process -Name ([System.IO.Path]::GetFileNameWithoutExtension($OutFile)) -ErrorAction SilentlyContinue
if ($runningProcs) {
    Write-Host "[!] Found running instance of $OutFile. Terminating process to enable file overwrite..." -ForegroundColor Yellow
    $runningProcs | Stop-Process -Force
    Start-Sleep -Milliseconds 500
}

Write-Host "[5/5] Compiling native x64 Windows binary with embedded assets: $outputExe ..." -ForegroundColor Yellow

$cscArgs = @(
    "/target:winexe",
    "/platform:x64",
    "/optimize+",
    "/highentropyva+",
    "/win32manifest:`"$manifestFile`"",
    "/win32icon:`"$iconFile`"",
    "/resource:`"$htmlFile`",BharatAstrology.index.html",
    "/out:`"$outputExe`"",
    "`"$runnerCsPath`"",
    "/reference:System.dll,System.Windows.Forms.dll,System.Drawing.dll,System.Core.dll"
)

& $csc $cscArgs

$compileExitCode = $LASTEXITCODE

if (Test-Path $runnerCsPath) {
    Remove-Item -Path $runnerCsPath -Force -ErrorAction SilentlyContinue
}

if ($compileExitCode -ne 0) {
    Write-Error "Compilation FAILED with exit code $compileExitCode."
    exit 1
}

if (-not (Test-Path $outputExe)) {
    Write-Error "Compilation completed but output binary was not found: $outputExe"
    exit 1
}

$exeSize = (Get-Item $outputExe).Length
$sha256 = (Get-FileHash -Path $outputExe -Algorithm SHA256).Hash

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "  SUCCESS: 100% Self-Contained Standalone Executable Created!   " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "  Output Binary : $outputExe" -ForegroundColor Cyan
Write-Host "  Architecture  : x64 (AMD64)" -ForegroundColor Cyan
Write-Host "  File Size     : $([Math]::Round($exeSize / 1KB, 1)) KB ($exeSize bytes)" -ForegroundColor Cyan
Write-Host "  SHA-256 Hash  : $sha256" -ForegroundColor Cyan
Write-Host "  Payload       : Embedded Assembly Resource (BharatAstrology.index.html)" -ForegroundColor Green
Write-Host "  Portability   : Can run anywhere, even without index.html in directory" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green

exit 0
