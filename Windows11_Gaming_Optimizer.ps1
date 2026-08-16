# Windows 11 Gaming Optimizer - Clean UI v1.4
# PowerShell 5.1+ | WinForms | No background service
# Safe-first: no backup is created, no disks are formatted automatically.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# -----------------------------
# Theme
# -----------------------------
$BG       = [System.Drawing.Color]::FromArgb(9,14,22)
$SIDEBAR  = [System.Drawing.Color]::FromArgb(18,27,41)
$CARD      = [System.Drawing.Color]::FromArgb(19,29,43)
$TEXT      = [System.Drawing.Color]::FromArgb(235,240,248)
$MUTED     = [System.Drawing.Color]::FromArgb(155,174,198)
$ACCENT    = [System.Drawing.Color]::FromArgb(45,126,224)
$GOOD      = [System.Drawing.Color]::FromArgb(50,205,130)
$WARN      = [System.Drawing.Color]::FromArgb(245,180,70)
$BAD       = [System.Drawing.Color]::FromArgb(235,90,90)

$font = New-Object System.Drawing.Font("Segoe UI", 10)
$fontTitle = New-Object System.Drawing.Font("Segoe UI Semibold", 22)
$fontHead = New-Object System.Drawing.Font("Segoe UI Semibold", 12)
$fontSmall = New-Object System.Drawing.Font("Segoe UI", 9)

# -----------------------------
# Helpers
# -----------------------------
$script:Language = "English"
$script:Results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param(
        [string]$Category,
        [string]$Item,
        [string]$Status,
        [string]$Details
    )
    $script:Results.Add([PSCustomObject]@{
        Category = $Category
        Item     = $Item
        Status   = $Status
        Details  = $Details
    })
}

function Safe {
    param([scriptblock]$Action, [string]$Category, [string]$Item)
    try {
        & $Action
        Add-Result $Category $Item "OK" ""
        return $true
    }
    catch {
        Add-Result $Category $Item "ERROR" $_.Exception.Message
        return $false
    }
}

function Get-Text {
    param([string]$English, [string]$Arabic)
    if ($script:Language -eq "Arabic") { return $Arabic }
    return $English
}

function New-Button {
    param([string]$Text)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderSize = 0
    $b.BackColor = $ACCENT
    $b.ForeColor = [System.Drawing.Color]::White
    $b.Font = $font
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.Height = 38
    return $b
}

function New-SectionLabel {
    param([string]$Text)
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $Text
    $l.ForeColor = $TEXT
    $l.Font = $fontHead
    $l.AutoSize = $true
    return $l
}

# -----------------------------
# Main window
# -----------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows 11 Gaming Optimizer"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(1120,720)
$form.MinimumSize = New-Object System.Drawing.Size(980,620)
$form.BackColor = $BG
$form.ForeColor = $TEXT
$form.Font = $font

# Sidebar - deliberately narrow
$sidebar = New-Object System.Windows.Forms.Panel
$sidebar.Dock = "Left"
$sidebar.Width = 190
$sidebar.BackColor = $SIDEBAR
$form.Controls.Add($sidebar)

# Main content
$content = New-Object System.Windows.Forms.Panel
$content.Dock = "Fill"
$content.BackColor = $BG
$content.Padding = New-Object System.Windows.Forms.Padding(28,22,28,20)
$form.Controls.Add($content)

# Header
$header = New-Object System.Windows.Forms.Panel
$header.Dock = "Top"
$header.Height = 92
$header.BackColor = $BG
$content.Controls.Add($header)

$title = New-Object System.Windows.Forms.Label
$title.Text = "Windows 11 Gaming Optimizer"
$title.ForeColor = $TEXT
$title.Font = $fontTitle
$title.AutoSize = $true
$title.TextAlign = "MiddleCenter"
$title.Anchor = "Top"
$header.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "Setup & Optimization Assistant"
$subtitle.ForeColor = $MUTED
$subtitle.Font = $fontSmall
$subtitle.AutoSize = $true
$header.Controls.Add($subtitle)

function Center-Header {
    if ($title.Width -gt 0) {
        $title.Left = [int](($header.ClientSize.Width - $title.Width) / 2)
        $title.Top = 8
    }
    if ($subtitle.Width -gt 0) {
        $subtitle.Left = [int](($header.ClientSize.Width - $subtitle.Width) / 2)
        $subtitle.Top = 48
    }
}
$header.Add_Resize({ Center-Header })
$form.Add_Shown({ Center-Header })

# Page host
$pageHost = New-Object System.Windows.Forms.Panel
$pageHost.Dock = "Fill"
$pageHost.BackColor = $BG
$content.Controls.Add($pageHost)

# Sidebar branding
$brand = New-Object System.Windows.Forms.Label
$brand.Text = "W11`nOptimizer"
$brand.ForeColor = $TEXT
$brand.Font = New-Object System.Drawing.Font("Segoe UI Semibold",16)
$brand.AutoSize = $true
$brand.Left = 20
$brand.Top = 22
$sidebar.Controls.Add($brand)

$version = New-Object System.Windows.Forms.Label
$version.Text = "v1.4 • Lightweight"
$version.ForeColor = $ACCENT
$version.Font = $fontSmall
$version.AutoSize = $true
$version.Left = 20
$version.Top = 70
$sidebar.Controls.Add($version)

# Sidebar buttons
$navNames = @("Home","Device Scan","Optimization","Optional Apps","Results")
$navButtons = @{}
$navY = 125

foreach ($n in $navNames) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $n
    $b.Tag = $n
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderSize = 0
    $b.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(27,42,62)
    $b.BackColor = $SIDEBAR
    $b.ForeColor = $TEXT
    $b.Font = $font
    $b.TextAlign = "MiddleLeft"
    $b.Left = 10
    $b.Top = $navY
    $b.Width = 170
    $b.Height = 40
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $sidebar.Controls.Add($b)
    $navButtons[$n] = $b
    $navY += 48
}

# Language selector
$langLabel = New-Object System.Windows.Forms.Label
$langLabel.Text = "Language"
$langLabel.ForeColor = $MUTED
$langLabel.Font = $fontSmall
$langLabel.AutoSize = $true
$langLabel.Left = 20
$langLabel.Top = 570
$sidebar.Controls.Add($langLabel)

$langBox = New-Object System.Windows.Forms.ComboBox
$langBox.DropDownStyle = "DropDownList"
$langBox.Items.AddRange(@("English","العربية"))
$langBox.SelectedIndex = 0
$langBox.Left = 18
$langBox.Top = 592
$langBox.Width = 150
$langBox.Height = 30
$sidebar.Controls.Add($langBox)

$safeLabel = New-Object System.Windows.Forms.Label
$safeLabel.Text = "No background service • Safe-first"
$safeLabel.ForeColor = $MUTED
$safeLabel.Font = New-Object System.Drawing.Font("Segoe UI",8)
$safeLabel.AutoSize = $true
$safeLabel.Left = 20
$safeLabel.Top = 638
$sidebar.Controls.Add($safeLabel)

# -----------------------------
# Page helpers
# -----------------------------
function Clear-Page {
    $pageHost.Controls.Clear()
}

function New-Card {
    param([int]$Height = 180)
    $p = New-Object System.Windows.Forms.Panel
    $p.BackColor = $CARD
    $p.Dock = "Top"
    $p.Height = $Height
    $p.Margin = New-Object System.Windows.Forms.Padding(0,0,0,14)
    return $p
}

function New-WrapLabel {
    param(
        [string]$Text,
        [int]$Top = 20,
        [int]$Height = 80,
        [int]$RightPadding = 20
    )
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $Text
    $l.ForeColor = $TEXT
    $l.Font = $font
    $l.Left = 20
    $l.Top = $Top
    $l.Width = $pageHost.ClientSize.Width - 40 - $RightPadding
    $l.Height = $Height
    $l.AutoSize = $false
    $l.MaximumSize = New-Object System.Drawing.Size($l.Width,$Height)
    $l.TextAlign = "TopRight"
    $l.AutoEllipsis = $false
    return $l
}

# -----------------------------
# Home
# -----------------------------
function Show-Home {
    Clear-Page

    $card = New-Card 230
    $pageHost.Controls.Add($card)

    $h = New-SectionLabel (Get-Text "Welcome" "مرحباً")
    $h.Left = 20
    $h.Top = 20
    $card.Controls.Add($h)

    $txt = Get-Text `
        "Designed for new Windows 11 PCs or systems after a clean format. No backup is created. Personal files are not deleted. Unallocated disks are only detected and displayed — never formatted automatically." `
        "مصمم لأجهزة Windows 11 الجديدة أو الأجهزة بعد الفورمات. لا يتم إنشاء Backup. لا يتم حذف ملفاتك الشخصية. الأقراص غير المهيأة يتم اكتشافها وعرضها فقط — ولا يتم عمل Format لها تلقائياً."

    $body = New-WrapLabel $txt 55 95
    $card.Controls.Add($body)

    $kept = New-Object System.Windows.Forms.Label
    $kept.Text = Get-Text "Kept intentionally: Snipping Tool • Xbox • image/video thumbnails • ClearType • Camera/Microphone permissions" "يتم إبقاؤها: Snipping Tool • Xbox • معاينات الصور والفيديو • ClearType • صلاحيات الكاميرا والميكروفون"
    $kept.ForeColor = $GOOD
    $kept.Font = $fontSmall
    $kept.Left = 20
    $kept.Top = 165
    $kept.Width = $pageHost.ClientSize.Width - 40
    $kept.Height = 40
    $kept.TextAlign = "TopRight"
    $card.Controls.Add($kept)

    $start = New-Button (Get-Text "Start Device Scan" "بدء فحص الجهاز")
    $start.Left = 20
    $start.Top = 195
    $start.Width = 180
    $start.Add_Click({ Show-DeviceScan })
    $card.Controls.Add($start)
}

# -----------------------------
# Device Scan
# -----------------------------
function Get-DeviceInfo {
    $info = @()

    Safe {
        $os = Get-CimInstance Win32_OperatingSystem
        $info += "Windows: $($os.Caption) | Build: $($os.BuildNumber)"
    } "Device Scan" "Windows"

    Safe {
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $info += "CPU: $($cpu.Name)"
    } "Device Scan" "CPU"

    Safe {
        $board = Get-CimInstance Win32_BaseBoard | Select-Object -First 1
        $info += "Motherboard: $($board.Manufacturer) | $($board.Product)"
    } "Device Scan" "Motherboard"

    Safe {
        $bios = Get-CimInstance Win32_BIOS | Select-Object -First 1
        $info += "BIOS: $($bios.Manufacturer) | $($bios.SMBIOSBIOSVersion)"
    } "Device Scan" "BIOS"

    Safe {
        $ram = [math]::Round(((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB),1)
        $info += "Memory: $ram GB"
    } "Device Scan" "Memory"

    Safe {
        $gpus = @(Get-CimInstance Win32_VideoController)
        foreach ($g in $gpus) {
            $info += "GPU: $($g.Name) | Driver: $($g.DriverVersion)"
        }
    } "Device Scan" "GPU"

    Safe {
        $disks = @(Get-CimInstance Win32_DiskDrive)
        foreach ($d in $disks) {
            $size = [math]::Round(($d.Size / 1GB),2)
            $info += "Disk: $($d.Index) | $($d.Model) | $size GB | $($d.InterfaceType)"
        }
    } "Device Scan" "Disks"

    Safe {
        $vols = @(Get-CimInstance Win32_Volume -Filter "DriveType=3")
        foreach ($v in $vols) {
            if ($v.DriveLetter) {
                $info += "Volume: $($v.DriveLetter) | $($v.Label) | $([math]::Round($v.Capacity/1GB,2)) GB"
            }
        }
    } "Device Scan" "Volumes"

    return @($info)
}

function Show-DeviceScan {
    Clear-Page

    $card = New-Card 500
    $pageHost.Controls.Add($card)

    $h = New-SectionLabel (Get-Text "Device Scan" "فحص الجهاز")
    $h.Left = 20
    $h.Top = 18
    $card.Controls.Add($h)

    $box = New-Object System.Windows.Forms.TextBox
    $box.Multiline = $true
    $box.ReadOnly = $true
    $box.ScrollBars = "Vertical"
    $box.BackColor = [System.Drawing.Color]::FromArgb(14,22,33)
    $box.ForeColor = $TEXT
    $box.BorderStyle = "FixedSingle"
    $box.Font = New-Object System.Drawing.Font("Consolas",9)
    $box.Left = 20
    $box.Top = 55
    $box.Width = $pageHost.ClientSize.Width - 40
    $box.Height = 350
    $box.RightToLeft = "No"
    $card.Controls.Add($box)

    $info = Get-DeviceInfo
    if (@($info).Count -eq 0) {
        $box.Text = Get-Text "No device information was returned." "لم يتم العثور على معلومات الجهاز."
    } else {
        $box.Text = ($info -join [Environment]::NewLine)
    }

    $scanBtn = New-Button (Get-Text "Rescan" "إعادة الفحص")
    $scanBtn.Left = 20
    $scanBtn.Top = 420
    $scanBtn.Width = 140
    $scanBtn.Add_Click({ Show-DeviceScan })
    $card.Controls.Add($scanBtn)

    $updateBtn = New-Button (Get-Text "Open Windows Update" "فتح Windows Update")
    $updateBtn.Left = 175
    $updateBtn.Top = 420
    $updateBtn.Width = 190
    $updateBtn.Add_Click({
        Safe { Start-Process "ms-settings:windowsupdate" } "Device Scan" "Windows Update"
    })
    $card.Controls.Add($updateBtn)
}

# -----------------------------
# Optimization
# -----------------------------
function Show-Optimization {
    Clear-Page

    $card = New-Card 450
    $pageHost.Controls.Add($card)

    $h = New-SectionLabel (Get-Text "Optimization" "التحسينات")
    $h.Left = 20
    $h.Top = 18
    $card.Controls.Add($h)

    $checks = @(
        @{ Text = (Get-Text "Remove OneDrive" "إزالة OneDrive"); Key="OneDrive" },
        @{ Text = (Get-Text "Remove Microsoft Teams" "إزالة Microsoft Teams"); Key="Teams" },
        @{ Text = (Get-Text "Disable Widgets" "تعطيل Widgets"); Key="Widgets" },
        @{ Text = (Get-Text "Disable Task View" "تعطيل Task View"); Key="TaskView" },
        @{ Text = (Get-Text "Disable Recall" "تعطيل Recall"); Key="Recall" },
        @{ Text = (Get-Text "Keep Snipping Tool" "الإبقاء على Snipping Tool"); Key="Snipping" },
        @{ Text = (Get-Text "Keep Xbox app, remove other Xbox components" "الإبقاء على Xbox app وحذف مكونات Xbox الأخرى"); Key="Xbox" },
        @{ Text = (Get-Text "Keep Camera & Microphone permissions" "الإبقاء على صلاحيات Camera وMicrophone"); Key="Privacy" }
    )

    $y = 58
    $boxControls = @()

    foreach ($item in $checks) {
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $item.Text
        $cb.Tag = $item.Key
        $cb.ForeColor = $TEXT
        $cb.BackColor = $CARD
        $cb.Font = $font
        $cb.Left = 25
        $cb.Top = $y
        $cb.Width = $pageHost.ClientSize.Width - 60
        $cb.Height = 32
        $cb.Checked = $false
        $card.Controls.Add($cb)
        $boxControls += $cb
        $y += 42
    }

    $apply = New-Button (Get-Text "Apply Selected" "تطبيق المحدد")
    $apply.Left = 20
    $apply.Top = 400
    $apply.Width = 160
    $apply.Add_Click({
        $selected = @($boxControls | Where-Object { $_.Checked })
        if ($selected.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                (Get-Text "Select at least one option." "اختر خياراً واحداً على الأقل."),
                "Windows 11 Gaming Optimizer",
                "OK",
                "Information"
            ) | Out-Null
            return
        }

        $confirmText = Get-Text "Apply the selected changes?`r`n`r`nNo personal files will be deleted." "هل تريد تطبيق التعديلات المحددة؟`r`n`r`nلن يتم حذف ملفاتك الشخصية."
        $answer = [System.Windows.Forms.MessageBox]::Show(
            $confirmText,
            "Windows 11 Gaming Optimizer",
            "YesNo",
            "Warning"
        )

        if ($answer -ne "Yes") { return }

        foreach ($c in $selected) {
            switch ($c.Tag) {
                "OneDrive" {
                    Safe {
                        $p = Get-AppxPackage -AllUsers "Microsoft.OneDriveSync"
                        if (@($p).Count -gt 0) { $p | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue }
                    } "Optimization" "OneDrive"
                }
                "Teams" {
                    Safe {
                        Get-AppxPackage -AllUsers "*MicrosoftTeams*" -ErrorAction SilentlyContinue |
                            Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
                    } "Optimization" "Microsoft Teams"
                }
                "Widgets" {
                    Safe {
                        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force | Out-Null
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Type DWord -Value 0 -ErrorAction Stop
                    } "Optimization" "Widgets"
                }
                "TaskView" {
                    Safe {
                        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force | Out-Null
                        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 0 -ErrorAction Stop
                    } "Optimization" "Task View"
                }
                "Recall" {
                    Safe {
                        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Force | Out-Null
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Type DWord -Value 1 -ErrorAction Stop
                    } "Optimization" "Recall"
                }
                "Snipping" {
                    Add-Result "Optimization" "Snipping Tool" "SKIPPED" "Intentionally kept."
                }
                "Xbox" {
                    Add-Result "Optimization" "Xbox" "SKIPPED" "Xbox app intentionally kept."
                }
                "Privacy" {
                    Add-Result "Privacy" "Camera/Microphone" "SKIPPED" "Permissions intentionally kept."
                }
            }
        }

        [System.Windows.Forms.MessageBox]::Show(
            (Get-Text "Selected changes finished. Open Results to review OK, SKIPPED and ERROR items." "انتهت التعديلات المحددة. افتح Results لمراجعة OK وSKIPPED وERROR."),
            "Windows 11 Gaming Optimizer",
            "OK",
            "Information"
        ) | Out-Null
    })
    $card.Controls.Add($apply)
}

# -----------------------------
# Optional Apps
# -----------------------------
function Show-OptionalApps {
    Clear-Page

    $card = New-Card 430
    $pageHost.Controls.Add($card)

    $h = New-SectionLabel (Get-Text "Optional Apps" "التطبيقات الاختيارية")
    $h.Left = 20
    $h.Top = 18
    $card.Controls.Add($h)

    $desc = New-WrapLabel (Get-Text "Select apps to install. The installer uses official winget package sources where available." "حدد التطبيقات التي تريد تثبيتها. يستخدم التثبيت مصادر winget الرسمية المتاحة.") 50 55
    $card.Controls.Add($desc)

    $apps = @(
        @{ Name="Google Chrome"; Id="Google.Chrome" },
        @{ Name="Brave"; Id="Brave.Brave" },
        @{ Name="Discord"; Id="Discord.Discord" },
        @{ Name="Parsec"; Id="Parsec.Parsec" }
    )

    $appChecks = @()
    $y = 115
    foreach ($a in $apps) {
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $a.Name
        $cb.Tag = $a.Id
        $cb.ForeColor = $TEXT
        $cb.BackColor = $CARD
        $cb.Font = $font
        $cb.Left = 25
        $cb.Top = $y
        $cb.Width = 350
        $cb.Height = 32
        $card.Controls.Add($cb)
        $appChecks += $cb
        $y += 45
    }

    $install = New-Button (Get-Text "Install Selected" "تثبيت المحدد")
    $install.Left = 20
    $install.Top = 330
    $install.Width = 170
    $install.Add_Click({
        $selected = @($appChecks | Where-Object { $_.Checked })
        if ($selected.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                (Get-Text "Select at least one app." "اختر تطبيقاً واحداً على الأقل."),
                "Windows 11 Gaming Optimizer",
                "OK",
                "Information"
            ) | Out-Null
            return
        }

        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            [System.Windows.Forms.MessageBox]::Show(
                (Get-Text "winget was not found. Install App Installer from Microsoft Store first." "لم يتم العثور على winget. ثبّت App Installer من Microsoft Store أولاً."),
                "Windows 11 Gaming Optimizer",
                "OK",
                "Warning"
            ) | Out-Null
            return
        }

        foreach ($c in $selected) {
            Safe {
                & winget install --id $c.Tag --exact --source winget --accept-source-agreements --accept-package-agreements
            } "Optional Apps" $c.Text
        }

        Show-Results
    })
    $card.Controls.Add($install)
}

# -----------------------------
# Results
# -----------------------------
function Show-Results {
    Clear-Page

    $card = New-Card 520
    $pageHost.Controls.Add($card)

    $h = New-SectionLabel (Get-Text "Results" "النتائج")
    $h.Left = 20
    $h.Top = 18
    $card.Controls.Add($h)

    $box = New-Object System.Windows.Forms.TextBox
    $box.Multiline = $true
    $box.ReadOnly = $true
    $box.ScrollBars = "Both"
    $box.WordWrap = $false
    $box.BackColor = [System.Drawing.Color]::FromArgb(14,22,33)
    $box.ForeColor = $TEXT
    $box.BorderStyle = "FixedSingle"
    $box.Font = New-Object System.Drawing.Font("Consolas",9)
    $box.Left = 20
    $box.Top = 55
    $box.Width = $pageHost.ClientSize.Width - 40
    $box.Height = 390
    $card.Controls.Add($box)

    $lines = New-Object System.Collections.Generic.List[string]

    if ($script:Results.Count -eq 0) {
        $lines.Add((Get-Text "No actions have been recorded yet." "لا توجد عمليات مسجلة حتى الآن."))
    } else {
        foreach ($r in $script:Results) {
            $lines.Add(("[{0}] {1} | {2} | {3}" -f $r.Status,$r.Category,$r.Item,$r.Details))
        }
    }

    $box.Text = ($lines -join [Environment]::NewLine)

    $clear = New-Button (Get-Text "Clear Results" "مسح النتائج")
    $clear.Left = 20
    $clear.Top = 460
    $clear.Width = 140
    $clear.Add_Click({
        $script:Results.Clear()
        Show-Results
    })
    $card.Controls.Add($clear)
}

# -----------------------------
# Navigation
# -----------------------------
$navButtons["Home"].Add_Click({ Show-Home })
$navButtons["Device Scan"].Add_Click({ Show-DeviceScan })
$navButtons["Optimization"].Add_Click({ Show-Optimization })
$navButtons["Optional Apps"].Add_Click({ Show-OptionalApps })
$navButtons["Results"].Add_Click({ Show-Results })

$langBox.Add_SelectedIndexChanged({
    if ($langBox.SelectedIndex -eq 1) {
        $script:Language = "Arabic"
    } else {
        $script:Language = "English"
    }
    # Rebuild page so text and alignment update without restarting.
    Show-Home
})

$form.Add_Shown({
    Show-Home
    $form.Activate()
})

[System.Windows.Forms.Application]::Run($form)
