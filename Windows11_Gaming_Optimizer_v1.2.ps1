#requires -version 5.1
<#
Windows 11 Gaming Optimizer & Setup Assistant
v1.2 - PowerShell Console Edition
- Arabic / English
- Runs entirely inside the same PowerShell window
- No GUI windows
- No automatic backup
- Designed primarily for new/fresh Windows 11 installations
- Does NOT format, initialize, delete partitions, or touch personal files
- Keeps Snipping Tool, Xbox, image/video thumbnails, ClearType/font smoothing,
  Camera permission, and Microphone permission unchanged
- Individual errors are logged and do not stop the whole script
#>

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

# -------------------- ADMIN --------------------
function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host ""
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Red
    Write-Host "يرجى تشغيل PowerShell كمسؤول." -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# -------------------- CONSOLE --------------------
try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    [Console]::InputEncoding  = [System.Text.UTF8Encoding]::new($false)
} catch {}

try {
    $host.UI.RawUI.WindowTitle = "Windows 11 Gaming Optimizer v1.2"
} catch {}

# -------------------- LANGUAGE --------------------
$Lang = $null

function T {
    param([string]$Key)
    if ($Lang -eq 'AR') { return $AR[$Key] }
    return $EN[$Key]
}

$EN = @{
    Title='WINDOWS 11 GAMING OPTIMIZER'
    Subtitle='Setup & Optimization Assistant'
    ChooseLanguage='Choose your language'
    Arabic='[1] العربية'
    English='[2] English'
    Invalid='Invalid choice.'
    DisclaimerTitle='IMPORTANT NOTICE'
    Disclaimer=@'
Designed primarily for new/fresh Windows 11 installations or PCs after a format.

• No automatic backup is created.
• Personal files are not intentionally deleted.
• Disks are NEVER formatted or initialized automatically.
• Camera and Microphone permissions are NOT changed.
• Snipping Tool and Xbox are kept.
• Image/video thumbnails and ClearType/font smoothing are kept.
• If one operation fails, the script logs the error and continues.

Review the proposed changes before applying them.
'@
    Continue='Continue'
    Cancel='Cancel'
    Scan='SYSTEM DETECTION'
    Review='REVIEW CHANGES'
    Execute='APPLY SELECTED CHANGES'
    Back='Back'
    Rescan='Rescan'
    Confirm='Confirm and continue'
    No='No / Cancel'
    MainMenu='MAIN MENU'
    Device='DEVICE'
    OS='Operating System'
    CPU='CPU'
    Board='Motherboard'
    BIOS='BIOS'
    RAM='RAM'
    GPU='GPU'
    Storage='STORAGE'
    Driver='Driver'
    Disk='Disk'
    Model='Model'
    Manufacturer='Manufacturer'
    Size='Size'
    Bus='Bus'
    Style='Partition Style'
    Status='Status'
    Physical='Physical GPU'
    Virtual='Virtual / Display Adapter'
    Apps='APPLICATIONS'
    Windows='WINDOWS SETTINGS'
    Privacy='PRIVACY'
    Gaming='GAMING & PERFORMANCE'
    Network='CLEANUP & NETWORK'
    Drivers='GPU & DRIVERS'
    Disks='STORAGE & DISKS'
    Keep='KEEP'
    Remove='REMOVE'
    Disable='DISABLE'
    Enable='ENABLE'
    Check='CHECK'
    Clean='CLEAN'
    ReviewAction='REVIEW'
    Skip='SKIP'
    Selected='selected'
    NothingSelected='No changes selected.'
    Detected='Detected'
    Unknown='Unknown'
    NotInstalled='Not installed / already removed'
    NotSupported='Not supported on this system'
    Opened='Opened official page'
    UpdateCheck='Windows Update scan started'
    DriverPages='Official driver pages'
    GPUType='GPU type'
    DiskWarning='WARNING: Unallocated/unpartitioned disks were detected.'
    DiskNoFormat='No disk will be formatted or initialized automatically.'
    OpenDisk='Open Disk Management'
    Nvidia='NVIDIA'
    AMD='AMD'
    Intel='Intel'
    Finish='FINISHED'
    Success='SUCCESS'
    Skipped='SKIPPED'
    Error='ERROR'
    Total='TOTAL'
    Report='FINAL REPORT'
    ReportSaved='Report saved to'
    Restart='A restart is recommended after finishing.'
    PressEnter='Press Enter to continue'
    Exit='Exit'
    ShowDetails='Show details'
    Choose='Choose'
    Yes='Yes'
    NoShort='No'
    DriverNote='The script detects the GPU and opens the official vendor page. It does not silently install GPU drivers.'
    WindowsUpdateNote='Windows Update is triggered for a scan. Windows decides which updates are applicable.'
    DiskNote='Disks are displayed with manufacturer/model. No formatting, initialization, partition deletion, or data destruction is performed.'
}

$AR = @{
    Title='WINDOWS 11 GAMING OPTIMIZER'
    Subtitle='Setup & Optimization Assistant'
    ChooseLanguage='اختر اللغة'
    Arabic='[1] العربية'
    English='[2] English'
    Invalid='اختيار غير صحيح.'
    DisclaimerTitle='تنبيه مهم'
    Disclaimer=@'
مصمم بشكل أساسي للأجهزة الجديدة أو الأجهزة بعد الفورمات.

• لن يتم إنشاء Backup تلقائي.
• لن يتم حذف ملفاتك الشخصية عمدًا.
• لن يتم عمل Format أو Initialize لأي قرص تلقائيًا.
• صلاحية Camera و Microphone لن يتم تغييرها.
• سيتم إبقاء Snipping Tool و Xbox.
• سيتم إبقاء Image/Video Thumbnails و ClearType و Font Smoothing.
• إذا فشلت عملية واحدة، سيتم تسجيل الخطأ وسيكمل السكربت بقية العمليات.

راجع التعديلات المقترحة قبل تنفيذها.
'@
    Continue='متابعة'
    Cancel='إلغاء'
    Scan='فحص الجهاز'
    Review='مراجعة التعديلات'
    Execute='تنفيذ التعديلات المحددة'
    Back='رجوع'
    Rescan='إعادة الفحص'
    Confirm='موافق والمتابعة'
    No='لا / إلغاء'
    MainMenu='القائمة الرئيسية'
    Device='معلومات الجهاز'
    OS='نظام التشغيل'
    CPU='المعالج'
    Board='اللوحة الأم'
    BIOS='BIOS'
    RAM='الذاكرة'
    GPU='كرت الشاشة'
    Storage='التخزين'
    Driver='التعريف'
    Disk='القرص'
    Model='الموديل'
    Manufacturer='الشركة'
    Size='السعة'
    Bus='نوع الاتصال'
    Style='نظام التقسيم'
    Status='الحالة'
    Physical='كرت شاشة فعلي'
    Virtual='Virtual / Display Adapter'
    Apps='التطبيقات والحذف'
    Windows='إعدادات Windows'
    Privacy='الخصوصية'
    Gaming='Gaming & Performance'
    Network='التنظيف والشبكة'
    Drivers='GPU & Drivers'
    Disks='التخزين والأقراص'
    Keep='إبقاء'
    Remove='حذف'
    Disable='تعطيل'
    Enable='تفعيل'
    Check='فحص'
    Clean='تنظيف'
    ReviewAction='مراجعة'
    Skip='تخطي'
    Selected='محدد'
    NothingSelected='لا توجد تعديلات محددة.'
    Detected='تم اكتشاف'
    Unknown='غير معروف'
    NotInstalled='غير مثبت / محذوف مسبقًا'
    NotSupported='غير مدعوم على هذا النظام'
    Opened='تم فتح الصفحة الرسمية'
    UpdateCheck='تم بدء فحص Windows Update'
    DriverPages='صفحات التعريفات الرسمية'
    GPUType='نوع كرت الشاشة'
    DiskWarning='تحذير: تم اكتشاف أقراص أو مساحات غير مقسمة.'
    DiskNoFormat='لن يتم عمل Format أو Initialize أو حذف أقسام تلقائيًا.'
    OpenDisk='فتح Disk Management'
    Nvidia='NVIDIA'
    AMD='AMD'
    Intel='Intel'
    Finish='اكتمل التنفيذ'
    Success='تم بنجاح'
    Skipped='تم التخطي'
    Error='خطأ'
    Total='الإجمالي'
    Report='التقرير النهائي'
    ReportSaved='تم حفظ التقرير في'
    Restart='يفضل إعادة تشغيل الجهاز بعد الانتهاء.'
    PressEnter='اضغط Enter للمتابعة'
    Exit='خروج'
    ShowDetails='عرض التفاصيل'
    Choose='اختر'
    Yes='نعم'
    NoShort='لا'
    DriverNote='السكربت يتعرف على كرت الشاشة ويفتح صفحة الشركة الرسمية. لا يقوم بتثبيت تعريف GPU بشكل صامت.'
    WindowsUpdateNote='يتم تشغيل فحص Windows Update، وWindows يحدد التحديثات المناسبة للجهاز.'
    DiskNote='يتم عرض الشركة والموديل للأقراص. لا يتم عمل Format أو Initialize أو حذف أقسام أو إتلاف بيانات.'
}

# -------------------- COLORS / UI --------------------
function C {
    param(
        [string]$Text,
        [ConsoleColor]$Color = 'White',
        [switch]$NoNewline
    )
    if ($NoNewline) { Write-Host $Text -ForegroundColor $Color -NoNewline }
    else { Write-Host $Text -ForegroundColor $Color }
}

function Clear-Screen { Clear-Host }

function Header {
    param([string]$Title,[string]$Subtitle='')
    Clear-Screen
    C '╔══════════════════════════════════════════════════════════════════════╗' Cyan
    C ("║  {0,-64}║" -f $Title) Cyan
    C '╠══════════════════════════════════════════════════════════════════════╣' Cyan
    if ($Subtitle) { C ("║  {0,-64}║" -f $Subtitle) DarkCyan }
    C '╚══════════════════════════════════════════════════════════════════════╝' Cyan
    Write-Host ''
}

function Section {
    param([string]$Title,[ConsoleColor]$Color='Cyan')
    C ("`n--- {0} ---" -f $Title) $Color
}

function Wait-Enter {
    Write-Host ''
    C (T 'PressEnter') DarkGray
    [void](Read-Host)
}

function Ask-YesNo {
    param([string]$Question)
    while ($true) {
        Write-Host ''
        C "$Question" Yellow
        if ($Lang -eq 'AR') { C '[1] نعم    [2] لا' White }
        else { C '[1] Yes    [2] No' White }
        $x=Read-Host '> '
        if ($x -eq '1') { return $true }
        if ($x -eq '2') { return $false }
        C (T 'Invalid') Red
    }
}

# -------------------- RESULT LOG --------------------
$Results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param([string]$Name,[ValidateSet('SUCCESS','SKIPPED','ERROR')][string]$Status,[string]$Detail='')
    $Results.Add([pscustomobject]@{
        Time=(Get-Date -Format 'HH:mm:ss')
        Name=$Name
        Status=$Status
        Detail=$Detail
    })
}

function Safe-Run {
    param([string]$Name,[scriptblock]$Action)
    try {
        & $Action
        Add-Result $Name 'SUCCESS'
        C ("[✓] {0}" -f $Name) Green
        return $true
    } catch {
        $msg=$_.Exception.Message
        Add-Result $Name 'ERROR' $msg
        C ("[!] {0}: {1}" -f $Name,$msg) Red
        return $false
    }
}

function Safe-Skip {
    param([string]$Name,[string]$Reason='')
    Add-Result $Name 'SKIPPED' $Reason
    C ("[-] {0} ({1})" -f $Name,$Reason) DarkYellow
}

# -------------------- HELPERS --------------------
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
    if ($null -eq $Bytes -or $Bytes -le 0) { return (T 'Unknown') }
    '{0:N2} GB' -f ($Bytes / 1GB)
}

function Get-AppxInstalled {
    param([string[]]$Patterns)
    $out=@()
    foreach($p in $Patterns) {
        $out += @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like $p -or $_.PackageFullName -like $p })
    }
    @($out | Sort-Object PackageFullName -Unique)
}

function Test-AppxExists {
    param([string[]]$Patterns)
    return (@(Get-AppxInstalled $Patterns).Count -gt 0)
}

function Get-PhysicalGPUs {
    # Keep virtual adapters visible in scan, but identify the physical GPU for vendor/driver actions.
    $all=@(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object Name)
    $physical=@($all | Where-Object {
        $_.Name -notmatch 'Parsec|Virtual|Remote Display|Indirect Display|Microsoft Basic Render|Basic Display'
    })
    if($physical.Count -eq 0){ $physical=$all }
    [pscustomobject]@{ All=$all; Physical=$physical }
}

function Get-SystemScan {
    $os=Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $cpu=Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    $board=Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue | Select-Object -First 1
    $bios=Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue | Select-Object -First 1
    $cs=Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $gpu=Get-PhysicalGPUs

    $disks=@(Get-Disk -ErrorAction SilentlyContinue | Select-Object Number,FriendlyName,Manufacturer,Model,SerialNumber,BusType,Size,PartitionStyle,OperationalStatus)
    $diskDetails=New-Object System.Collections.Generic.List[object]
    foreach($d in $disks){
        $parts=@(Get-Partition -DiskNumber $d.Number -ErrorAction SilentlyContinue)
        $vols=@()
        foreach($p in $parts){
            $v=Get-Volume -Partition $p -ErrorAction SilentlyContinue
            if($v){ $vols += $v }
        }
        $hasUnallocated=$false
        $sizeSum=($parts | Measure-Object Size -Sum).Sum
        if($d.Size -gt 0 -and (($d.Size-$sizeSum) -gt 1GB)){ $hasUnallocated=$true }
        $diskDetails.Add([pscustomobject]@{
            Number=$d.Number
            FriendlyName=$d.FriendlyName
            Manufacturer=$d.Manufacturer
            Model=$d.Model
            Size=$d.Size
            BusType=$d.BusType
            PartitionStyle=$d.PartitionStyle
            OperationalStatus=($d.OperationalStatus -join ', ')
            Partitions=$parts
            Volumes=$vols
            HasUnallocated=$hasUnallocated
        })
    }

    [pscustomobject]@{
        OS=$os
        CPU=$cpu
        Board=$board
        BIOS=$bios
        RAMGB=[math]::Round(($cs.TotalPhysicalMemory/1GB),1)
        GPUsAll=$gpu.All
        GPUsPhysical=$gpu.Physical
        Disks=$diskDetails
    }
}

# -------------------- PROPOSALS --------------------
$Proposals=@(
    [pscustomobject]@{Id='onedrive';Cat='Apps';Name='OneDrive';Action='Remove';Detail='Remove OneDrive';Default=$true}
    [pscustomobject]@{Id='teams';Cat='Apps';Name='Microsoft Teams';Action='Remove';Detail='Remove Teams app';Default=$true}
    [pscustomobject]@{Id='clipchamp';Cat='Apps';Name='Clipchamp';Action='Remove';Detail='Remove Clipchamp';Default=$true}
    [pscustomobject]@{Id='consumerapps';Cat='Apps';Name='Consumer Windows Apps';Action='Remove';Detail='Remove News, Weather, Tips, Get Help, Maps, People and Solitaire';Default=$true}

    [pscustomobject]@{Id='dark';Cat='Windows';Name='Dark Mode';Action='Enable';Detail='Enable Windows dark theme';Default=$true}
    [pscustomobject]@{Id='wallpaper';Cat='Windows';Name='Black Wallpaper';Action='Enable';Detail='Set a black Windows wallpaper';Default=$true}
    [pscustomobject]@{Id='search';Cat='Windows';Name='Taskbar Search';Action='Change';Detail='Search icon only';Default=$true}
    [pscustomobject]@{Id='taskview';Cat='Windows';Name='Task View';Action='Disable';Detail='Hide Task View button';Default=$true}
    [pscustomobject]@{Id='widgets';Cat='Windows';Name='Widgets';Action='Disable';Detail='Hide Widgets';Default=$true}
    [pscustomobject]@{Id='recall';Cat='Windows';Name='Recall';Action='Disable';Detail='Disable Recall policy when supported';Default=$true}

    [pscustomobject]@{Id='adid';Cat='Privacy';Name='Advertising ID';Action='Disable';Detail='Disable advertising ID';Default=$true}
    [pscustomobject]@{Id='telemetry';Cat='Privacy';Name='Optional Diagnostic Data';Action='Disable';Detail='Restrict optional diagnostic data';Default=$true}
    [pscustomobject]@{Id='suggestions';Cat='Privacy';Name='Windows Suggestions';Action='Disable';Detail='Disable consumer suggestions';Default=$true}

    [pscustomobject]@{Id='gamemode';Cat='Gaming';Name='Game Mode';Action='Enable';Detail='Enable Game Mode';Default=$true}
    [pscustomobject]@{Id='hags';Cat='Gaming';Name='Hardware-Accelerated GPU Scheduling';Action='Enable';Detail='Enable HAGS when supported';Default=$true}
    [pscustomobject]@{Id='power';Cat='Gaming';Name='Power Plan';Action='Change';Detail='High Performance when available';Default=$true}

    [pscustomobject]@{Id='temp';Cat='Network';Name='Temporary Files';Action='Clean';Detail='Clean user/system temp files';Default=$true}
    [pscustomobject]@{Id='dns';Cat='Network';Name='DNS Cache';Action='Clean';Detail='Clear DNS cache';Default=$true}
    [pscustomobject]@{Id='updates';Cat='Network';Name='Windows Update';Action='Check';Detail='Start Windows Update scan';Default=$true}

    [pscustomobject]@{Id='gpu';Cat='Drivers';Name='GPU Detection';Action='Check';Detail='Detect NVIDIA / AMD / Intel';Default=$true}
    [pscustomobject]@{Id='drivers';Cat='Drivers';Name='Hardware Driver Check';Action='Check';Detail='Show Windows Update driver availability';Default=$true}

    [pscustomobject]@{Id='disks';Cat='Disks';Name='Disk Review';Action='Review';Detail='Show disk manufacturer/model and unallocated space';Default=$true}
)

# Explicit keep list, displayed separately.
$KeepItems=@(
    'Snipping Tool',
    'Xbox',
    'Image/Video Thumbnails',
    'ClearType / Font Smoothing',
    'Camera Permission',
    'Microphone Permission',
    'Hyper-V'
)

function Cat-Color {
    param($cat)
    switch($cat){
        'Apps' {'Red'}
        'Windows' {'Yellow'}
        'Privacy' {'Blue'}
        'Gaming' {'Green'}
        'Network' {'Cyan'}
        'Drivers' {'Magenta'}
        'Disks' {'DarkRed'}
        default {'White'}
    }
}

function Cat-Text {
    param($cat)
    switch($cat){
        'Apps' { T 'Apps' }
        'Windows' { T 'Windows' }
        'Privacy' { T 'Privacy' }
        'Gaming' { T 'Gaming' }
        'Network' { T 'Network' }
        'Drivers' { T 'Drivers' }
        'Disks' { T 'Disks' }
    }
}

function Action-Text {
    param($action)
    switch($action){
        'Remove' { T 'Remove' }
        'Disable' { T 'Disable' }
        'Enable' { T 'Enable' }
        'Check' { T 'Check' }
        'Clean' { T 'Clean' }
        'Review' { T 'ReviewAction' }
        default { $action }
    }
}

# -------------------- SCAN SCREEN --------------------
function Show-Scan {
    param($Scan)

    Header (T 'Scan') (T 'Subtitle')

    Section (T 'Device') Cyan
    C ("{0,-20}: {1}" -f (T 'OS'), $Scan.OS.Caption) White
    C ("{0,-20}: {1}" -f (T 'CPU'), $Scan.CPU.Name) White
    C ("{0,-20}: {1}" -f (T 'Board'), "$($Scan.Board.Manufacturer) $($Scan.Board.Product)") White
    C ("{0,-20}: {1}" -f (T 'BIOS'), $Scan.BIOS.SMBIOSBIOSVersion) White
    C ("{0,-20}: {1} GB" -f (T 'RAM'), $Scan.RAMGB) White

    Section (T 'GPU') Magenta
    foreach($g in $Scan.GPUsPhysical){
        C ("[GPU] {0}" -f $g.Name) Green
        C ("      {0}: {1}" -f (T 'Driver'), $g.DriverVersion) DarkGray
        $vendor='Unknown'
        if($g.Name -match 'NVIDIA'){ $vendor='NVIDIA' }
        elseif($g.Name -match 'AMD|Radeon'){ $vendor='AMD' }
        elseif($g.Name -match 'Intel'){ $vendor='Intel' }
        C ("      {0}: {1}" -f (T 'GPUType'), (T 'Physical')) DarkGray
        C ("      Vendor: $vendor") DarkGray
    }
    $virtual=@($Scan.GPUsAll | Where-Object { $Scan.GPUsPhysical -notcontains $_ })
    foreach($g in $virtual){
        C ("[DISPLAY] {0}" -f $g.Name) DarkGray
        C ("           {0}: {1}" -f (T 'Driver'), $g.DriverVersion) DarkGray
    }

    Section (T 'Storage') DarkCyan
    foreach($d in $Scan.Disks){
        $man=$d.Manufacturer
        if([string]::IsNullOrWhiteSpace($man)){ $man=(T 'Unknown') }
        $model=$d.Model
        if([string]::IsNullOrWhiteSpace($model)){ $model=$d.FriendlyName }
        $state='OK'
        if($d.HasUnallocated){ $state='UNALLOCATED SPACE DETECTED' }
        C ("Disk {0} | {1} | {2} | {3} | {4} | {5}" -f $d.Number,$man,$model,(Format-GB $d.Size),$d.BusType,$state) $(if($d.HasUnallocated){'Yellow'}else{'White'})
    }

    if(@($Scan.Disks | Where-Object HasUnallocated).Count -gt 0){
        C (T 'DiskWarning') Yellow
        C (T 'DiskNoFormat') Yellow
    }

    Write-Host ''
    C '[1] Continue    [2] Rescan    [3] Cancel' White
    while($true){
        $x=Read-Host '> '
        if($x -eq '1'){return 'CONTINUE'}
        if($x -eq '2'){return 'RESCAN'}
        if($x -eq '3'){return 'CANCEL'}
        C (T 'Invalid') Red
    }
}

# -------------------- REVIEW SCREEN --------------------
function Show-Review {
    Header (T 'Review') (T 'Subtitle')

    C 'Default-selected changes are marked [X]. You can toggle each item by its number.' Cyan
    if($Lang -eq 'AR'){ C 'التعديلات المحددة افتراضيًا تظهر [X]. اكتب رقم العنصر لتغييره.' Cyan }
    Write-Host ''

    $state=@{}
    foreach($p in $Proposals){ $state[$p.Id]=$p.Default }

    function Render-Review {
        Header (T 'Review') (T 'Subtitle')
        C 'X = selected   O = skipped' DarkGray
        Write-Host ''
        $i=1
        $last=''
        foreach($p in $Proposals){
            if($p.Cat -ne $last){
                Section (Cat-Text $p.Cat) (Cat-Color $p.Cat)
                $last=$p.Cat
            }
            $mark=if($state[$p.Id]){'X'}else{'O'}
            $col=if($state[$p.Id]){'Green'}else{'DarkGray'}
            C ("[{0,2}] [{1}] {2} -> {3}" -f $i,$mark,$p.Name,(Action-Text $p.Action)) $col
            C ("      {0}" -f $p.Detail) DarkGray
            $i++
        }

        Section 'KEEP / NOT TOUCHED' Green
        foreach($k in $KeepItems){ C ("[KEEP] {0}" -f $k) Green }

        Write-Host ''
        C '[A] Apply selected    [R] Reset defaults    [C] Cancel' White
    }

    while($true){
        Render-Review
        $x=(Read-Host '> ').Trim().ToUpperInvariant()
        if($x -eq 'A'){ return @($Proposals | Where-Object { $state[$_.Id] }) }
        if($x -eq 'R'){ foreach($p in $Proposals){$state[$p.Id]=$p.Default}; continue }
        if($x -eq 'C'){ return $null }
        $n=0
        if([int]::TryParse($x,[ref]$n) -and $n -ge 1 -and $n -le $Proposals.Count){
            $p=$Proposals[$n-1]
            $state[$p.Id]=-not $state[$p.Id]
        } else {
            C (T 'Invalid') Red
            Start-Sleep -Milliseconds 600
        }
    }
}

# -------------------- APPLY --------------------
function Apply-Change {
    param($p)

    switch($p.Id){
        'onedrive' {
            $exe="$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
            if(-not(Test-Path $exe)){ $exe="$env:SystemRoot\System32\OneDriveSetup.exe" }
            if(Test-Path $exe){
                Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                Safe-Run 'OneDrive' { Start-Process $exe '/uninstall' -Wait -NoNewWindow } | Out-Null
            } else { Safe-Skip 'OneDrive' (T 'NotInstalled') }
        }
        'teams' {
            $pkgs=@(Get-AppxInstalled @('*MSTeams*'))
            if($pkgs.Count -gt 0){
                Safe-Run 'Microsoft Teams' { foreach($pkg in $pkgs){ Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop } } | Out-Null
            } else { Safe-Skip 'Microsoft Teams' (T 'NotInstalled') }
        }
        'clipchamp' {
            $pkgs=@(Get-AppxInstalled @('*Clipchamp*'))
            if($pkgs.Count -gt 0){
                Safe-Run 'Clipchamp' { foreach($pkg in $pkgs){ Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop } } | Out-Null
            } else { Safe-Skip 'Clipchamp' (T 'NotInstalled') }
        }
        'consumerapps' {
            $groups=@(
                @{Name='News';Patterns=@('*BingNews*')},
                @{Name='Weather';Patterns=@('*BingWeather*')},
                @{Name='Tips';Patterns=@('*Getstarted*','*MicrosoftTips*')},
                @{Name='Get Help';Patterns=@('*GetHelp*')},
                @{Name='Maps';Patterns=@('*WindowsMaps*')},
                @{Name='People';Patterns=@('*MicrosoftPeople*')},
                @{Name='Solitaire';Patterns=@('*MicrosoftSolitaireCollection*')}
            )
            foreach($g in $groups){
                $pkgs=@(Get-AppxInstalled $g.Patterns)
                if($pkgs.Count -eq 0){ Safe-Skip $g.Name (T 'NotInstalled') }
                else {
                    Safe-Run $g.Name { foreach($pkg in $pkgs){ Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop } } | Out-Null
                }
            }
        }
        'dark' {
            Safe-Run 'Dark Mode' {
                Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'AppsUseLightTheme' 0
                Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'SystemUsesLightTheme' 0
            } | Out-Null
        }
        'wallpaper' {
            Safe-Run 'Black Wallpaper' {
                $path="$env:WINDIR\Web\Wallpaper\Windows\img0.jpg"
                if(-not(Test-Path $path)){ throw 'Windows wallpaper resource not found' }
                Set-RegString 'HKCU:\Control Panel\Desktop' 'Wallpaper' $path
                Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class WallpaperApi {
 [DllImport("user32.dll", CharSet=CharSet.Unicode)]
 public static extern int SystemParametersInfo(int action,int param,string path,int winIni);
}
'@
                [WallpaperApi]::SystemParametersInfo(20,0,$path,3) | Out-Null
            } | Out-Null
        }
        'search' {
            Safe-Run 'Taskbar Search' {
                Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'SearchboxTaskbarMode' 1
            } | Out-Null
        }
        'taskview' {
            Safe-Run 'Task View' {
                Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowTaskViewButton' 0
            } | Out-Null
        }
        'widgets' {
            Safe-Run 'Widgets' {
                Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarDa' 0
            } | Out-Null
        }
        'recall' {
            Safe-Run 'Recall' {
                Set-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 1
            } | Out-Null
        }
        'adid' {
            Safe-Run 'Advertising ID' {
                Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
            } | Out-Null
        }
        'telemetry' {
            Safe-Run 'Optional Diagnostic Data' {
                Set-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
            } | Out-Null
        }
        'suggestions' {
            Safe-Run 'Windows Suggestions' {
                $p='HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
                foreach($n in @('SubscribedContent-338388Enabled','SubscribedContent-338389Enabled','SubscribedContent-353694Enabled','SubscribedContent-353696Enabled','SystemPaneSuggestionsEnabled')){
                    Set-RegDword $p $n 0
                }
            } | Out-Null
        }
        'gamemode' {
            Safe-Run 'Game Mode' {
                Set-RegDword 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
            } | Out-Null
        }
        'hags' {
            Safe-Run 'Hardware-Accelerated GPU Scheduling' {
                Set-RegDword 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2
            } | Out-Null
        }
        'power' {
            Safe-Run 'Power Plan' {
                $plans=(powercfg /list 2>$null)
                if($plans -match '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'){
                    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c | Out-Null
                } else { throw 'High Performance power plan unavailable' }
            } | Out-Null
        }
        'temp' {
            Safe-Run 'Temporary Files' {
                Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item "$env:WINDIR\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
            } | Out-Null
        }
        'dns' {
            Safe-Run 'DNS Cache' { Clear-DnsClientCache } | Out-Null
        }
        'updates' {
            Safe-Run 'Windows Update' {
                $u="$env:SystemRoot\System32\UsoClient.exe"
                if(Test-Path $u){ Start-Process $u 'StartScan' -WindowStyle Hidden }
                else { throw 'Windows Update client unavailable' }
            } | Out-Null
        }
        'gpu' {
            $scan=Get-SystemScan
            foreach($g in $scan.GPUsPhysical){
                $vendor='Unknown'
                if($g.Name -match 'NVIDIA'){ $vendor='NVIDIA' }
                elseif($g.Name -match 'AMD|Radeon'){ $vendor='AMD' }
                elseif($g.Name -match 'Intel'){ $vendor='Intel' }
                C ("[GPU] {0} | {1} | {2}: {3}" -f $g.Name,$vendor,(T 'Driver'),$g.DriverVersion) Green
            }
            Safe-Skip 'GPU Detection' 'Detection only; no silent GPU driver installation'
        }
        'drivers' {
            Safe-Run 'Hardware Driver Check' {
                $u="$env:SystemRoot\System32\UsoClient.exe"
                if(Test-Path $u){ Start-Process $u 'StartScan' -WindowStyle Hidden }
                else { throw 'Windows Update client unavailable' }
            } | Out-Null
            Safe-Skip 'GPU vendor driver installation' (T 'DriverNote')
        }
        'disks' {
            Safe-Skip 'Disk Review' (T 'DiskNote')
        }
    }
}

# -------------------- GPU / DISK MENU --------------------
function Show-HardwareMenu {
    param($Scan)
    Header (T 'Drivers') (T 'Subtitle')

    Section (T 'GPU') Magenta
    foreach($g in $Scan.GPUsPhysical){
        $vendor='Unknown'
        if($g.Name -match 'NVIDIA'){ $vendor='NVIDIA' }
        elseif($g.Name -match 'AMD|Radeon'){ $vendor='AMD' }
        elseif($g.Name -match 'Intel'){ $vendor='Intel' }
        C "$($g.Name) | $vendor | Driver: $($g.DriverVersion)" Green
    }

    Section (T 'DriverPages') Magenta
    C '[1] NVIDIA official driver page' White
    C '[2] AMD official driver page' White
    C '[3] Intel official driver page' White
    C '[4] Open Disk Management' White
    C '[5] Back' White
    Write-Host ''
    C (T 'DriverNote') DarkGray
    C (T 'WindowsUpdateNote') DarkGray
    C (T 'DiskNote') DarkGray

    while($true){
        $x=Read-Host '> '
        switch($x){
            '1' { Start-Process 'https://www.nvidia.com/Download/index.aspx'; Safe-Skip 'NVIDIA Driver Page' (T 'Opened') }
            '2' { Start-Process 'https://www.amd.com/en/support/download/drivers.html'; Safe-Skip 'AMD Driver Page' (T 'Opened') }
            '3' { Start-Process 'https://www.intel.com/content/www/us/en/support/detect.html'; Safe-Skip 'Intel Driver Page' (T 'Opened') }
            '4' { Start-Process 'diskmgmt.msc'; Safe-Skip 'Disk Management' (T 'Opened') }
            '5' { return }
            default { C (T 'Invalid') Red }
        }
    }
}

# -------------------- FINAL REPORT --------------------
function Show-FinalReport {
    Header (T 'Report') (T 'Subtitle')

    $success=@($Results | Where-Object Status -eq 'SUCCESS').Count
    $skipped=@($Results | Where-Object Status -eq 'SKIPPED').Count
    $errors=@($Results | Where-Object Status -eq 'ERROR').Count

    C ("{0,-12}: {1}" -f (T 'Success'),$success) Green
    C ("{0,-12}: {1}" -f (T 'Skipped'),$skipped) Yellow
    C ("{0,-12}: {1}" -f (T 'Error'),$errors) Red
    C ("{0,-12}: {1}" -f (T 'Total'),$Results.Count) Cyan

    Section (T 'ShowDetails') Cyan
    foreach($r in $Results){
        $color=switch($r.Status){'SUCCESS'{'Green'}'SKIPPED'{'Yellow'}'ERROR'{'Red'}default{'White'}}
        C ("[{0}] {1} - {2}" -f $r.Status,$r.Name,$r.Detail) $color
    }

    $reportPath=Join-Path $env:USERPROFILE 'Desktop\Windows11_Optimizer_Report.txt'
    $header=@(
        'Windows 11 Gaming Optimizer v1.2'
        "Date: $(Get-Date)"
        ''
        "SUCCESS: $success"
        "SKIPPED: $skipped"
        "ERROR: $errors"
        ''
    )
    ($header + ($Results | Format-Table -AutoSize | Out-String)) | Set-Content -Path $reportPath -Encoding UTF8

    Write-Host ''
    C ("{0}: {1}" -f (T 'ReportSaved'),$reportPath) Cyan
    C (T 'Restart') Yellow
    Wait-Enter
}

# -------------------- MAIN --------------------
while($true){
    Header (T 'Title') (T 'Subtitle')
    C (T 'ChooseLanguage') Yellow
    C (T 'Arabic') White
    C (T 'English') White
    $l=Read-Host '> '
    if($l -eq '1'){ $Lang='AR'; break }
    if($l -eq '2'){ $Lang='EN'; break }
    C (T 'Invalid') Red
}

Header (T 'DisclaimerTitle') (T 'Subtitle')
C (T 'Disclaimer') White
Write-Host ''
if(-not (Ask-YesNo (T 'Continue'))){ exit }

do {
    $scan=Get-SystemScan
    $action=Show-Scan $scan
    if($action -eq 'CANCEL'){ exit }
} while($action -eq 'RESCAN')

while($true){
    $chosen=Show-Review
    if($null -eq $chosen){ exit }
    if(@($chosen).Count -eq 0){
        C (T 'NothingSelected') Yellow
        Wait-Enter
        continue
    }

    Header (T 'Execute') (T 'Subtitle')
    C ("{0}: {1}" -f (T 'Selected'),@($chosen).Count) Cyan
    foreach($p in $chosen){ C "[X] $($p.Name) -> $(Action-Text $p.Action)" Green }
    Write-Host ''
    if(Ask-YesNo (T 'Confirm')){ break }
}

Header (T 'Execute') (T 'Subtitle')
C 'Starting...' Cyan
foreach($p in $chosen){
    Section "$($p.Name) -> $(Action-Text $p.Action)" (Cat-Color $p.Cat)
    Apply-Change $p
}

# Hardware / driver / disk review is informational and optional.
Show-HardwareMenu $scan
Show-FinalReport

Header (T 'Finish') (T 'Title')
C (T 'Restart') Yellow
Wait-Enter
