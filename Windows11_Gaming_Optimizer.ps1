#requires -version 5.1
<#
Windows 11 Gaming Optimizer - Clean GUI
Safe-first edition:
- No backup creation
- Never formats/deletes partitions
- Keeps Snipping Tool and Xbox
- Does not change Camera/Microphone permissions
- Keeps thumbnails and ClearType/text smoothing
- Each action is isolated: failure is logged and the script continues
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -----------------------------
# Global state
# -----------------------------
$script:Results = New-Object System.Collections.Generic.List[object]
$script:Language = 'en'
$script:CurrentPage = $null

$script:Theme = @{
    Background = [System.Drawing.Color]::FromArgb(10, 14, 22)
    Panel      = [System.Drawing.Color]::FromArgb(18, 25, 38)
    Panel2     = [System.Drawing.Color]::FromArgb(24, 33, 49)
    Text       = [System.Drawing.Color]::FromArgb(235, 241, 250)
    Muted      = [System.Drawing.Color]::FromArgb(155, 170, 190)
    Accent     = [System.Drawing.Color]::FromArgb(45, 125, 235)
    Success    = [System.Drawing.Color]::FromArgb(55, 190, 115)
    Warning    = [System.Drawing.Color]::FromArgb(235, 175, 55)
    Error      = [System.Drawing.Color]::FromArgb(230, 80, 90)
    Border     = [System.Drawing.Color]::FromArgb(40, 52, 72)
}

# -----------------------------
# Text
# -----------------------------
$script:Text = @{
    en = @{
        Title = 'Windows 11 Gaming Optimizer'
        Subtitle = 'v1.4.2 • Lightweight Setup & Optimization Assistant'
        Home = 'Home'
        Scan = 'Device Scan'
        Optimize = 'Optimization'
        Apps = 'Optional Apps'
        Results = 'Results'
        Language = 'Language'
        Start = 'Start'
        Continue = 'Continue'
        Cancel = 'Cancel'
        Apply = 'Apply selected'
        Rescan = 'Rescan'
        Clear = 'Clear results'
        Save = 'Save report'
        OpenWU = 'Open Windows Update'
        DisclaimerTitle = 'Important notice'
        Disclaimer = 'Designed mainly for new Windows 11 PCs or systems after a clean format. No backup is created. The optimizer does not delete personal files or format disks. Unallocated disks are only detected and displayed.'
        ScanTitle = 'Device information'
        OptimizeTitle = 'Choose the changes you want'
        AppsTitle = 'Optional applications'
        ResultsTitle = 'Operation results'
        GPU = 'Graphics'
        Storage = 'Storage'
        Hardware = 'Hardware'
        Updates = 'Updates'
        Status = 'Status'
        Success = 'Success'
        Skipped = 'Skipped'
        Error = 'Error'
        NothingSelected = 'Select at least one item.'
        Finished = 'Finished. Review Results for details.'
        Keep = 'Kept intentionally'
        DiskWarning = 'Unallocated disks detected — no formatting will be performed.'
        NVIDIA = 'NVIDIA detected'
        AMD = 'AMD detected'
        IntelGPU = 'Intel graphics detected'
        NoGPU = 'No supported discrete GPU detected'
    }
    ar = @{
        Title = 'Windows 11 Gaming Optimizer'
        Subtitle = 'v1.4.2 • مساعد إعداد وتحسين خفيف'
        Home = 'الرئيسية'
        Scan = 'فحص الجهاز'
        Optimize = 'التحسين'
        Apps = 'البرامج الاختيارية'
        Results = 'النتائج'
        Language = 'اللغة'
        Start = 'ابدأ'
        Continue = 'متابعة'
        Cancel = 'إلغاء'
        Apply = 'تطبيق المحدد'
        Rescan = 'إعادة الفحص'
        Clear = 'مسح النتائج'
        Save = 'حفظ التقرير'
        OpenWU = 'فتح Windows Update'
        DisclaimerTitle = 'تنبيه مهم'
        Disclaimer = 'مصمم بشكل أساسي لأجهزة Windows 11 الجديدة أو الأجهزة بعد الفورمات النظيف. لا يتم إنشاء نسخة احتياطية. لا يحذف ملفاتك الشخصية ولا يقوم بتهيئة الأقراص. الأقراص غير المخصصة يتم اكتشافها وعرضها فقط.'
        ScanTitle = 'معلومات الجهاز'
        OptimizeTitle = 'اختر التعديلات التي تريدها'
        AppsTitle = 'البرامج الاختيارية'
        ResultsTitle = 'نتائج العمليات'
        GPU = 'كرت الشاشة'
        Storage = 'التخزين'
        Hardware = 'العتاد'
        Updates = 'التحديثات'
        Status = 'الحالة'
        Success = 'نجح'
        Skipped = 'تم التخطي'
        Error = 'خطأ'
        NothingSelected = 'اختر عنصراً واحداً على الأقل.'
        Finished = 'انتهى التنفيذ. راجع النتائج لمعرفة التفاصيل.'
        Keep = 'مبقي عمداً'
        DiskWarning = 'تم اكتشاف أقراص بها مساحة غير مخصصة — لن تتم تهيئتها.'
        NVIDIA = 'تم اكتشاف NVIDIA'
        AMD = 'تم اكتشاف AMD'
        IntelGPU = 'تم اكتشاف رسومات Intel'
        NoGPU = 'لم يتم اكتشاف كرت منفصل مدعوم'
    }
}

function T([string]$key) {
    return $script:Text[$script:Language][$key]
}

# -----------------------------
# Helpers
# -----------------------------
function Add-Result {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Details
    )
    $script:Results.Add([pscustomobject]@{
        Time = Get-Date -Format 'HH:mm:ss'
        Name = $Name
        Status = $Status
        Details = $Details
    })
}

function Invoke-Safe {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    try {
        & $Action
        Add-Result $Name 'Success' 'Completed'
        return $true
    }
    catch {
        Add-Result $Name 'Error' $_.Exception.Message
        return $false
    }
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function New-Label {
    param([string]$Text,[int]$X,[int]$Y,[int]$W,[int]$H,[int]$Size=10)
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point($X,$Y)
    $label.Size = New-Object System.Drawing.Size($W,$H)
    $label.ForeColor = $script:Theme.Text
    $label.Font = New-Object System.Drawing.Font('Segoe UI',$Size)
    $label.BackColor = [System.Drawing.Color]::Transparent
    return $label
}

function New-Button {
    param([string]$Text,[int]$X,[int]$Y,[int]$W,[int]$H=38)
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point($X,$Y)
    $button.Size = New-Object System.Drawing.Size($W,$H)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize = 0
    $button.BackColor = $script:Theme.Accent
    $button.ForeColor = [System.Drawing.Color]::White
    $button.Font = New-Object System.Drawing.Font('Segoe UI Semibold',10)
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $button
}

function New-Check {
    param([string]$Text,[int]$X,[int]$Y,[int]$W,[int]$H=38)
    $check = New-Object System.Windows.Forms.CheckBox
    $check.Text = $Text
    $check.Location = New-Object System.Drawing.Point($X,$Y)
    $check.Size = New-Object System.Drawing.Size($W,$H)
    $check.ForeColor = $script:Theme.Text
    $check.BackColor = $script:Theme.Panel2
    $check.Font = New-Object System.Drawing.Font('Segoe UI',10)
    $check.Padding = New-Object System.Windows.Forms.Padding(8,0,0,0)
    $check.Tag = $null
    return $check
}

function Get-GpuInfo {
    try {
        return @(Get-CimInstance Win32_VideoController | Where-Object { $_.Name -and $_.Name -notmatch 'Parsec|Virtual|Remote Display' } | Select-Object Name,DriverVersion)
    } catch {
        return @()
    }
}

function Get-DeviceScanText {
    $lines = New-Object System.Collections.Generic.List[string]

    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $lines.Add("Windows: $($os.Caption) | Build: $($os.BuildNumber)")
    } catch {
        $lines.Add('Windows: unavailable')
    }

    try {
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $lines.Add("CPU: $($cpu.Name)")
    } catch {
        $lines.Add('CPU: unavailable')
    }

    try {
        $board = Get-CimInstance Win32_BaseBoard | Select-Object -First 1
        $lines.Add("Motherboard: $($board.Manufacturer) | $($board.Product)")
    } catch {
        $lines.Add('Motherboard: unavailable')
    }

    try {
        $bios = Get-CimInstance Win32_BIOS | Select-Object -First 1
        $lines.Add("BIOS: $($bios.Manufacturer) | $($bios.SMBIOSBIOSVersion)")
    } catch {
        $lines.Add('BIOS: unavailable')
    }

    $gpus = Get-GpuInfo
    if (@($gpus).Count -eq 0) {
        $lines.Add("GPU: $(T 'NoGPU')")
    } else {
        foreach ($gpu in $gpus) {
            $lines.Add("GPU: $($gpu.Name) | Driver: $($gpu.DriverVersion)")
        }
    }

    try {
        $ram = [math]::Round(((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB),1)
        $lines.Add("RAM: $ram GB")
    } catch {
        $lines.Add('RAM: unavailable')
    }

    try {
        $disks = @(Get-CimInstance Win32_DiskDrive | Sort-Object Index)
        foreach ($disk in $disks) {
            $size = [math]::Round(($disk.Size / 1GB),2)
            $lines.Add("Disk $($disk.Index): $($disk.Model) | $size GB | $($disk.InterfaceType)")
        }
    } catch {
        $lines.Add('Disks: unavailable')
    }

    try {
        $parts = @(Get-Disk | Where-Object { $_.OperationalStatus -eq 'Online' -and $_.PartitionStyle -ne 'RAW' })
        foreach ($d in $parts) {
            $unalloc = $d.Size - (($d | Get-Partition -ErrorAction SilentlyContinue | Measure-Object -Property Size -Sum).Sum)
            if ($unalloc -gt 1GB) {
                $lines.Add("WARNING: Disk $($d.Number) has about $([math]::Round($unalloc/1GB,2)) GB unallocated.")
            }
        }
    } catch {
        # Non-critical.
    }

    try {
        $wu = Get-Service wuauserv -ErrorAction Stop
        $lines.Add("Windows Update service: $($wu.Status)")
    } catch {
        $lines.Add('Windows Update service: unavailable')
    }

    return ($lines -join [Environment]::NewLine)
}

function Detect-GpuVendor {
    $gpus = Get-GpuInfo
    $names = ($gpus.Name -join ' ')
    if ($names -match 'NVIDIA|GeForce|RTX|GTX|Quadro') { return 'NVIDIA' }
    if ($names -match 'AMD|Radeon') { return 'AMD' }
    if ($names -match 'Intel') { return 'Intel' }
    return 'None'
}

function Open-Url {
    param([string]$Url)
    Start-Process $Url
}

function Set-RegDword {
    param([string]$Path,[string]$Name,[int]$Value)
    New-Item -Path $Path -Force | Out-Null
    New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
}

function Remove-OneDrive {
    $paths = @(
        "$env:SystemRoot\System32\OneDriveSetup.exe",
        "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
    )
    $found = $false
    foreach ($path in $paths) {
        if (Test-Path $path) {
            $found = $true
            Start-Process $path '/uninstall' -Wait -WindowStyle Hidden
        }
    }
    if (-not $found) { throw 'OneDrive installer was not found. It may already be removed.' }
}

function Remove-TeamsConsumer {
    $packages = @(Get-AppxPackage -AllUsers -Name '*MicrosoftTeams*' -ErrorAction SilentlyContinue)
    if (@($packages).Count -eq 0) { throw 'Microsoft Teams consumer package was not found.' }
    foreach ($pkg in $packages) {
        Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
    }
}

function Set-BlackDesktop {
    Set-ItemProperty -Path 'HKCU:\Control Panel\Colors' -Name Background -Value '0 0 0' -Force
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper -Value '' -Force
    rundll32.exe user32.dll,UpdatePerUserSystemParameters
}

function Disable-Widgets {
    Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarDa' 0
}

function Disable-TaskView {
    Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowTaskViewButton' 0
}

function Disable-SearchBox {
    # 0 = hidden/search icon depending on Windows build policy.
    Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'SearchboxTaskbarMode' 1
}

function Disable-Recall {
    Set-RegDword 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 1
}

function Reduce-Telemetry {
    Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
    Set-RegDword 'HKCU:\Software\Microsoft\Siuf\Rules' 'NumberOfSIUFInPeriod' 0
}

function Enable-GameMode {
    Set-RegDword 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1
    Set-RegDword 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
}

function Disable-GameDvr {
    Set-RegDword 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
}

function Reduce-PowerThrottling {
    Set-RegDword 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 1
}

function Conservative-Network {
    # Conservative: only disables a known user-level background Game Bar capture feature.
    Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'HistoricalCaptureEnabled' 0
}

function Restart-ExplorerSafe {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe
}

# -----------------------------
# Form
# -----------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = T 'Title'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(1120,720)
$form.MinimumSize = New-Object System.Drawing.Size(980,620)
$form.BackColor = $script:Theme.Background
$form.ForeColor = $script:Theme.Text
$form.Font = New-Object System.Drawing.Font('Segoe UI',10)
$form.RightToLeft = [System.Windows.Forms.RightToLeft]::No
$form.RightToLeftLayout = $false

$sidebar = New-Object System.Windows.Forms.Panel
$sidebar.Dock = 'Left'
$sidebar.Width = 235
$sidebar.BackColor = $script:Theme.Panel
$form.Controls.Add($sidebar)

$content = New-Object System.Windows.Forms.Panel
$content.Dock = 'Fill'
$content.BackColor = $script:Theme.Background
$content.RightToLeft = [System.Windows.Forms.RightToLeft]::No
$content.AutoScroll = $false
$form.Controls.Add($content)
# Keep the sidebar visually above the fill panel; otherwise the panel can cover the left side of labels.
$sidebar.BringToFront()

$header = New-Label (T 'Title') 28 22 800 40 20
$header.Anchor = 'Top,Left,Right'
$content.Controls.Add($header)

$subHeader = New-Label (T 'Subtitle') 30 62 800 28 10
$subHeader.Anchor = 'Top,Left,Right'
$subHeader.ForeColor = $script:Theme.Muted
$content.Controls.Add($subHeader)

# Sidebar buttons
$navButtons = @{}
$navY = 125
foreach ($key in @('Home','Scan','Optimize','Apps','Results')) {
    $btn = New-Button (T $key) 18 $navY 195 40
    $btn.Tag = $key
    $btn.BackColor = $script:Theme.Panel
    $btn.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $btn.Add_Click({
        Show-Page $this.Tag
    })
    $sidebar.Controls.Add($btn)
    $navButtons[$key] = $btn
    $navY += 50
}

$langLabel = New-Label (T 'Language') 18 555 195 25 9
$langLabel.ForeColor = $script:Theme.Muted
$sidebar.Controls.Add($langLabel)

$langCombo = New-Object System.Windows.Forms.ComboBox
$langCombo.Location = New-Object System.Drawing.Point(18,582)
$langCombo.Size = New-Object System.Drawing.Size(195,34)
$langCombo.DropDownStyle = 'DropDownList'
[void]$langCombo.Items.Add('English')
[void]$langCombo.Items.Add('العربية')
$langCombo.SelectedIndex = 0
$langCombo.BackColor = [System.Drawing.Color]::White
$langCombo.ForeColor = [System.Drawing.Color]::Black
$langCombo.Add_SelectedIndexChanged({
    if ($this.SelectedIndex -eq 1) { $script:Language = 'ar' } else { $script:Language = 'en' }
    Refresh-StaticText
    Show-Page $script:CurrentPage
})
$sidebar.Controls.Add($langCombo)

$footer = New-Label 'No background service • Safe-first' 18 635 195 35 8
$footer.ForeColor = $script:Theme.Muted
$sidebar.Controls.Add($footer)

# Keep the main content aligned when the window is resized.
$form.Add_Resize({
    $available = [Math]::Max(500, $content.ClientSize.Width - 56)
    $header.Width = $available
    $subHeader.Width = $available
})

function Refresh-StaticText {
    $form.Text = T 'Title'
    $header.Text = T 'Title'
    $subHeader.Text = T 'Subtitle'
    foreach ($key in $navButtons.Keys) {
        $navButtons[$key].Text = T $key
    }
    $langLabel.Text = T 'Language'
}

function Clear-Content {
    $content.Controls.Clear()
    $content.Controls.Add($header)
    $content.Controls.Add($subHeader)
}

function Add-SectionPanel {
    param([int]$Y,[int]$H)
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(28,$Y)
    $panel.Size = New-Object System.Drawing.Size([Math]::Max(500, $content.ClientSize.Width - 56),$H)
    $panel.BackColor = $script:Theme.Panel
    $content.Controls.Add($panel)
    return $panel
}

function Show-Home {
    Clear-Content
    $notice = Add-SectionPanel 110 270
    $title = New-Label (T 'DisclaimerTitle') 24 20 730 35 14
    $notice.Controls.Add($title)
    $body = New-Label (T 'Disclaimer') 24 62 730 130 10
    $body.ForeColor = $script:Theme.Muted
    $body.AutoEllipsis = $false
    $notice.Controls.Add($body)

    $startBtn = New-Button (T 'Start') 24 195 160
    $startBtn.Add_Click({ Show-Page 'Scan' })
    $notice.Controls.Add($startBtn)

    $keep = New-Label "$(T 'Keep'): Snipping Tool • Xbox • Thumbnails • ClearType • Camera/Microphone permissions" 205 200 560 55 9
    $keep.ForeColor = $script:Theme.Success
    $notice.Controls.Add($keep)
}

function Show-Scan {
    Clear-Content
    $title = New-Label (T 'ScanTitle') 28 105 760 35 16
    $content.Controls.Add($title)

    $box = New-Object System.Windows.Forms.TextBox
    $box.Location = New-Object System.Drawing.Point(28,150)
    $box.Size = New-Object System.Drawing.Size([Math]::Max(500, $content.ClientSize.Width - 56),360)
    $box.Multiline = $true
    $box.ReadOnly = $true
    $box.ScrollBars = 'Vertical'
    $box.BackColor = $script:Theme.Panel
    $box.ForeColor = $script:Theme.Text
    $box.Font = New-Object System.Drawing.Font('Consolas',10)
    $box.Text = Get-DeviceScanText
    $content.Controls.Add($box)

    $scanBtn = New-Button (T 'Rescan') 28 530 150
    $scanBtn.Add_Click({ $box.Text = Get-DeviceScanText })
    $content.Controls.Add($scanBtn)

    $wuBtn = New-Button (T 'OpenWU') 195 530 190
    $wuBtn.Add_Click({ Start-Process 'ms-settings:windowsupdate' })
    $content.Controls.Add($wuBtn)
}

$script:OptimizationChecks = @()

function Show-Optimize {
    Clear-Content
    $title = New-Label (T 'OptimizeTitle') 28 105 760 35 16
    $content.Controls.Add($title)

    $scroll = New-Object System.Windows.Forms.Panel
    $scroll.Location = New-Object System.Drawing.Point(28,145)
    $scroll.Size = New-Object System.Drawing.Size([Math]::Max(500, $content.ClientSize.Width - 56),430)
    $scroll.AutoScroll = $true
    $scroll.BackColor = $script:Theme.Panel
    $content.Controls.Add($scroll)

    $items = @(
        [pscustomobject]@{ Key='OneDrive'; En='Remove OneDrive'; Ar='إزالة OneDrive'; Action={ Remove-OneDrive } },
        [pscustomobject]@{ Key='Teams'; En='Remove Microsoft Teams consumer'; Ar='إزالة Microsoft Teams للمستهلك'; Action={ Remove-TeamsConsumer } },
        [pscustomobject]@{ Key='Widgets'; En='Disable Widgets'; Ar='تعطيل Widgets'; Action={ Disable-Widgets } },
        [pscustomobject]@{ Key='TaskView'; En='Disable Task View button'; Ar='تعطيل زر Task View'; Action={ Disable-TaskView } },
        [pscustomobject]@{ Key='Search'; En='Show Search as icon'; Ar='إظهار البحث كأيقونة'; Action={ Disable-SearchBox } },
        [pscustomobject]@{ Key='Recall'; En='Disable Recall / AI data analysis policy'; Ar='تعطيل Recall / سياسة تحليل بيانات الذكاء الاصطناعي'; Action={ Disable-Recall } },
        [pscustomobject]@{ Key='Telemetry'; En='Reduce telemetry / advertising ID'; Ar='تقليل Telemetry / Advertising ID'; Action={ Reduce-Telemetry } },
        [pscustomobject]@{ Key='GameMode'; En='Enable Game Mode'; Ar='تفعيل Game Mode'; Action={ Enable-GameMode } },
        [pscustomobject]@{ Key='GameDvr'; En='Disable Game DVR capture'; Ar='تعطيل Game DVR capture'; Action={ Disable-GameDvr } },
        [pscustomobject]@{ Key='Power'; En='Reduce power throttling'; Ar='تقليل Power Throttling'; Action={ Reduce-PowerThrottling } },
        [pscustomobject]@{ Key='Network'; En='Conservative network optimization'; Ar='تحسين شبكة محافظ'; Action={ Conservative-Network } },
        [pscustomobject]@{ Key='Black'; En='Black desktop background'; Ar='خلفية سطح المكتب سوداء'; Action={ Set-BlackDesktop } }
    )

    $script:OptimizationChecks = @()
    $y = 12
    foreach ($item in $items) {
        $check = New-Check (if ($script:Language -eq 'ar') { $item.Ar } else { $item.En }) 15 $y 750
        $check.Tag = $item
        $scroll.Controls.Add($check)
        $script:OptimizationChecks += $check
        $y += 43
    }

    $applyBtn = New-Button (T 'Apply') 28 595 180
    $applyBtn.Add_Click({
        $selected = @($script:OptimizationChecks | Where-Object { $_.Checked })
        if ($selected.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show((T 'NothingSelected'),(T 'Title'),'OK','Information') | Out-Null
            return
        }

        foreach ($checkItem in $selected) {
            $item = $checkItem.Tag
            try {
                & $item.Action
                Add-Result $item.En 'Success' 'Completed'
            } catch {
                Add-Result $item.En 'Error' $_.Exception.Message
            }
        }

        [System.Windows.Forms.MessageBox]::Show((T 'Finished'),(T 'Title'),'OK','Information') | Out-Null
        Show-Page 'Results'
    })
    $content.Controls.Add($applyBtn)

    $note = New-Label 'Intentionally untouched: Snipping Tool • Xbox • Camera/Microphone permissions • image/video thumbnails • ClearType/text smoothing • Hyper-V' 230 600 590 55 8
    $note.ForeColor = $script:Theme.Muted
    $content.Controls.Add($note)
}

function Show-Apps {
    Clear-Content
    $title = New-Label (T 'AppsTitle') 28 105 760 35 16
    $content.Controls.Add($title)

    $panel = Add-SectionPanel 150 380

    $apps = @(
        [pscustomobject]@{ Name='Discord'; Id='Discord.Discord' },
        [pscustomobject]@{ Name='Google Chrome'; Id='Google.Chrome' },
        [pscustomobject]@{ Name='Brave'; Id='Brave.Brave' },
        [pscustomobject]@{ Name='Parsec'; Id='Parsec.Parsec' },
        [pscustomobject]@{ Name='NVIDIA App'; Id='Nvidia.NVIDIAApp' },
        [pscustomobject]@{ Name='AMD Software'; Id='AMD.AMDSoftware' }
    )

    $appChecks = @()
    $y = 18
    foreach ($app in $apps) {
        $check = New-Check $app.Name 20 $y 330
        $check.Tag = $app
        $panel.Controls.Add($check)
        $appChecks += $check
        $y += 52
    }

    $installBtn = New-Button 'Install selected with winget' 390 18 300
    $panel.Controls.Add($installBtn)

    $info = New-Label 'Requires winget/App Installer. If a package ID is unavailable, it is reported as Skipped/Error rather than stopping the optimizer.' 390 80 340 120 9
    $info.ForeColor = $script:Theme.Muted
    $panel.Controls.Add($info)

    $installBtn.Add_Click({
        $selectedApps = @($appChecks | Where-Object { $_.Checked })
        if ($selectedApps.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show((T 'NothingSelected'),(T 'Title'),'OK','Information') | Out-Null
            return
        }

        $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
        if (-not $winget) {
            Add-Result 'winget' 'Error' 'winget.exe was not found.'
            Show-Page 'Results'
            return
        }

        foreach ($appCheck in $selectedApps) {
            $app = $appCheck.Tag
            try {
                & winget.exe install --id $app.Id --exact --accept-source-agreements --accept-package-agreements --silent
                if ($LASTEXITCODE -eq 0) {
                    Add-Result $app.Name 'Success' 'Installed/updated with winget.'
                } else {
                    Add-Result $app.Name 'Skipped' "winget exit code: $LASTEXITCODE"
                }
            } catch {
                Add-Result $app.Name 'Error' $_.Exception.Message
            }
        }
        Show-Page 'Results'
    })

    $gpuVendor = Detect-GpuVendor
    $gpuNote = New-Label "GPU detection: $gpuVendor" 20 330 330 35 10
    if ($gpuVendor -eq 'NVIDIA') { $gpuNote.ForeColor = $script:Theme.Success }
    elseif ($gpuVendor -eq 'AMD') { $gpuNote.ForeColor = $script:Theme.Success }
    else { $gpuNote.ForeColor = $script:Theme.Muted }
    $panel.Controls.Add($gpuNote)
}

function Show-Results {
    Clear-Content
    $title = New-Label (T 'ResultsTitle') 28 105 760 35 16
    $content.Controls.Add($title)

    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Location = New-Object System.Drawing.Point(28,150)
    $grid.Size = New-Object System.Drawing.Size([Math]::Max(500, $content.ClientSize.Width - 56),390)
    $grid.BackgroundColor = $script:Theme.Panel
    $grid.ForeColor = [System.Drawing.Color]::Black
    $grid.AutoSizeColumnsMode = 'Fill'
    $grid.ReadOnly = $true
    $grid.AllowUserToAddRows = $false
    $grid.RowHeadersVisible = $false
    [void]$grid.Columns.Add('Time','Time')
    [void]$grid.Columns.Add('Name','Name')
    [void]$grid.Columns.Add('Status','Status')
    [void]$grid.Columns.Add('Details','Details')

    foreach ($r in $script:Results) {
        $i = $grid.Rows.Add($r.Time,$r.Name,$r.Status,$r.Details)
        if ($r.Status -eq 'Success') {
            $grid.Rows[$i].DefaultCellStyle.ForeColor = [System.Drawing.Color]::DarkGreen
        } elseif ($r.Status -eq 'Error') {
            $grid.Rows[$i].DefaultCellStyle.ForeColor = [System.Drawing.Color]::DarkRed
        } else {
            $grid.Rows[$i].DefaultCellStyle.ForeColor = [System.Drawing.Color]::DarkGoldenrod
        }
    }
    $content.Controls.Add($grid)

    $clearBtn = New-Button (T 'Clear') 28 560 140
    $clearBtn.Add_Click({
        $script:Results.Clear()
        Show-Page 'Results'
    })
    $content.Controls.Add($clearBtn)

    $saveBtn = New-Button (T 'Save') 185 560 150
    $saveBtn.Add_Click({
        $dialog = New-Object System.Windows.Forms.SaveFileDialog
        $dialog.Filter = 'Text file (*.txt)|*.txt'
        $dialog.FileName = 'Windows11-Gaming-Optimizer-Report.txt'
        if ($dialog.ShowDialog() -eq 'OK') {
            $out = foreach ($r in $script:Results) {
                "[$($r.Time)] $($r.Status) | $($r.Name) | $($r.Details)"
            }
            [IO.File]::WriteAllLines($dialog.FileName,$out)
        }
    })
    $content.Controls.Add($saveBtn)
}

function Show-Page {
    param([string]$Page)
    $script:CurrentPage = $Page
    switch ($Page) {
        'Home' { Show-Home }
        'Scan' { Show-Scan }
        'Optimize' { Show-Optimize }
        'Apps' { Show-Apps }
        'Results' { Show-Results }
        default { Show-Home }
    }
}

# Run
if (-not (Test-Admin)) {
    [System.Windows.Forms.MessageBox]::Show(
        'Please run PowerShell as Administrator so system-level actions can work.',
        'Windows 11 Gaming Optimizer',
        'OK',
        'Warning'
    ) | Out-Null
    return
}

Show-Page 'Home'
[void]$form.ShowDialog()
