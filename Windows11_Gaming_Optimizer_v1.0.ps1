# Windows 11 Gaming Optimizer & Setup Assistant
# v1.0
# Run in Windows PowerShell as Administrator.
# IMPORTANT: Designed primarily for fresh/new Windows 11 installations.
# No automatic backup is created. Review every proposed change before applying.
# The script is designed to be idempotent and continue after individual errors.

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

function Write-Color($Text, $Color = "White") {
    Write-Host $Text -ForegroundColor $Color
}

function Pause-Continue {
    Read-Host "`nPress Enter to continue"
}

function Ask-YesNo($Prompt) {
    while ($true) {
        $v = Read-Host "$Prompt [Y/N]"
        if ($v -match '^[Yy]$') { return $true }
        if ($v -match '^[Nn]$') { return $false }
    }
}

function Is-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Run-Safe($Name, [scriptblock]$Action) {
    try {
        & $Action
        $script:Results += [pscustomobject]@{ Name=$Name; Status="SUCCESS"; Detail="" }
        Write-Color "  ✓ $Name" Green
    } catch {
        $msg = $_.Exception.Message
        $script:Results += [pscustomobject]@{ Name=$Name; Status="ERROR"; Detail=$msg }
        Write-Color "  🔴 $Name" Red
        Write-Color "     $msg" DarkRed
    }
}

function Skip-Result($Name, $Reason) {
    $script:Results += [pscustomobject]@{ Name=$Name; Status="SKIPPED"; Detail=$Reason }
    Write-Color "  ↪ $Name — $Reason" Yellow
}

function Get-AppxInstalled($Pattern) {
    @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like $Pattern -or $_.PackageFullName -like $Pattern })
}

function Remove-AppxSafe($DisplayName, $Patterns) {
    $found = @()
    foreach ($p in $Patterns) { $found += Get-AppxInstalled $p }
    $found = $found | Sort-Object PackageFullName -Unique

    if (-not $found) {
        Skip-Result $DisplayName "Already removed / not installed"
        return
    }

    Run-Safe $DisplayName {
        foreach ($pkg in $found) {
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
        }
    }
}

function Set-RegDword($Path, $Name, $Value) {
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    $old = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
    if ($old -eq $Value) { return $false }
    New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
    return $true
}

function Set-RegString($Path, $Name, $Value) {
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    $old = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
    if ($old -eq $Value) { return $false }
    New-ItemProperty -Path $Path -Name $Name -PropertyType String -Value $Value -Force | Out-Null
    return $true
}

function Get-GpuInfo {
    @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
        Where-Object { $_.Name } |
        Select-Object Name, DriverVersion, PNPDeviceID)
}

function Get-StorageInfo {
    @(Get-Disk -ErrorAction SilentlyContinue |
        Select-Object Number, FriendlyName, Manufacturer, Model, SerialNumber,
                      BusType, Size, PartitionStyle, OperationalStatus)
}

function Format-GB($Bytes) {
    if ($null -eq $Bytes) { return "Unknown" }
    return ("{0:N2} GB" -f ($Bytes / 1GB))
}

# ---------------- LANGUAGE ----------------
Clear-Host
Write-Color "╔══════════════════════════════════════════════════════════════╗" Cyan
Write-Color "║        WINDOWS 11 GAMING OPTIMIZER & SETUP ASSISTANT       ║" Cyan
Write-Color "║                         v1.0                               ║" Cyan
Write-Color "╚══════════════════════════════════════════════════════════════╝" Cyan
Write-Host ""
Write-Color "[1] العربية" White
Write-Color "[2] English" White
$lang = Read-Host "Select / اختر"

$AR = $lang -ne "2"

# ---------------- TEXT ----------------
if ($AR) {
    $T = @{
        Continue="متابعة"; Cancel="إلغاء"; Yes="نعم"; No="لا"; Skip="تخطي"
        Scan="فحص الجهاز"; Review="مراجعة التعديلات"; Apply="تطبيق التعديلات"
        Final="التقرير النهائي"; Exit="الخروج"; Full="عرض التقرير الكامل"; Save="حفظ التقرير كملف TXT"
    }
} else {
    $T = @{
        Continue="Continue"; Cancel="Cancel"; Yes="YES"; No="NO"; Skip="Skip"
        Scan="SYSTEM SCAN"; Review="FINAL REVIEW"; Apply="APPLY CHANGES"
        Final="FINAL REPORT"; Exit="Exit"; Full="View Full Report"; Save="Save Report as TXT"
    }
}

# ---------------- ADMIN ----------------
if (-not (Is-Admin)) {
    if ($AR) {
        Write-Color "`n🔴 يجب تشغيل السكربت بصلاحيات Administrator." Red
        Write-Color "اضغط بزر الفأرة الأيمن على PowerShell واختر Run as administrator." Yellow
    } else {
        Write-Color "`n🔴 This script must be run as Administrator." Red
        Write-Color "Right-click PowerShell and choose Run as administrator." Yellow
    }
    Pause-Continue
    exit
}

# ---------------- DISCLAIMER ----------------
Clear-Host
if ($AR) {
    Write-Color "╔══════════════════════════════════════════════════════════════╗" Yellow
    Write-Color "║                         ⚠️ تنبيه مهم                        ║" Yellow
    Write-Color "╚══════════════════════════════════════════════════════════════╝" Yellow
    Write-Host ""
    Write-Host "هذا البرنامج مصمم بشكل أساسي لأجهزة Windows 11 الجديدة أو بعد Format."
    Write-Host "سيتم فحص الجهاز أولًا ثم عرض ما سيتم حذفه أو تغييره قبل التنفيذ."
    Write-Host ""
    Write-Color "⚠️ لن يتم إنشاء Backup تلقائي." Yellow
    Write-Color "⚠️ عمليات Disk الحساسة تحتاج موافقة منفصلة." Yellow
    Write-Color "🟢 لن يتم حذف ملفاتك الشخصية عمدًا." Green
    Write-Host ""
    Write-Host "لن يتم استهداف:"
    Write-Host "  Documents / Downloads / Pictures / Videos / Desktop / Game Saves"
    Write-Host ""
    Write-Host "[1] متابعة"
    Write-Host "[2] إلغاء"
    if ((Read-Host "اختر") -ne "1") { exit }
} else {
    Write-Color "╔══════════════════════════════════════════════════════════════╗" Yellow
    Write-Color "║                       ⚠️ IMPORTANT NOTICE                   ║" Yellow
    Write-Color "╚══════════════════════════════════════════════════════════════╝" Yellow
    Write-Host ""
    Write-Host "This tool is primarily designed for new or recently formatted Windows 11 PCs."
    Write-Host "The PC will be scanned first and proposed changes will be shown before execution."
    Write-Host ""
    Write-Color "⚠️ No automatic backup will be created." Yellow
    Write-Color "⚠️ Sensitive Disk operations require separate confirmation." Yellow
    Write-Color "🟢 Personal files will not be intentionally deleted." Green
    Write-Host ""
    Write-Host "The tool will not target:"
    Write-Host "  Documents / Downloads / Pictures / Videos / Desktop / Game Saves"
    Write-Host ""
    Write-Host "[1] Continue"
    Write-Host "[2] Cancel"
    if ((Read-Host "Select") -ne "1") { exit }
}

# ---------------- SCAN ----------------
Clear-Host
if ($AR) { Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Cyan; Write-Color "🖥️ اكتشاف الجهاز" Cyan; Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Cyan }
else { Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Cyan; Write-Color "🖥️ SYSTEM DETECTION" Cyan; Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Cyan }

$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$board = Get-CimInstance Win32_BaseBoard | Select-Object -First 1
$bios = Get-CimInstance Win32_BIOS | Select-Object -First 1
$ramGB = [math]::Round(((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB), 1)
$gpus = Get-GpuInfo
$disks = Get-StorageInfo

if ($AR) {
    Write-Host "نظام التشغيل: $($os.Caption) $($os.Version) / Build $($os.BuildNumber)"
    Write-Host "المعالج: $($cpu.Name)"
    Write-Host "اللوحة الأم: $($board.Manufacturer) $($board.Product)"
    Write-Host "BIOS: $($bios.SMBIOSBIOSVersion)"
    Write-Host "الذاكرة: $ramGB GB"
    Write-Host ""
    Write-Color "كرت الشاشة:" Magenta
} else {
    Write-Host "Operating System: $($os.Caption) $($os.Version) / Build $($os.BuildNumber)"
    Write-Host "CPU: $($cpu.Name)"
    Write-Host "Motherboard: $($board.Manufacturer) $($board.Product)"
    Write-Host "BIOS: $($bios.SMBIOSBIOSVersion)"
    Write-Host "Memory: $ramGB GB"
    Write-Host ""
    Write-Color "GPU:" Magenta
}

foreach ($g in $gpus) {
    Write-Host "  $($g.Name) — Driver $($g.DriverVersion)"
}

Write-Host ""
if ($AR) { Write-Color "التخزين:" Cyan } else { Write-Color "Storage:" Cyan }
foreach ($d in $disks) {
    Write-Host ("  Disk {0} — {1} — {2} — {3} — {4}" -f `
        $d.Number, $d.Model, (Format-GB $d.Size), $d.BusType, $d.PartitionStyle)
}

# ---------------- PROPOSED CHANGES ----------------
Write-Host ""
if ($AR) {
    Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Cyan
    Write-Color "📋 التعديلات المقترحة" Cyan
    Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Cyan
    Write-Color "🟥 التطبيقات:" Red
    Write-Host "  • OneDrive"
    Write-Host "  • Microsoft Teams"
    Write-Host "  • Clipchamp"
    Write-Host "  • News / Weather / Tips / Get Help / Maps / People / Solitaire"
    Write-Host "  • Unwanted Windows Consumer Apps"
    Write-Color "🟩 سيتم الإبقاء على: Xbox / Snipping Tool / Microsoft Store / Windows Security" Green
    Write-Color "🟨 Windows Settings:" Yellow
    Write-Host "  • Dark Mode → تشغيل"
    Write-Host "  • Desktop Wallpaper → أسود"
    Write-Host "  • Taskbar Search → أيقونة فقط"
    Write-Host "  • Task View → إيقاف"
    Write-Host "  • Widgets → إيقاف"
    Write-Host "  • Recall → إيقاف عند توفره"
    Write-Host "  • Game Mode → تشغيل"
    Write-Host "  • Hardware-Accelerated GPU Scheduling → تشغيل"
    Write-Host "  • Power Mode → Best Performance (إن كان متاحًا)"
    Write-Host "  • Image/Video Thumbnails + ClearType + Font Smoothing → الإبقاء عليها"
    Write-Color "🟨 Privacy:" Yellow
    Write-Host "  • Optional Diagnostic Data / Advertising ID / Suggestions / Consumer Experiences"
    Write-Host "  • Camera Permission / Microphone Permission → الإبقاء عليها"
    Write-Color "🟦 Cleanup & Network:" Cyan
    Write-Host "  • Temporary Files / DNS Cache"
    Write-Host "  • فحص إعدادات TCP دون تغيير IPv6 أو MTU تلقائيًا"
} else {
    Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Cyan
    Write-Color "📋 PROPOSED CHANGES" Cyan
    Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Cyan
    Write-Color "🟥 Applications:" Red
    Write-Host "  • OneDrive"
    Write-Host "  • Microsoft Teams"
    Write-Host "  • Clipchamp"
    Write-Host "  • News / Weather / Tips / Get Help / Maps / People / Solitaire"
    Write-Host "  • Unwanted Windows Consumer Apps"
    Write-Color "🟩 Keep: Xbox / Snipping Tool / Microsoft Store / Windows Security" Green
    Write-Color "🟨 Windows Settings:" Yellow
    Write-Host "  • Dark Mode → ON"
    Write-Host "  • Desktop Wallpaper → Black"
    Write-Host "  • Taskbar Search → Icon Only"
    Write-Host "  • Task View → OFF"
    Write-Host "  • Widgets → OFF"
    Write-Host "  • Recall → OFF when available"
    Write-Host "  • Game Mode → ON"
    Write-Host "  • Hardware-Accelerated GPU Scheduling → ON"
    Write-Host "  • Power Mode → Best Performance when available"
    Write-Host "  • Image/Video Thumbnails + ClearType + Font Smoothing → KEEP"
    Write-Color "🟨 Privacy:" Yellow
    Write-Host "  • Optional Diagnostic Data / Advertising ID / Suggestions / Consumer Experiences"
    Write-Host "  • Camera Permission / Microphone Permission → KEEP"
    Write-Color "🟦 Cleanup & Network:" Cyan
    Write-Host "  • Temporary Files / DNS Cache"
    Write-Host "  • Check TCP settings without automatically changing IPv6 or MTU"
}

Write-Host ""
if ($AR) { $go = Read-Host "هل تريد تطبيق التعديلات؟ [1] نعم  [2] لا" }
else { $go = Read-Host "Apply these changes? [1] YES  [2] NO" }
if ($go -ne "1") { exit }

$script:Results = @()

# ---------------- APPLY ----------------
Clear-Host
if ($AR) { Write-Color "╔══════════════════════════════════════════════════════════════╗" Cyan; Write-Color "║                    تطبيق التعديلات                          ║" Cyan; Write-Color "╚══════════════════════════════════════════════════════════════╝" Cyan }
else { Write-Color "╔══════════════════════════════════════════════════════════════╗" Cyan; Write-Color "║                     APPLYING CHANGES                         ║" Cyan; Write-Color "╚══════════════════════════════════════════════════════════════╝" Cyan }

# Apps
Remove-AppxSafe "Clipchamp" @("*Clipchamp*")
Remove-AppxSafe "News" @("*BingNews*")
Remove-AppxSafe "Weather" @("*BingWeather*")
Remove-AppxSafe "Tips" @("*Getstarted*","*MicrosoftTips*")
Remove-AppxSafe "Get Help" @("*GetHelp*")
Remove-AppxSafe "Maps" @("*WindowsMaps*")
Remove-AppxSafe "People" @("*MicrosoftPeople*")
Remove-AppxSafe "Solitaire" @("*MicrosoftSolitaireCollection*")

# OneDrive
if (Get-Command "winget" -ErrorAction SilentlyContinue) {
    $od = Get-Process OneDrive -ErrorAction SilentlyContinue
    if ($od) { $od | Stop-Process -Force -ErrorAction SilentlyContinue }
    $oneDriveExe = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
    if (-not (Test-Path $oneDriveExe)) { $oneDriveExe = "$env:SystemRoot\System32\OneDriveSetup.exe" }
    if (Test-Path $oneDriveExe) {
        Run-Safe "OneDrive" { Start-Process $oneDriveExe "/uninstall" -Wait -NoNewWindow }
    } else {
        Skip-Result "OneDrive" "Installer not present / already removed"
    }
} else {
    Skip-Result "OneDrive" "winget unavailable; OneDrive installer not found"
}

# Teams
if (Get-Command "winget" -ErrorAction SilentlyContinue) {
    $teams = Get-AppxInstalled "*MSTeams*"
    if ($teams) {
        Run-Safe "Microsoft Teams" {
            foreach ($pkg in $teams) { Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop }
        }
    } else {
        Skip-Result "Microsoft Teams" "Already removed / not installed"
    }
} else {
    Skip-Result "Microsoft Teams" "winget unavailable"
}

# Dark Mode
Run-Safe "Dark Mode" {
    $a = Set-RegDword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0
    $b = Set-RegDword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0
    if (-not ($a -or $b)) { throw "Already enabled" }
}

# Black wallpaper
Run-Safe "Desktop Wallpaper" {
    $path = "$env:WINDIR\Web\Wallpaper\Windows\img0.jpg"
    if (-not (Test-Path $path)) { $path = "$env:WINDIR\Web\Wallpaper\Windows\img19.jpg" }
    if (Test-Path $path) {
        Set-RegString "HKCU:\Control Panel\Desktop" "Wallpaper" $path | Out-Null
        Add-Type @'
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
 [DllImport("user32.dll", CharSet=CharSet.Unicode)]
 public static extern int SystemParametersInfo(int uAction,int uParam,string lpvParam,int fuWinIni);
}
'@
        [Wallpaper]::SystemParametersInfo(20,0,$path,3) | Out-Null
    } else { throw "Windows wallpaper resource not found" }
}

# Taskbar search icon only
Run-Safe "Taskbar Search" {
    $changed = Set-RegDword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 1
    if (-not $changed) { throw "Already set to icon-only" }
}

# Task View OFF
Run-Safe "Task View" {
    $changed = Set-RegDword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" 0
    if (-not $changed) { throw "Already disabled" }
}

# Widgets OFF
Run-Safe "Widgets" {
    $changed = Set-RegDword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 0
    if (-not $changed) { throw "Already disabled" }
}

# Recall OFF (if policy is supported)
Run-Safe "Recall" {
    $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
    $changed = Set-RegDword $p "DisableAIDataAnalysis" 1
    if (-not $changed) { throw "Already disabled or policy already applied" }
}

# Game Mode ON
Run-Safe "Game Mode" {
    $changed = Set-RegDword "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 1
    if (-not $changed) { throw "Already enabled" }
}

# HAGS ON
Run-Safe "Hardware-Accelerated GPU Scheduling" {
    $p = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    $changed = Set-RegDword $p "HwSchMode" 2
    if (-not $changed) { throw "Already enabled" }
}

# Privacy
Run-Safe "Advertising ID" {
    $changed = Set-RegDword "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
    if (-not $changed) { throw "Already disabled" }
}

Run-Safe "Optional Diagnostic Data" {
    $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    $changed = Set-RegDword $p "AllowTelemetry" 0
    if (-not $changed) { throw "Already restricted" }
}

Run-Safe "Windows Suggestions" {
    $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    $changed = $false
    foreach ($n in @(
        "SubscribedContent-338388Enabled",
        "SubscribedContent-338389Enabled",
        "SubscribedContent-353694Enabled",
        "SubscribedContent-353696Enabled",
        "SystemPaneSuggestionsEnabled"
    )) {
        if (Set-RegDword $p $n 0) { $changed = $true }
    }
    if (-not $changed) { throw "Already disabled" }
}

# Cleanup
Run-Safe "Temporary Files" {
    $targets = @("$env:TEMP\*", "$env:WINDIR\Temp\*")
    foreach ($t in $targets) {
        Remove-Item $t -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Run-Safe "DNS Cache" {
    Clear-DnsClientCache
}

# Network info only, no risky automatic MTU/IPv6 changes
Run-Safe "Network Configuration Check" {
    Get-NetIPConfiguration | Out-Null
    Get-NetTCPSetting | Out-Null
}

# Power mode: use powercfg only if available; do not hard-fail if Windows rejects it.
Run-Safe "Power Mode" {
    $p = powercfg /getactivescheme 2>$null
    if ($p -match "SCHEME_MAX") { throw "Already set / unavailable" }
    # Use the built-in High Performance plan if present.
    $hp = powercfg /list 2>$null | Select-String -Pattern "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    if ($hp) {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c | Out-Null
    } else {
        throw "High Performance power plan unavailable"
    }
}

# Windows Update scan (does not force a reboot)
Run-Safe "Windows Update Check" {
    if (Get-Command UsoClient.exe -ErrorAction SilentlyContinue) {
        Start-Process "$env:SystemRoot\System32\UsoClient.exe" "StartScan" -WindowStyle Hidden
    } else {
        throw "Windows Update client command unavailable"
    }
}

# ---------------- GPU DETECTION ----------------
Write-Host ""
if ($AR) { Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Magenta; Write-Color "🟪 فحص GPU والتعريفات" Magenta; Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Magenta }
else { Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Magenta; Write-Color "🟪 GPU & DRIVER CHECK" Magenta; Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Magenta }

foreach ($g in $gpus) {
    if ($g.Name -match "NVIDIA") {
        Write-Color "NVIDIA GPU: $($g.Name)" Magenta
        if ($AR) {
            Write-Host "[1] فتح موقع NVIDIA الرسمي"
            Write-Host "[2] تخطي"
            $choice = Read-Host "اختر"
        } else {
            Write-Host "[1] Open Official NVIDIA Website"
            Write-Host "[2] Skip"
            $choice = Read-Host "Select"
        }
        if ($choice -eq "1") {
            Start-Process "https://www.nvidia.com/Download/index.aspx"
            Skip-Result "NVIDIA Driver" "Opened official NVIDIA download page for manual selection"
        } else {
            Skip-Result "NVIDIA Driver" "User selected Skip"
        }
    } elseif ($g.Name -match "AMD") {
        Write-Color "AMD GPU: $($g.Name)" Magenta
        if ($AR) {
            Write-Host "[1] فتح موقع AMD الرسمي"
            Write-Host "[2] تخطي"
            $choice = Read-Host "اختر"
        } else {
            Write-Host "[1] Open Official AMD Website"
            Write-Host "[2] Skip"
            $choice = Read-Host "Select"
        }
        if ($choice -eq "1") {
            Start-Process "https://www.amd.com/en/support/download/drivers.html"
            Skip-Result "AMD Driver" "Opened official AMD download page for manual selection"
        } else {
            Skip-Result "AMD Driver" "User selected Skip"
        }
    } elseif ($g.Name -match "Intel") {
        Write-Color "Intel GPU: $($g.Name)" Magenta
        if ($AR) {
            Write-Host "[1] فتح Intel Driver & Support Assistant"
            Write-Host "[2] تخطي"
            $choice = Read-Host "اختر"
        } else {
            Write-Host "[1] Open Intel Driver & Support Assistant"
            Write-Host "[2] Skip"
            $choice = Read-Host "Select"
        }
        if ($choice -eq "1") {
            Start-Process "https://www.intel.com/content/www/us/en/support/detect.html"
            Skip-Result "Intel Driver" "Opened official Intel support page"
        } else {
            Skip-Result "Intel Driver" "User selected Skip"
        }
    }
}

# ---------------- STORAGE REVIEW ----------------
$unalloc = @($disks | Where-Object { $_.PartitionStyle -eq "RAW" -or $_.PartitionStyle -eq "Unknown" })
if ($unalloc.Count -gt 0) {
    Write-Host ""
    if ($AR) {
        Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Red
        Write-Color "🟥 أقراص تحتاج مراجعة" Red
        Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Red
        Write-Host "تم اكتشاف Disk غير مهيأ/غير معروف. لن يتم تهيئته تلقائيًا."
        Write-Host ""
        foreach ($d in $unalloc) {
            Write-Host ("Disk {0} — {1} — {2}" -f $d.Number,$d.Model,(Format-GB $d.Size))
        }
        Write-Host ""
        Write-Host "[1] فتح Disk Management"
        Write-Host "[2] تخطي"
        $c = Read-Host "اختر"
    } else {
        Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Red
        Write-Color "🟥 DISKS REQUIRING REVIEW" Red
        Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" Red
        Write-Host "An uninitialized/unknown Disk was detected. It will NOT be formatted automatically."
        Write-Host ""
        foreach ($d in $unalloc) {
            Write-Host ("Disk {0} — {1} — {2}" -f $d.Number,$d.Model,(Format-GB $d.Size))
        }
        Write-Host ""
        Write-Host "[1] Open Disk Management"
        Write-Host "[2] Skip"
        $c = Read-Host "Select"
    }
    if ($c -eq "1") {
        Start-Process "diskmgmt.msc"
        Skip-Result "Unallocated Disk Configuration" "Opened Disk Management for manual confirmation"
    } else {
        Skip-Result "Unallocated Disk Configuration" "User selected Skip"
    }
} else {
    Skip-Result "Unallocated Disk Configuration" "No uninitialized/unknown disks detected"
}

# ---------------- FINAL REPORT ----------------
Clear-Host
if ($AR) {
    Write-Color "╔══════════════════════════════════════════════════════════════╗" Cyan
    Write-Color "║                     التقرير النهائي                          ║" Cyan
    Write-Color "╚══════════════════════════════════════════════════════════════╝" Cyan
} else {
    Write-Color "╔══════════════════════════════════════════════════════════════╗" Cyan
    Write-Color "║                       FINAL REPORT                           ║" Cyan
    Write-Color "╚══════════════════════════════════════════════════════════════╝" Cyan
}

$success = @($Results | Where-Object Status -eq "SUCCESS").Count
$skipped = @($Results | Where-Object Status -eq "SKIPPED").Count
$errors  = @($Results | Where-Object Status -eq "ERROR").Count

Write-Host ""
if ($AR) {
    Write-Color "🟢 تم بنجاح: $success" Green
    Write-Color "↪ تم التخطي: $skipped" Yellow
    Write-Color "🔴 أخطاء: $errors" Red
} else {
    Write-Color "🟢 SUCCESSFUL: $success" Green
    Write-Color "↪ SKIPPED: $skipped" Yellow
    Write-Color "🔴 ERRORS: $errors" Red
}

Write-Host ""
foreach ($r in $Results) {
    switch ($r.Status) {
        "SUCCESS" {
            Write-Color "✓ $($r.Name)" Green
        }
        "SKIPPED" {
            Write-Color "↪ $($r.Name)" Yellow
            Write-Host "    $($r.Detail)"
        }
        "ERROR" {
            Write-Color "🔴 $($r.Name)" Red
            Write-Host "    $($r.Detail)"
        }
    }
}

$reportPath = Join-Path $env:USERPROFILE "Desktop\Windows11_Optimizer_Report.txt"
$Results | Format-Table -AutoSize | Out-String | Set-Content -Path $reportPath -Encoding UTF8

Write-Host ""
if ($AR) {
    Write-Color "تم حفظ نسخة من التقرير هنا:" Cyan
} else {
    Write-Color "A copy of the report was saved here:" Cyan
}
Write-Host $reportPath
Write-Host ""

if ($AR) {
    Write-Host "[1] عرض التقرير الكامل"
    Write-Host "[2] فتح مكان التقرير"
    Write-Host "[3] الخروج"
    $f = Read-Host "اختر"
} else {
    Write-Host "[1] View Full Report"
    Write-Host "[2] Open Report Location"
    Write-Host "[3] Exit"
    $f = Read-Host "Select"
}

if ($f -eq "1") {
    $Results | Format-Table -Wrap -AutoSize | Out-Host
    Pause-Continue
} elseif ($f -eq "2") {
    Start-Process explorer.exe "/select,`"$reportPath`""
}

Write-Host ""
if ($AR) {
    Write-Color "اكتمل تشغيل السكربت. يفضل إعادة تشغيل Windows لتطبيق بعض إعدادات الواجهة." Green
} else {
    Write-Color "The script has finished. A Windows restart is recommended for some UI changes." Green
}
