# Windows 11 Gaming Optimizer & Setup Assistant
# v1.1 - GUI / Arabic + English
# Run in Windows PowerShell as Administrator.
# No automatic backup is created.
# Designed primarily for new/fresh Windows 11 installations.
# The script continues after individual errors and shows SUCCESS / SKIPPED / ERROR.

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# ---------------- ADMIN ----------------
function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "Please run PowerShell as Administrator.`n`nيرجى تشغيل PowerShell كمسؤول.",
        "Windows 11 Gaming Optimizer",
        "OK",
        "Warning"
    ) | Out-Null
    exit
}

# ---------------- GUI ----------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:Results = New-Object System.Collections.Generic.List[object]
$script:Lang = "EN"
$script:Selected = $null
$script:Scan = $null

function Add-Result {
    param([string]$Name,[string]$Status,[string]$Detail="")
    $script:Results.Add([pscustomobject]@{
        Name=$Name; Status=$Status; Detail=$Detail
    })
}

function Safe-Run {
    param([string]$Name,[scriptblock]$Action)
    try {
        & $Action
        Add-Result $Name "SUCCESS"
        return $true
    } catch {
        Add-Result $Name "ERROR" $_.Exception.Message
        return $false
    }
}

function Safe-Skip {
    param([string]$Name,[string]$Reason)
    Add-Result $Name "SKIPPED" $Reason
}

function Get-AppxInstalled {
    param([string[]]$Patterns)
    $out = @()
    foreach ($p in $Patterns) {
        $out += @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like $p -or $_.PackageFullName -like $p })
    }
    @($out | Sort-Object PackageFullName -Unique)
}

function Remove-AppxSafe {
    param([string]$Name,[string[]]$Patterns)
    $pkgs = @(Get-AppxInstalled $Patterns)
    if ($pkgs.Count -eq 0) {
        Safe-Skip $Name "Already removed / not installed"
        return
    }
    Safe-Run $Name {
        foreach ($pkg in $pkgs) {
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
        }
    } | Out-Null
}

function Set-RegDword {
    param([string]$Path,[string]$Name,[int]$Value)
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
}

function Set-RegString {
    param([string]$Path,[string]$Name,[string]$Value)
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -PropertyType String -Value $Value -Force | Out-Null
}

function Format-GB {
    param($Bytes)
    if ($null -eq $Bytes) { return "Unknown" }
    return ("{0:N2} GB" -f ($Bytes / 1GB))
}

function Get-SystemScan {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    $board = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue | Select-Object -First 1
    $bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue | Select-Object -First 1
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $gpus = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
        Where-Object { $_.Name } |
        Select-Object Name,DriverVersion,PNPDeviceID)
    $disks = @(Get-Disk -ErrorAction SilentlyContinue |
        Select-Object Number,FriendlyName,Manufacturer,Model,SerialNumber,BusType,Size,PartitionStyle,OperationalStatus)
    $emptyDisks = @()
    foreach ($d in $disks) {
        $parts = @(Get-Partition -DiskNumber $d.Number -ErrorAction SilentlyContinue)
        if ($parts.Count -eq 0 -and $d.OperationalStatus -contains "Online" -and $d.Size -gt 0) {
            $emptyDisks += $d
        }
    }

    [pscustomobject]@{
        OS=$os
        CPU=$cpu
        Board=$board
        BIOS=$bios
        RAMGB=[math]::Round(($cs.TotalPhysicalMemory / 1GB),1)
        GPUs=$gpus
        Disks=$disks
        EmptyDisks=$emptyDisks
    }
}

# ---------------- TEXT ----------------
$TX = @{
    EN = @{
        Title="Windows 11 Gaming Optimizer & Setup Assistant"
        LangTitle="Choose your language"
        Arabic="العربية"
        English="English"
        DisclaimerTitle="Important Notice"
        Disclaimer="Designed primarily for new/fresh Windows 11 installations or PCs after a format.`n`nNo automatic backup is created.`nPersonal files are not intentionally deleted.`nSensitive disk operations are never performed automatically.`n`nYou can cancel at any time."
        Continue="Continue"
        Cancel="Cancel"
        ScanTitle="System Detection"
        ReviewTitle="Review Changes"
        Apply="Apply Changes"
        Back="Back"
        Rescan="Rescan"
        Finish="Finish"
        Close="Close"
        Device="Device"
        OS="Operating System"
        CPU="CPU"
        Board="Motherboard"
        BIOS="BIOS"
        RAM="Memory"
        GPU="GPU"
        Storage="Storage"
        Apps="Applications"
        Windows="Windows Settings"
        Privacy="Privacy"
        Gaming="Gaming & Performance"
        Network="Cleanup & Network"
        Drivers="GPU & Driver Check"
        Disks="Disk Review"
        Keep="Keep"
        Remove="Remove"
        Disable="Disable"
        Enable="Enable"
        Check="Check"
        NoChanges="No changes selected."
        Done="Finished"
        Success="Successful"
        Skipped="Skipped"
        Errors="Errors"
        Report="Final Report"
        ReportSaved="A TXT report was saved to your Desktop:"
        Restart="A Windows restart is recommended after finishing."
        OpenReport="Open Report"
        Unallocated="Unallocated / unmounted disk detected"
        DiskWarning="The following disk(s) have no partitions. They will NOT be formatted automatically."
        OpenDiskManagement="Open Disk Management"
        SkipDisk="Skip"
        GPUDetected="Detected GPU"
        OpenNvidia="Open official NVIDIA driver page"
        OpenAMD="Open official AMD driver page"
        OpenIntel="Open official Intel driver page"
        DriverSkip="Skip"
    }
    AR = @{
        Title="Windows 11 Gaming Optimizer & Setup Assistant"
        LangTitle="اختر اللغة"
        Arabic="العربية"
        English="English"
        DisclaimerTitle="تنبيه مهم"
        Disclaimer="مصمم بشكل أساسي لأجهزة Windows 11 الجديدة أو الأجهزة بعد الفورمات.`n`nلن يتم إنشاء Backup تلقائي.`nلن يتم حذف ملفاتك الشخصية عمدًا.`nعمليات الأقراص الحساسة لا يتم تنفيذها تلقائيًا.`n`nيمكنك الإلغاء في أي وقت."
        Continue="متابعة"
        Cancel="إلغاء"
        ScanTitle="فحص الجهاز"
        ReviewTitle="مراجعة التعديلات"
        Apply="موافق والمتابعة"
        Back="رجوع"
        Rescan="إعادة الفحص"
        Finish="إنهاء"
        Close="إغلاق"
        Device="الجهاز"
        OS="نظام التشغيل"
        CPU="المعالج"
        Board="اللوحة الأم"
        BIOS="BIOS"
        RAM="الذاكرة"
        GPU="كرت الشاشة"
        Storage="التخزين"
        Apps="التطبيقات والحذف"
        Windows="إعدادات Windows"
        Privacy="الخصوصية"
        Gaming="Gaming & Performance"
        Network="التنظيف والشبكة"
        Drivers="GPU & Driver Check"
        Disks="مراجعة الأقراص"
        Keep="إبقاء"
        Remove="حذف"
        Disable="تعطيل"
        Enable="تفعيل"
        Check="فحص"
        NoChanges="لا توجد تعديلات محددة."
        Done="اكتمل"
        Success="تم بنجاح"
        Skipped="تم التخطي"
        Errors="أخطاء"
        Report="التقرير النهائي"
        ReportSaved="تم حفظ تقرير TXT على سطح المكتب:"
        Restart="يفضل إعادة تشغيل Windows بعد الانتهاء."
        OpenReport="فتح التقرير"
        Unallocated="تم اكتشاف قرص غير مدرج / غير مقسم"
        DiskWarning="الأقراص التالية لا تحتوي على أقسام. لن يتم تهيئتها أو حذفها تلقائيًا."
        OpenDiskManagement="فتح Disk Management"
        SkipDisk="تخطي"
        GPUDetected="كرت الشاشة المكتشف"
        OpenNvidia="فتح صفحة تعريف NVIDIA الرسمية"
        OpenAMD="فتح صفحة تعريف AMD الرسمية"
        OpenIntel="فتح صفحة دعم Intel الرسمية"
        DriverSkip="تخطي"
    }
}

function T([string]$Key) { return $TX[$script:Lang][$Key] }

function New-BaseForm {
    param([string]$Title,[int]$Width=900,[int]$Height=650)
    $f = New-Object System.Windows.Forms.Form
    $f.Text=$Title
    $f.Size=New-Object System.Drawing.Size($Width,$Height)
    $f.StartPosition="CenterScreen"
    $f.MinimumSize=New-Object System.Drawing.Size(780,560)
    $f.BackColor=[System.Drawing.Color]::FromArgb(245,247,250)
    $f.Font=New-Object System.Drawing.Font("Segoe UI",10)
    if ($script:Lang -eq "AR") {
        $f.RightToLeft=[System.Windows.Forms.RightToLeft]::Yes
        $f.RightToLeftLayout=$true
    } else {
        $f.RightToLeft=[System.Windows.Forms.RightToLeft]::No
        $f.RightToLeftLayout=$false
    }
    return $f
}

function Add-Header {
    param($Form,[string]$Title,[string]$Subtitle="")
    $p=New-Object System.Windows.Forms.Panel
    $p.Dock="Top"; $p.Height=82
    $p.BackColor=[System.Drawing.Color]::FromArgb(20,30,45)
    $Form.Controls.Add($p)

    $l=New-Object System.Windows.Forms.Label
    $l.Text=$Title
    $l.ForeColor=[System.Drawing.Color]::White
    $l.Font=New-Object System.Drawing.Font("Segoe UI Semibold",18)
    $l.AutoSize=$true
    $l.Location=New-Object System.Drawing.Point(24,14)
    if ($script:Lang -eq "AR") { $l.RightToLeft="Yes"; $l.Anchor="Top,Right" }
    $p.Controls.Add($l)

    if ($Subtitle) {
        $s=New-Object System.Windows.Forms.Label
        $s.Text=$Subtitle
        $s.ForeColor=[System.Drawing.Color]::Gainsboro
        $s.Font=New-Object System.Drawing.Font("Segoe UI",9)
        $s.AutoSize=$true
        $s.Location=New-Object System.Drawing.Point(26,49)
        $p.Controls.Add($s)
    }
}

function New-Button {
    param([string]$Text,[int]$Width=150)
    $b=New-Object System.Windows.Forms.Button
    $b.Text=$Text
    $b.Width=$Width
    $b.Height=40
    $b.FlatStyle="Flat"
    $b.FlatAppearance.BorderSize=0
    $b.BackColor=[System.Drawing.Color]::FromArgb(30,120,210)
    $b.ForeColor=[System.Drawing.Color]::White
    $b.Font=New-Object System.Drawing.Font("Segoe UI Semibold",10)
    return $b
}

function Show-Language {
    $f=New-BaseForm "Windows 11 Gaming Optimizer" 650 420
    Add-Header $f "Windows 11 Gaming Optimizer" "Gaming Optimizer & Setup Assistant"

    $label=New-Object System.Windows.Forms.Label
    $label.Text="Choose your language / اختر اللغة"
    $label.Font=New-Object System.Drawing.Font("Segoe UI Semibold",16)
    $label.AutoSize=$true
    $label.Location=New-Object System.Drawing.Point(190,145)
    $f.Controls.Add($label)

    $ar=New-Button "العربية" 160
    $ar.Location=New-Object System.Drawing.Point(155,215)
    $en=New-Button "English" 160
    $en.Location=New-Object System.Drawing.Point(335,215)
    $f.Controls.AddRange(@($ar,$en))

    $script:Selected=$null
    $ar.Add_Click({ $script:Lang="AR"; $script:Selected=$true; $f.Close() })
    $en.Add_Click({ $script:Lang="EN"; $script:Selected=$true; $f.Close() })
    [void]$f.ShowDialog()
    return $script:Selected
}

function Show-Disclaimer {
    $f=New-BaseForm (T "DisclaimerTitle") 760 500
    Add-Header $f (T "DisclaimerTitle") (T "Title")

    $box=New-Object System.Windows.Forms.TextBox
    $box.Multiline=$true
    $box.ReadOnly=$true
    $box.BorderStyle="None"
    $box.BackColor=$f.BackColor
    $box.Font=New-Object System.Drawing.Font("Segoe UI",12)
    $box.Text=(T "Disclaimer")
    $box.Location=New-Object System.Drawing.Point(45,125)
    $box.Size=New-Object System.Drawing.Size(660,210)
    if ($script:Lang -eq "AR") { $box.RightToLeft="Yes" }
    $f.Controls.Add($box)

    $ok=New-Button (T "Continue") 170
    $ok.Location=New-Object System.Drawing.Point(405,385)
    $no=New-Button (T "Cancel") 140
    $no.BackColor=[System.Drawing.Color]::FromArgb(110,115,125)
    $no.Location=New-Object System.Drawing.Point(230,385)
    $f.Controls.AddRange(@($ok,$no))
    $ok.Add_Click({ $script:Selected=$true; $f.Close() })
    $no.Add_Click({ $script:Selected=$false; $f.Close() })
    $script:Selected=$false
    [void]$f.ShowDialog()
    return $script:Selected
}

function Show-Scan {
    $script:Scan=Get-SystemScan
    $f=New-BaseForm (T "ScanTitle") 980 700
    Add-Header $f (T "ScanTitle") (T "Title")

    $info=New-Object System.Windows.Forms.TextBox
    $info.Multiline=$true
    $info.ReadOnly=$true
    $info.ScrollBars="Vertical"
    $info.BackColor=[System.Drawing.Color]::White
    $info.Location=New-Object System.Drawing.Point(25,105)
    $info.Size=New-Object System.Drawing.Size(930,450)
    $info.Font=New-Object System.Drawing.Font("Consolas",10)

    $os=$script:Scan.OS
    $cpu=$script:Scan.CPU
    $board=$script:Scan.Board
    $bios=$script:Scan.BIOS

    $text = @()
    $text += "$(T 'Device')"
    $text += "────────────────────────────────────────"
    $text += "$(T 'OS') : $($os.Caption) $($os.Version) / Build $($os.BuildNumber)"
    $text += "$(T 'CPU'): $($cpu.Name)"
    $text += "$(T 'Board'): $($board.Manufacturer) $($board.Product)"
    $text += "$(T 'BIOS'): $($bios.SMBIOSBIOSVersion)"
    $text += "$(T 'RAM'): $($script:Scan.RAMGB) GB"
    $text += ""
    $text += "$(T 'GPU')"
    $text += "────────────────────────────────────────"
    foreach($g in $script:Scan.GPUs) {
        $text += "$($g.Name) | Driver: $($g.DriverVersion)"
    }
    $text += ""
    $text += "$(T 'Storage')"
    $text += "────────────────────────────────────────"
    foreach($d in $script:Scan.Disks) {
        $text += "Disk $($d.Number) | $($d.Model) | $(Format-GB $d.Size) | $($d.BusType) | $($d.PartitionStyle)"
    }

    $info.Text=($text -join [Environment]::NewLine)
    $f.Controls.Add($info)

    $next=New-Button (T "Continue") 160
    $next.Location=New-Object System.Drawing.Point(780,585)
    $rescan=New-Button (T "Rescan") 130
    $rescan.BackColor=[System.Drawing.Color]::FromArgb(100,105,115)
    $rescan.Location=New-Object System.Drawing.Point(635,585)
    $cancel=New-Button (T "Cancel") 130
    $cancel.BackColor=[System.Drawing.Color]::FromArgb(100,105,115)
    $cancel.Location=New-Object System.Drawing.Point(490,585)
    $f.Controls.AddRange(@($next,$rescan,$cancel))

    $next.Add_Click({ $script:Selected=$true; $f.Close() })
    $cancel.Add_Click({ $script:Selected=$false; $f.Close() })
    $rescan.Add_Click({
        $script:Scan=Get-SystemScan
        $f.Close()
        $script:Selected="RESCAN"
    })
    $script:Selected=$false
    [void]$f.ShowDialog()
    return $script:Selected
}

function Get-Proposals {
    @(
        [pscustomobject]@{Cat="Apps"; Item="OneDrive"; Action="Remove"; Detail="Uninstall OneDrive"; Enabled=$true}
        [pscustomobject]@{Cat="Apps"; Item="Microsoft Teams"; Action="Remove"; Detail="Remove Teams app"; Enabled=$true}
        [pscustomobject]@{Cat="Apps"; Item="Clipchamp"; Action="Remove"; Detail="Remove Clipchamp"; Enabled=$true}
        [pscustomobject]@{Cat="Apps"; Item="News / Weather / Tips / Get Help / Maps / People / Solitaire"; Action="Remove"; Detail="Remove unwanted consumer apps"; Enabled=$true}
        [pscustomobject]@{Cat="Windows"; Item="Dark Mode"; Action="Enable"; Detail="Enable Windows dark theme"; Enabled=$true}
        [pscustomobject]@{Cat="Windows"; Item="Black Wallpaper"; Action="Enable"; Detail="Set Windows wallpaper"; Enabled=$true}
        [pscustomobject]@{Cat="Windows"; Item="Taskbar Search"; Action="Change"; Detail="Search icon only"; Enabled=$true}
        [pscustomobject]@{Cat="Windows"; Item="Task View"; Action="Disable"; Detail="Hide Task View button"; Enabled=$true}
        [pscustomobject]@{Cat="Windows"; Item="Widgets"; Action="Disable"; Detail="Hide Widgets"; Enabled=$true}
        [pscustomobject]@{Cat="Windows"; Item="Recall"; Action="Disable"; Detail="Disable Recall policy when supported"; Enabled=$true}
        [pscustomobject]@{Cat="Windows"; Item="Thumbnails"; Action="Keep"; Detail="Image/Video thumbnails stay enabled"; Enabled=$false}
        [pscustomobject]@{Cat="Windows"; Item="ClearType / Font Smoothing"; Action="Keep"; Detail="No changes"; Enabled=$false}
        [pscustomobject]@{Cat="Privacy"; Item="Advertising ID"; Action="Disable"; Detail="Disable advertising ID"; Enabled=$true}
        [pscustomobject]@{Cat="Privacy"; Item="Optional Diagnostic Data"; Action="Disable"; Detail="Restrict optional telemetry"; Enabled=$true}
        [pscustomobject]@{Cat="Privacy"; Item="Windows Suggestions"; Action="Disable"; Detail="Disable consumer suggestions"; Enabled=$true}
        [pscustomobject]@{Cat="Privacy"; Item="Camera Permission"; Action="Keep"; Detail="Permission is not changed"; Enabled=$false}
        [pscustomobject]@{Cat="Privacy"; Item="Microphone Permission"; Action="Keep"; Detail="Permission is not changed"; Enabled=$false}
        [pscustomobject]@{Cat="Gaming"; Item="Game Mode"; Action="Enable"; Detail="Enable Game Mode"; Enabled=$true}
        [pscustomobject]@{Cat="Gaming"; Item="Hardware-Accelerated GPU Scheduling"; Action="Enable"; Detail="Enable HAGS when supported"; Enabled=$true}
        [pscustomobject]@{Cat="Gaming"; Item="Power Plan"; Action="Change"; Detail="High Performance when available"; Enabled=$true}
        [pscustomobject]@{Cat="Network"; Item="Temporary Files"; Action="Clean"; Detail="Clean temporary files"; Enabled=$true}
        [pscustomobject]@{Cat="Network"; Item="DNS Cache"; Action="Clean"; Detail="Clear DNS cache"; Enabled=$true}
        [pscustomobject]@{Cat="Network"; Item="Windows Update"; Action="Check"; Detail="Start Windows Update scan"; Enabled=$true}
        [pscustomobject]@{Cat="Drivers"; Item="GPU Detection"; Action="Check"; Detail="Detect NVIDIA / AMD / Intel"; Enabled=$true}
        [pscustomobject]@{Cat="Disks"; Item="Unallocated / Unmounted Disks"; Action="Review"; Detail="Show model/company and open Disk Management"; Enabled=$true}
    )
}

function Cat-Name($c) {
    switch($c) {
        "Apps" { T "Apps" }
        "Windows" { T "Windows" }
        "Privacy" { T "Privacy" }
        "Gaming" { T "Gaming" }
        "Network" { T "Network" }
        "Drivers" { T "Drivers" }
        "Disks" { T "Disks" }
    }
}

function Action-Text($a) {
    switch($a) {
        "Remove" { T "Remove" }
        "Disable" { T "Disable" }
        "Enable" { T "Enable" }
        "Keep" { T "Keep" }
        default { $a }
    }
}

function Show-Review {
    $props=Get-Proposals
    $f=New-BaseForm (T "ReviewTitle") 1050 760
    Add-Header $f (T "ReviewTitle") (T "Title")

    $panel=New-Object System.Windows.Forms.Panel
    $panel.Location=New-Object System.Drawing.Point(20,100)
    $panel.Size=New-Object System.Drawing.Size(990,515)
    $panel.AutoScroll=$true
    $panel.BackColor=[System.Drawing.Color]::White
    $f.Controls.Add($panel)

    $y=15
    $catColors=@{
        Apps=[System.Drawing.Color]::IndianRed
        Windows=[System.Drawing.Color]::Goldenrod
        Privacy=[System.Drawing.Color]::SteelBlue
        Gaming=[System.Drawing.Color]::SeaGreen
        Network=[System.Drawing.Color]::DarkCyan
        Drivers=[System.Drawing.Color]::MediumPurple
        Disks=[System.Drawing.Color]::Firebrick
    }

    $checks=New-Object System.Collections.Generic.List[object]
    $lastCat=""
    foreach($p in $props) {
        if($p.Cat -ne $lastCat) {
            $h=New-Object System.Windows.Forms.Label
            $h.Text=Cat-Name $p.Cat
            $h.ForeColor=$catColors[$p.Cat]
            $h.Font=New-Object System.Drawing.Font("Segoe UI Semibold",12)
            $h.AutoSize=$true
            $h.Location=New-Object System.Drawing.Point(20,$y)
            $panel.Controls.Add($h)
            $y += 32
            $lastCat=$p.Cat
        }

        $cb=New-Object System.Windows.Forms.CheckBox
        $cb.Text="$($p.Item)   →   $(Action-Text $p.Action)"
        $cb.Checked=$p.Enabled
        $cb.AutoSize=$false
        $cb.Width=900
        $cb.Height=28
        $cb.Location=New-Object System.Drawing.Point(40,$y)
        if(-not $p.Enabled) { $cb.Enabled=$false }
        if($script:Lang -eq "AR") { $cb.RightToLeft="Yes" }
        $panel.Controls.Add($cb)
        $checks.Add([pscustomobject]@{Box=$cb; Proposal=$p})
        $y += 31
    }

    $apply=New-Button (T "Apply") 180
    $apply.Location=New-Object System.Drawing.Point(800,640)
    $back=New-Button (T "Back") 130
    $back.BackColor=[System.Drawing.Color]::FromArgb(100,105,115)
    $back.Location=New-Object System.Drawing.Point(655,640)
    $cancel=New-Button (T "Cancel") 130
    $cancel.BackColor=[System.Drawing.Color]::FromArgb(100,105,115)
    $cancel.Location=New-Object System.Drawing.Point(510,640)
    $f.Controls.AddRange(@($apply,$back,$cancel))

    $script:Selected=$false
    $apply.Add_Click({
        $script:Chosen=@($checks | Where-Object { $_.Box.Checked } | ForEach-Object { $_.Proposal })
        $script:Selected=$true
        $f.Close()
    })
    $back.Add_Click({ $script:Selected="BACK"; $f.Close() })
    $cancel.Add_Click({ $script:Selected=$false; $f.Close() })
    [void]$f.ShowDialog()
    return $script:Selected
}

function Apply-Selected {
    param($Chosen)

    foreach($p in $Chosen) {
        switch($p.Item) {
            "OneDrive" {
                $exe="$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
                if(-not(Test-Path $exe)){ $exe="$env:SystemRoot\System32\OneDriveSetup.exe" }
                if(Test-Path $exe) {
                    Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                    Safe-Run "OneDrive" { Start-Process $exe "/uninstall" -Wait -NoNewWindow } | Out-Null
                } else { Safe-Skip "OneDrive" "Installer not found / already removed" }
            }
            "Microsoft Teams" {
                $pkgs=@(Get-AppxInstalled @("*MSTeams*"))
                if($pkgs.Count){ Safe-Run "Microsoft Teams" { foreach($x in $pkgs){ Remove-AppxPackage -Package $x.PackageFullName -AllUsers -ErrorAction Stop } } | Out-Null }
                else { Safe-Skip "Microsoft Teams" "Already removed / not installed" }
            }
            "Clipchamp" { Remove-AppxSafe "Clipchamp" @("*Clipchamp*") }
            "News / Weather / Tips / Get Help / Maps / People / Solitaire" {
                Remove-AppxSafe "News" @("*BingNews*")
                Remove-AppxSafe "Weather" @("*BingWeather*")
                Remove-AppxSafe "Tips" @("*Getstarted*","*MicrosoftTips*")
                Remove-AppxSafe "Get Help" @("*GetHelp*")
                Remove-AppxSafe "Maps" @("*WindowsMaps*")
                Remove-AppxSafe "People" @("*MicrosoftPeople*")
                Remove-AppxSafe "Solitaire" @("*MicrosoftSolitaireCollection*")
            }
            "Dark Mode" {
                Safe-Run "Dark Mode" {
                    Set-RegDword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0
                    Set-RegDword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0
                } | Out-Null
            }
            "Black Wallpaper" {
                Safe-Run "Black Wallpaper" {
                    Add-Type @'
using System;
using System.Runtime.InteropServices;
public class WinWallpaper {
 [DllImport("user32.dll", CharSet=CharSet.Unicode)]
 public static extern int SystemParametersInfo(int uAction,int uParam,string lpvParam,int fuWinIni);
}
'@
                    $path="$env:WINDIR\Web\Wallpaper\Windows\img0.jpg"
                    if(Test-Path $path){
                        Set-RegString "HKCU:\Control Panel\Desktop" "Wallpaper" $path
                        [WinWallpaper]::SystemParametersInfo(20,0,$path,3) | Out-Null
                    } else { throw "Windows wallpaper resource not found" }
                } | Out-Null
            }
            "Taskbar Search" {
                Safe-Run "Taskbar Search" {
                    Set-RegDword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 1
                } | Out-Null
            }
            "Task View" {
                Safe-Run "Task View" {
                    Set-RegDword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" 0
                } | Out-Null
            }
            "Widgets" {
                Safe-Run "Widgets" {
                    Set-RegDword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 0
                } | Out-Null
            }
            "Recall" {
                Safe-Run "Recall" {
                    Set-RegDword "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
                } | Out-Null
            }
            "Advertising ID" {
                Safe-Run "Advertising ID" {
                    Set-RegDword "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
                } | Out-Null
            }
            "Optional Diagnostic Data" {
                Safe-Run "Optional Diagnostic Data" {
                    Set-RegDword "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
                } | Out-Null
            }
            "Windows Suggestions" {
                Safe-Run "Windows Suggestions" {
                    $p="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
                    foreach($n in @("SubscribedContent-338388Enabled","SubscribedContent-338389Enabled","SubscribedContent-353694Enabled","SubscribedContent-353696Enabled","SystemPaneSuggestionsEnabled")){
                        Set-RegDword $p $n 0
                    }
                } | Out-Null
            }
            "Game Mode" {
                Safe-Run "Game Mode" {
                    Set-RegDword "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 1
                } | Out-Null
            }
            "Hardware-Accelerated GPU Scheduling" {
                Safe-Run "Hardware-Accelerated GPU Scheduling" {
                    Set-RegDword "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2
                } | Out-Null
            }
            "Power Plan" {
                Safe-Run "Power Plan" {
                    $hp=powercfg /list 2>$null | Select-String "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
                    if($hp){ powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c | Out-Null }
                    else { throw "High Performance power plan unavailable" }
                } | Out-Null
            }
            "Temporary Files" {
                Safe-Run "Temporary Files" {
                    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Remove-Item "$env:WINDIR\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
                } | Out-Null
            }
            "DNS Cache" {
                Safe-Run "DNS Cache" { Clear-DnsClientCache } | Out-Null
            }
            "Windows Update" {
                Safe-Run "Windows Update" {
                    $u="$env:SystemRoot\System32\UsoClient.exe"
                    if(Test-Path $u){ Start-Process $u "StartScan" -WindowStyle Hidden }
                    else { throw "Windows Update client unavailable" }
                } | Out-Null
            }
            "GPU Detection" {
                Safe-Skip "GPU Detection" "Detection is shown in the scan; no driver is installed automatically"
            }
            "Unallocated / Unmounted Disks" {
                Safe-Skip "Unallocated / Unmounted Disks" "Handled in Disk Review"
            }
        }
    }
}

function Show-GPUAndDiskReview {
    $f=New-BaseForm (T "Drivers") 950 680
    Add-Header $f (T "Drivers") (T "Title")

    $box=New-Object System.Windows.Forms.TextBox
    $box.Multiline=$true
    $box.ReadOnly=$true
    $box.ScrollBars="Vertical"
    $box.BackColor=[System.Drawing.Color]::White
    $box.Location=New-Object System.Drawing.Point(25,105)
    $box.Size=New-Object System.Drawing.Size(900,400)
    $box.Font=New-Object System.Drawing.Font("Consolas",10)

    $lines=@()
    $lines += "$(T 'GPUDetected')"
    $lines += "────────────────────────────────────────"
    foreach($g in $script:Scan.GPUs){
        $lines += "$($g.Name) | Driver: $($g.DriverVersion)"
    }
    if($script:Scan.GPUs.Count -eq 0){ $lines += "No GPU detected." }
    $lines += ""
    $lines += "$(T 'Disks')"
    $lines += "────────────────────────────────────────"
    foreach($d in $script:Scan.EmptyDisks){
        $company=$d.Manufacturer
        if([string]::IsNullOrWhiteSpace($company)){ $company="Unknown manufacturer" }
        $model=$d.Model
        if([string]::IsNullOrWhiteSpace($model)){ $model=$d.FriendlyName }
        $lines += "Disk $($d.Number) | $company | $model | $(Format-GB $d.Size)"
    }
    if($script:Scan.EmptyDisks.Count -eq 0){ $lines += "No disk without partitions detected." }

    $box.Text=($lines -join [Environment]::NewLine)
    $f.Controls.Add($box)

    $nvidia=New-Button (T "OpenNvidia") 210
    $nvidia.Location=New-Object System.Drawing.Point(25,535)
    $amd=New-Button (T "OpenAMD") 190
    $amd.Location=New-Object System.Drawing.Point(245,535)
    $intel=New-Button (T "OpenIntel") 190
    $intel.Location=New-Object System.Drawing.Point(445,535)
    $disk=New-Button (T "OpenDiskManagement") 190
    $disk.Location=New-Object System.Drawing.Point(645,535)
    $close=New-Button (T "Finish") 130
    $close.BackColor=[System.Drawing.Color]::FromArgb(100,105,115)
    $close.Location=New-Object System.Drawing.Point(790,590)
    $f.Controls.AddRange(@($nvidia,$amd,$intel,$disk,$close))

    $nvidia.Add_Click({ Start-Process "https://www.nvidia.com/Download/index.aspx"; Safe-Skip "NVIDIA Driver" "Official page opened" })
    $amd.Add_Click({ Start-Process "https://www.amd.com/en/support/download/drivers.html"; Safe-Skip "AMD Driver" "Official page opened" })
    $intel.Add_Click({ Start-Process "https://www.intel.com/content/www/us/en/support/detect.html"; Safe-Skip "Intel Driver" "Official page opened" })
    $disk.Add_Click({ Start-Process "diskmgmt.msc"; Safe-Skip "Disk Management" "Disk Management opened; no formatting performed" })
    $close.Add_Click({ $f.Close() })
    [void]$f.ShowDialog()
}

function Show-ProgressAndReport {
    $f=New-BaseForm (T "Report") 1000 720
    Add-Header $f (T "Report") (T "Title")

    $grid=New-Object System.Windows.Forms.DataGridView
    $grid.Location=New-Object System.Drawing.Point(25,105)
    $grid.Size=New-Object System.Drawing.Size(930,430)
    $grid.ReadOnly=$true
    $grid.AllowUserToAddRows=$false
    $grid.AutoSizeColumnsMode="Fill"
    $grid.BackgroundColor=[System.Drawing.Color]::White
    $grid.DataSource=@($script:Results)
    $f.Controls.Add($grid)

    $success=@($script:Results | Where-Object Status -eq "SUCCESS").Count
    $skip=@($script:Results | Where-Object Status -eq "SKIPPED").Count
    $err=@($script:Results | Where-Object Status -eq "ERROR").Count

    $summary=New-Object System.Windows.Forms.Label
    $summary.Text="$(T 'Success'): $success     $(T 'Skipped'): $skip     $(T 'Errors'): $err"
    $summary.Font=New-Object System.Drawing.Font("Segoe UI Semibold",12)
    $summary.AutoSize=$true
    $summary.Location=New-Object System.Drawing.Point(25,555)
    $f.Controls.Add($summary)

    $path=Join-Path $env:USERPROFILE "Desktop\Windows11_Optimizer_Report.txt"
    $script:Results | Format-Table -Wrap -AutoSize | Out-String | Set-Content -Path $path -Encoding UTF8

    $saved=New-Object System.Windows.Forms.Label
    $saved.Text="$(T 'ReportSaved')`n$path`n`n$(T 'Restart')"
    $saved.AutoSize=$true
    $saved.Location=New-Object System.Drawing.Point(25,585)
    $f.Controls.Add($saved)

    $open=New-Button (T "OpenReport") 150
    $open.Location=New-Object System.Drawing.Point(785,610)
    $close=New-Button (T "Close") 120
    $close.BackColor=[System.Drawing.Color]::FromArgb(100,105,115)
    $close.Location=New-Object System.Drawing.Point(645,610)
    $f.Controls.AddRange(@($open,$close))

    $open.Add_Click({ Start-Process notepad.exe $path })
    $close.Add_Click({ $f.Close() })
    [void]$f.ShowDialog()
}

# ---------------- MAIN FLOW ----------------
if(-not (Show-Language)){ exit }
if(-not (Show-Disclaimer)){ exit }

do {
    $r=Show-Scan
} while($r -eq "RESCAN")
if(-not $r){ exit }

$rr=Show-Review
if($rr -eq "BACK"){
    do { $r=Show-Scan } while($r -eq "RESCAN")
    if(-not $r){ exit }
    $rr=Show-Review
}
if(-not $rr){ exit }

Apply-Selected $script:Chosen

Show-GPUAndDiskReview
Show-ProgressAndReport
