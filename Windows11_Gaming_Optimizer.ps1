#requires -version 5.1
<#
Windows 11 Gaming Optimizer v1.4
Lightweight WinForms GUI
- No backup
- Does NOT format/partition disks
- Does NOT delete personal files
- Keeps Snipping Tool and Xbox
- Does not change camera/microphone permissions
- Hyper-V, thumbnails and ClearType are untouched
#>

$ErrorActionPreference = 'Continue'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:Lang = 'en'
$script:Results = New-Object System.Collections.ArrayList

function L([string]$en,[string]$ar) {
    if ($script:Lang -eq 'ar') { return $ar }
    return $en
}

function Add-Result {
    param([string]$Category,[string]$Item,[string]$Status,[string]$Details = '')
    [void]$script:Results.Add([pscustomobject]@{
        Time = Get-Date -Format 'HH:mm:ss'
        Category = $Category
        Item = $Item
        Status = $Status
        Details = $Details
    })
}

function Run-Safe {
    param([string]$Name,[scriptblock]$Action,[string]$Category = 'Optimization')
    try {
        & $Action
        Add-Result $Category $Name 'SUCCESS'
    }
    catch {
        Add-Result $Category $Name 'ERROR' $_.Exception.Message
    }
}

function Set-Reg {
    param(
        [string]$Path,
        [string]$Name,
        $Value,
        [Microsoft.Win32.RegistryValueKind]$Type = [Microsoft.Win32.RegistryValueKind]::DWord
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-RealGPU {
    try {
        Get-CimInstance Win32_VideoController |
            Where-Object {
                $_.Name -and
                $_.Name -notmatch 'Parsec|Virtual Display|Microsoft Basic|Indirect Display'
            } |
            Select-Object -First 1
    }
    catch { return $null }
}

function Get-StorageReport {
    $lines = New-Object System.Collections.Generic.List[string]

    try {
        $disks = Get-CimInstance Win32_DiskDrive | Sort-Object Index
        foreach ($d in $disks) {
            $size = if ($d.Size) { [math]::Round($d.Size / 1GB, 2) } else { 0 }
            $lines.Add(("Disk {0} | {1} | {2} GB | {3}" -f $d.Index,$d.Model,$size,$d.InterfaceType))

            $parts = @(Get-CimInstance Win32_DiskPartition -Filter "DiskIndex=$($d.Index)" -ErrorAction SilentlyContinue)
            if ($parts.Count -eq 0) {
                $lines.Add('  -> UNALLOCATED / NO PARTITIONS DETECTED (not modified)')
            }
        }
    }
    catch {
        $lines.Add("Storage scan error: $($_.Exception.Message)")
    }

    return ($lines -join [Environment]::NewLine)
}

function Scan-Device {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $board = Get-CimInstance Win32_BaseBoard | Select-Object -First 1
        $bios = Get-CimInstance Win32_BIOS | Select-Object -First 1
        $gpu = Get-RealGPU
        $ram = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)

        $text = @"
WINDOWS 11 GAMING OPTIMIZER - DEVICE SCAN
==========================================

OS          : $($os.Caption)
Build       : $($os.BuildNumber)
CPU         : $($cpu.Name)
GPU         : $(if ($gpu) { $gpu.Name } else { 'Not detected' })
RAM         : $ram GB
Motherboard : $($board.Manufacturer) $($board.Product)
BIOS        : $($bios.SMBIOSBIOSVersion)

STORAGE
=======
$(Get-StorageReport)

NOTE
====
Unallocated disks are detected only.
The optimizer NEVER formats or partitions them automatically.
"@

        Add-Result 'Device Scan' 'Hardware and storage scan' 'SUCCESS'
        $script:scanText = $text
        return $text
    }
    catch {
        Add-Result 'Device Scan' 'Hardware and storage scan' 'ERROR' $_.Exception.Message
        return "Scan error: $($_.Exception.Message)"
    }
}

$Options = @(
    [pscustomobject]@{
        Key='OneDrive'; En='Remove OneDrive'; Ar='حذف OneDrive'
        Action={
            $paths = @(
                "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
                "$env:SystemRoot\System32\OneDriveSetup.exe"
            )
            $p = $paths | Where-Object { Test-Path $_ } | Select-Object -First 1
            if (-not $p) { throw 'OneDriveSetup.exe not found' }
            Start-Process $p '/uninstall' -Wait -WindowStyle Hidden
        }
    },
    [pscustomobject]@{
        Key='Teams'; En='Remove Microsoft Teams'; Ar='حذف Microsoft Teams'
        Action={
            $pkgs = @(Get-AppxPackage -AllUsers '*MicrosoftTeams*' -ErrorAction SilentlyContinue)
            if ($pkgs.Count -eq 0) { throw 'Microsoft Teams package not found' }
            foreach ($p in $pkgs) {
                Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Stop
            }
        }
    },
    [pscustomobject]@{
        Key='Widgets'; En='Disable Widgets'; Ar='تعطيل Widgets'
        Action={
            Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarDa' 0
            Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0
        }
    },
    [pscustomobject]@{
        Key='TaskView'; En='Disable Task View'; Ar='تعطيل Task View'
        Action={
            Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowTaskViewButton' 0
        }
    },
    [pscustomobject]@{
        Key='Recall'; En='Disable Recall'; Ar='تعطيل Recall'
        Action={
            Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableRecall' 1
            Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 1
        }
    },
    [pscustomobject]@{
        Key='Search'; En='Search as icon'; Ar='تحويل البحث إلى أيقونة'
        Action={
            Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'SearchboxTaskbarMode' 1
        }
    },
    [pscustomobject]@{
        Key='Dark'; En='Dark theme'; Ar='الثيم الداكن'
        Action={
            Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'AppsUseLightTheme' 0
            Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'SystemUsesLightTheme' 0
        }
    },
    [pscustomobject]@{
        Key='Wallpaper'; En='Black desktop background'; Ar='خلفية سطح المكتب سوداء'
        Action={
            Set-Reg 'HKCU:\Control Panel\Colors' 'Background' '0 0 0' String
            Set-Reg 'HKCU:\Control Panel\Desktop' 'Wallpaper' '' String
        }
    },
    [pscustomobject]@{
        Key='Privacy'; En='Reduce telemetry / advertising ID'; Ar='تقليل جمع البيانات ومعرف الإعلانات'
        Action={
            Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
            Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
        }
    },
    [pscustomobject]@{
        Key='GameMode'; En='Enable Game Mode'; Ar='تفعيل Game Mode'
        Action={
            Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1
            Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
        }
    },
    [pscustomobject]@{
        Key='DVR'; En='Disable Game DVR capture'; Ar='تعطيل Game DVR'
        Action={
            Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
            Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
        }
    },
    [pscustomobject]@{
        Key='Power'; En='Reduce Power Throttling'; Ar='تقليل Power Throttling'
        Action={
            Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 1
        }
    },
    [pscustomobject]@{
        Key='Network'; En='Conservative network optimization'; Ar='تحسينات شبكة محافظة'
        Action={
            & netsh interface tcp set global rss=enabled | Out-Null
            & netsh interface tcp set global autotuninglevel=normal | Out-Null
            & netsh interface tcp set global timestamps=disabled | Out-Null
        }
    }
)

$Apps = @(
    [pscustomobject]@{ Name='Discord'; Id='Discord.Discord' },
    [pscustomobject]@{ Name='Google Chrome'; Id='Google.Chrome' },
    [pscustomobject]@{ Name='Brave Browser'; Id='Brave.Brave' },
    [pscustomobject]@{ Name='Parsec'; Id='Parsec.Parsec' }
)

$gpu = Get-RealGPU
if ($gpu -and $gpu.Name -match 'NVIDIA|GeForce') {
    $Apps += [pscustomobject]@{ Name='NVIDIA App'; Id='Nvidia.NVIDIAApp' }
}
elseif ($gpu -and $gpu.Name -match 'AMD|Radeon') {
    $Apps += [pscustomobject]@{ Name='AMD Software: Adrenalin Edition'; Id='AMD.AMDSoftware' }
}

# ---------------- GUI ----------------

$colors = @{
    Bg     = [Drawing.Color]::FromArgb(12,17,25)
    Panel  = [Drawing.Color]::FromArgb(20,28,40)
    Panel2 = [Drawing.Color]::FromArgb(28,38,54)
    Text   = [Drawing.Color]::FromArgb(235,241,248)
    Muted  = [Drawing.Color]::FromArgb(155,168,185)
    Blue   = [Drawing.Color]::FromArgb(45,125,240)
    Green  = [Drawing.Color]::FromArgb(35,185,112)
}

$form = New-Object Windows.Forms.Form
$form.Text = 'Windows 11 Gaming Optimizer'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object Drawing.Size(1080,700)
$form.MinimumSize = New-Object Drawing.Size(950,620)
$form.BackColor = $colors.Bg
$form.Font = New-Object Drawing.Font('Segoe UI',10)

$side = New-Object Windows.Forms.Panel
$side.Dock = 'Left'
$side.Width = 215
$side.BackColor = [Drawing.Color]::FromArgb(16,22,32)
$form.Controls.Add($side)

$main = New-Object Windows.Forms.Panel
$main.Dock = 'Fill'
$main.BackColor = $colors.Bg
$form.Controls.Add($main)

$title = New-Object Windows.Forms.Label
$title.Text = 'Windows 11 Gaming Optimizer'
$title.ForeColor = $colors.Text
$title.Font = New-Object Drawing.Font('Segoe UI Semibold',14)
$title.AutoSize = $true
$title.Location = New-Object Drawing.Point(18,20)
$side.Controls.Add($title)

$version = New-Object Windows.Forms.Label
$version.Text = 'v1.4 • Lightweight'
$version.ForeColor = $colors.Blue
$version.AutoSize = $true
$version.Location = New-Object Drawing.Point(20,50)
$side.Controls.Add($version)

$nav = New-Object Windows.Forms.FlowLayoutPanel
$nav.Location = New-Object Drawing.Point(12,90)
$nav.Size = New-Object Drawing.Size(190,430)
$nav.FlowDirection = 'TopDown'
$nav.WrapContents = $false
$nav.BackColor = $side.BackColor
$side.Controls.Add($nav)

function New-NavButton([string]$Text) {
    $b = New-Object Windows.Forms.Button
    $b.Text = "  $Text"
    $b.Width = 185
    $b.Height = 42
    $b.FlatStyle = 'Flat'
    $b.FlatAppearance.BorderSize = 0
    $b.BackColor = $side.BackColor
    $b.ForeColor = $colors.Text
    $b.TextAlign = 'MiddleLeft'
    return $b
}

$homeBtn = New-NavButton 'Home'
$scanBtn = New-NavButton 'Device Scan'
$optBtn = New-NavButton 'Optimization'
$appBtn = New-NavButton 'Optional Apps'
$resBtn = New-NavButton 'Results'
$nav.Controls.AddRange(@($homeBtn,$scanBtn,$optBtn,$appBtn,$resBtn))

$lang = New-Object Windows.Forms.ComboBox
$lang.DropDownStyle = 'DropDownList'
[void]$lang.Items.Add('English')
[void]$lang.Items.Add('العربية')
$lang.SelectedIndex = 0
$lang.Width = 180
$lang.Location = New-Object Drawing.Point(18,570)
$side.Controls.Add($lang)

$footer = New-Object Windows.Forms.Label
$footer.Text = 'No background service'
$footer.ForeColor = $colors.Muted
$footer.AutoSize = $true
$footer.Location = New-Object Drawing.Point(18,620)
$side.Controls.Add($footer)

$pages = @{}

function New-Page([string]$Name) {
    $p = New-Object Windows.Forms.Panel
    $p.Dock = 'Fill'
    $p.BackColor = $colors.Bg
    $p.Visible = $false
    [void]$main.Controls.Add($p)
    $pages[$Name] = $p
    return $p
}

function Show-Page([string]$Name) {
    foreach ($p in $pages.Values) { $p.Visible = $false }
    $pages[$Name].Visible = $true
}

function Add-Header($Panel,[string]$En,[string]$Ar,[string]$SubEn,[string]$SubAr) {
    $h = New-Object Windows.Forms.Label
    $h.Text = L $En $Ar
    $h.Font = New-Object Drawing.Font('Segoe UI Semibold',22)
    $h.ForeColor = $colors.Text
    $h.AutoSize = $true
    $h.Location = New-Object Drawing.Point(28,24)
    $Panel.Controls.Add($h)

    $s = New-Object Windows.Forms.Label
    $s.Text = L $SubEn $SubAr
    $s.ForeColor = $colors.Muted
    $s.AutoSize = $true
    $s.Location = New-Object Drawing.Point(30,68)
    $Panel.Controls.Add($s)
}

$pHome = New-Page 'Home'
$pScan = New-Page 'Scan'
$pOpt  = New-Page 'Opt'
$pApps = New-Page 'Apps'
$pRes  = New-Page 'Results'

Add-Header $pHome 'Welcome' 'مرحبًا' 'Lightweight setup for new Windows 11 PCs or post-format systems.' 'أداة خفيفة للأجهزة الجديدة أو بعد الفورمات.'

$homeInfo = New-Object Windows.Forms.Label
$homeInfo.Text = L @'
No backup is created.
Personal files are not deleted.
Camera and microphone permissions are untouched.
Snipping Tool and Xbox stay installed.
Hyper-V, thumbnails and ClearType are untouched.
Unallocated disks are detected only and NEVER formatted automatically.
'@ @'
لا يتم إنشاء Backup.
لا يتم حذف ملفاتك الشخصية.
صلاحيات الكاميرا والمايك لا يتم تعديلها.
Snipping Tool وXbox يبقيان مثبتين.
Hyper-V وThumbnails وClearType لا يتم تعديلها.
الأقراص غير المخصصة يتم اكتشافها فقط ولا تتم تهيئتها تلقائيًا.
'@
$homeInfo.ForeColor = $colors.Text
$homeInfo.Font = New-Object Drawing.Font('Segoe UI',11)
$homeInfo.Location = New-Object Drawing.Point(30,125)
$homeInfo.Size = New-Object Drawing.Size(800,230)
$pHome.Controls.Add($homeInfo)

$start = New-Object Windows.Forms.Button
$start.Text = L 'Start Device Scan' 'بدء فحص الجهاز'
$start.Size = New-Object Drawing.Size(190,45)
$start.Location = New-Object Drawing.Point(30,380)
$start.BackColor = $colors.Blue
$start.ForeColor = [Drawing.Color]::White
$start.FlatStyle = 'Flat'
$pHome.Controls.Add($start)

Add-Header $pScan 'Device Scan' 'فحص الجهاز' 'Hardware, GPU, BIOS and storage information.' 'معلومات الجهاز وكرت الشاشة والبايوس والتخزين.'

$scanBox = New-Object Windows.Forms.TextBox
$scanBox.Multiline = $true
$scanBox.ScrollBars = 'Vertical'
$scanBox.ReadOnly = $true
$scanBox.Font = New-Object Drawing.Font('Consolas',10)
$scanBox.Location = New-Object Drawing.Point(28,105)
$scanBox.Size = New-Object Drawing.Size(800,430)
$scanBox.BackColor = $colors.Panel
$scanBox.ForeColor = $colors.Text
$pScan.Controls.Add($scanBox)

$again = New-Object Windows.Forms.Button
$again.Text = L 'Rescan' 'إعادة الفحص'
$again.Size = New-Object Drawing.Size(140,40)
$again.Location = New-Object Drawing.Point(28,555)
$again.BackColor = $colors.Panel2
$again.ForeColor = $colors.Text
$again.FlatStyle = 'Flat'
$pScan.Controls.Add($again)

Add-Header $pOpt 'Optimization' 'تحسين النظام' 'Select only the changes you want.' 'اختر فقط التعديلات التي تريدها.'

$optPanel = New-Object Windows.Forms.FlowLayoutPanel
$optPanel.Location = New-Object Drawing.Point(28,105)
$optPanel.Size = New-Object Drawing.Size(800,420)
$optPanel.AutoScroll = $true
$optPanel.FlowDirection = 'TopDown'
$optPanel.WrapContents = $false
$optPanel.BackColor = $colors.Bg
$pOpt.Controls.Add($optPanel)

$optChecks = @{}
foreach ($o in $Options) {
    $c = New-Object Windows.Forms.CheckBox
    $c.Text = L $o.En $o.Ar
    $c.Tag = $o
    $c.Width = 760
    $c.Height = 35
    $c.ForeColor = $colors.Text
    $c.BackColor = $colors.Panel
    $optPanel.Controls.Add($c)
    $optChecks[$o.Key] = $c
}

$apply = New-Object Windows.Forms.Button
$apply.Text = L 'Review & Apply' 'مراجعة وتطبيق'
$apply.Size = New-Object Drawing.Size(180,42)
$apply.Location = New-Object Drawing.Point(28,550)
$apply.BackColor = $colors.Blue
$apply.ForeColor = [Drawing.Color]::White
$apply.FlatStyle = 'Flat'
$pOpt.Controls.Add($apply)

Add-Header $pApps 'Optional Apps' 'التطبيقات الاختيارية' 'Choose apps to install with WinGet.' 'اختر التطبيقات التي تريد تثبيتها باستخدام WinGet.'

$gpuLabel = New-Object Windows.Forms.Label
$gpuName = if ($gpu) { $gpu.Name } else { 'Not detected' }
$gpuLabel.Text = L "Detected GPU: $gpuName" "كرت الشاشة المكتشف: $gpuName"
$gpuLabel.ForeColor = $colors.Green
$gpuLabel.AutoSize = $true
$gpuLabel.Location = New-Object Drawing.Point(30,105)
$pApps.Controls.Add($gpuLabel)

$appPanel = New-Object Windows.Forms.FlowLayoutPanel
$appPanel.Location = New-Object Drawing.Point(28,140)
$appPanel.Size = New-Object Drawing.Size(800,350)
$appPanel.AutoScroll = $true
$appPanel.FlowDirection = 'TopDown'
$appPanel.WrapContents = $false
$appPanel.BackColor = $colors.Bg
$pApps.Controls.Add($appPanel)

$appChecks = @{}
foreach ($a in $Apps) {
    $c = New-Object Windows.Forms.CheckBox
    $c.Text = $a.Name
    $c.Tag = $a
    $c.Width = 760
    $c.Height = 38
    $c.ForeColor = $colors.Text
    $c.BackColor = $colors.Panel
    $appPanel.Controls.Add($c)
    $appChecks[$a.Name] = $c
}

$install = New-Object Windows.Forms.Button
$install.Text = L 'Review & Install' 'مراجعة وتثبيت'
$install.Size = New-Object Drawing.Size(180,42)
$install.Location = New-Object Drawing.Point(28,510)
$install.BackColor = $colors.Blue
$install.ForeColor = [Drawing.Color]::White
$install.FlatStyle = 'Flat'
$pApps.Controls.Add($install)

$wu = New-Object Windows.Forms.Button
$wu.Text = L 'Check Windows Update' 'فحص تحديثات Windows'
$wu.Size = New-Object Drawing.Size(190,42)
$wu.Location = New-Object Drawing.Point(225,510)
$wu.BackColor = $colors.Panel2
$wu.ForeColor = $colors.Text
$wu.FlatStyle = 'Flat'
$pApps.Controls.Add($wu)

$drivers = New-Object Windows.Forms.Button
$drivers.Text = L 'Check Hardware Drivers' 'فحص التعريفات'
$drivers.Size = New-Object Drawing.Size(180,42)
$drivers.Location = New-Object Drawing.Point(430,510)
$drivers.BackColor = $colors.Panel2
$drivers.ForeColor = $colors.Text
$drivers.FlatStyle = 'Flat'
$pApps.Controls.Add($drivers)

Add-Header $pRes 'Results' 'النتائج' 'Applied, skipped and error items.' 'ما تم تطبيقه أو تخطيه أو فشل فيه.'

$grid = New-Object Windows.Forms.DataGridView
$grid.Location = New-Object Drawing.Point(28,105)
$grid.Size = New-Object Drawing.Size(800,430)
$grid.ReadOnly = $true
$grid.AllowUserToAddRows = $false
$grid.AutoSizeColumnsMode = 'Fill'
$grid.BackgroundColor = $colors.Panel
$grid.RowHeadersVisible = $false
$pRes.Controls.Add($grid)

$save = New-Object Windows.Forms.Button
$save.Text = L 'Save Report' 'حفظ التقرير'
$save.Size = New-Object Drawing.Size(150,42)
$save.Location = New-Object Drawing.Point(28,555)
$save.BackColor = $colors.Panel2
$save.ForeColor = $colors.Text
$save.FlatStyle = 'Flat'
$pRes.Controls.Add($save)

function Refresh-Results {
    $grid.DataSource = $null
    $grid.DataSource = @($script:Results)
}

function Confirm-Action([string]$Title,[string]$Message) {
    $r = [Windows.Forms.MessageBox]::Show(
        $Message,
        $Title,
        [Windows.Forms.MessageBoxButtons]::YesNo,
        [Windows.Forms.MessageBoxIcon]::Warning
    )
    return ($r -eq [Windows.Forms.DialogResult]::Yes)
}

$homeBtn.Add_Click({ Show-Page 'Home' })
$scanBtn.Add_Click({ Show-Page 'Scan'; $scanBox.Text = Scan-Device })
$optBtn.Add_Click({ Show-Page 'Opt' })
$appBtn.Add_Click({ Show-Page 'Apps' })
$resBtn.Add_Click({ Show-Page 'Results'; Refresh-Results })

$start.Add_Click({
    Show-Page 'Scan'
    $scanBox.Text = Scan-Device
})

$again.Add_Click({
    $scanBox.Text = Scan-Device
})

$apply.Add_Click({
    $selected = @($Options | Where-Object { $optChecks[$_.Key].Checked })

    if ($selected.Count -eq 0) {
        [Windows.Forms.MessageBox]::Show(
            (L 'Select at least one optimization.' 'حدد تعديلًا واحدًا على الأقل.')
        ) | Out-Null
        return
    }

    $list = ($selected | ForEach-Object { '• ' + (L $_.En $_.Ar) }) -join "`r`n"
    $msg = L `
        ("The following changes will be applied:`r`n`r`n$list`r`n`r`nContinue?") `
        ("سيتم تطبيق التعديلات التالية:`r`n`r`n$list`r`n`r`nهل تريد المتابعة؟")

    if (Confirm-Action (L 'Confirm changes' 'تأكيد التعديلات') $msg) {
        foreach ($o in $selected) {
            Run-Safe (L $o.En $o.Ar) $o.Action
        }

        try {
            Stop-Process explorer -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 700
            Start-Process explorer.exe
        }
        catch {}

        Refresh-Results
    }
})

$install.Add_Click({
    $selectedApps = @(
        $appChecks.Values |
        Where-Object { $_.Checked } |
        ForEach-Object { $_.Tag }
    )

    if ($selectedApps.Count -eq 0) {
        [Windows.Forms.MessageBox]::Show(
            (L 'Select at least one app.' 'حدد تطبيقًا واحدًا على الأقل.')
        ) | Out-Null
        return
    }

    $list = ($selectedApps | ForEach-Object { '• ' + $_.Name }) -join "`r`n"
    $msg = L `
        ("WinGet will install:`r`n`r`n$list`r`n`r`nContinue?") `
        ("سيتم تثبيت:`r`n`r`n$list`r`n`r`nهل تريد المتابعة؟")

    if (Confirm-Action (L 'Confirm installation' 'تأكيد التثبيت') $msg) {
        foreach ($a in $selectedApps) {
            try {
                if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
                    throw 'WinGet is not available'
                }

                $p = Start-Process winget.exe `
                    -ArgumentList @(
                        'install','--id',$a.Id,'--exact',
                        '--accept-source-agreements',
                        '--accept-package-agreements'
                    ) `
                    -Wait -PassThru -WindowStyle Hidden

                if ($p.ExitCode -eq 0) {
                    Add-Result 'Apps' $a.Name 'SUCCESS'
                }
                else {
                    Add-Result 'Apps' $a.Name 'ERROR' "WinGet exit code $($p.ExitCode)"
                }
            }
            catch {
                Add-Result 'Apps' $a.Name 'ERROR' $_.Exception.Message
            }
        }
        Refresh-Results
    }
})

$wu.Add_Click({
    try {
        if (Get-Command usoclient.exe -ErrorAction SilentlyContinue) {
            Start-Process usoclient.exe -ArgumentList 'StartScan' -WindowStyle Hidden
            Add-Result 'Windows Update' 'Update scan requested' 'SUCCESS'
        }
        else {
            Add-Result 'Windows Update' 'Update scan' 'SKIPPED' 'Update client unavailable'
        }
    }
    catch {
        Add-Result 'Windows Update' 'Update scan' 'ERROR' $_.Exception.Message
    }
    Refresh-Results
})

$drivers.Add_Click({
    try {
        $d = @(
            Get-CimInstance Win32_PnPSignedDriver -ErrorAction Stop |
            Where-Object {
                $_.DeviceName -and $_.DriverVersion
            } |
            Select-Object DeviceName,Manufacturer,DriverVersion,DriverDate
        )

        $text = ($d | Format-Table -AutoSize | Out-String)
        [Windows.Forms.MessageBox]::Show(
            $text,
            (L 'Hardware drivers' 'تعريفات الجهاز')
        ) | Out-Null

        Add-Result 'Drivers' 'Hardware driver inventory' 'SUCCESS'
    }
    catch {
        Add-Result 'Drivers' 'Hardware driver inventory' 'ERROR' $_.Exception.Message
    }
    Refresh-Results
})

$save.Add_Click({
    $dialog = New-Object Windows.Forms.SaveFileDialog
    $dialog.Filter = 'Text files (*.txt)|*.txt'
    $dialog.FileName = "Windows11_Gaming_Optimizer_Report_$(Get-Date -Format yyyyMMdd_HHmmss).txt"

    if ($dialog.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
        @($script:Results) |
            Format-Table -AutoSize |
            Out-String |
            Set-Content -Path $dialog.FileName -Encoding UTF8

        [Windows.Forms.MessageBox]::Show(
            (L 'Report saved.' 'تم حفظ التقرير.')
        ) | Out-Null
    }
})

$lang.Add_SelectedIndexChanged({
    $script:Lang = if ($lang.SelectedIndex -eq 1) { 'ar' } else { 'en' }

    [Windows.Forms.MessageBox]::Show(
        (L 'Restart the program after changing language so all controls use the selected language.' 'أعد تشغيل البرنامج بعد تغيير اللغة حتى تظهر جميع العناصر باللغة المختارة.')
    ) | Out-Null
})

$form.Add_Shown({
    if (-not (Test-Admin)) {
        [Windows.Forms.MessageBox]::Show(
            (L 'Run PowerShell as Administrator for system changes.' 'شغّل PowerShell كمسؤول حتى تعمل تعديلات النظام.')
        ) | Out-Null
    }
})

Show-Page 'Home'
[void]$form.ShowDialog()
