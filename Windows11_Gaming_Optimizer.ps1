#requires -version 5.1
# Windows 11 Gaming Optimizer v1.3
# Lightweight WinForms GUI. No background service. No disk formatting/partitioning.

Set-StrictMode -Version Latest
$ErrorActionPreference='Continue'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$C=@{
 BG=[Drawing.Color]::FromArgb(10,15,23); Panel=[Drawing.Color]::FromArgb(18,25,36)
 Panel2=[Drawing.Color]::FromArgb(24,33,47); Text=[Drawing.Color]::FromArgb(235,241,248)
 Muted=[Drawing.Color]::FromArgb(150,164,182); Blue=[Drawing.Color]::FromArgb(45,125,240)
 Green=[Drawing.Color]::FromArgb(35,185,112); Red=[Drawing.Color]::FromArgb(225,72,72)
}
$Lang='en'; $Results=[Collections.ArrayList]::new()

function T($en,$ar){if($script:Lang -eq 'ar'){$ar}else{$en}}
function Log($cat,$item,$status,$details=''){[void]$Results.Add([pscustomobject]@{Time=(Get-Date -f HH:mm:ss);Category=$cat;Item=$item;Status=$status;Details=$details})}
function Safe($name,[scriptblock]$code,$cat='Optimization'){
 try{&$code;Log $cat $name 'SUCCESS'}catch{Log $cat $name 'ERROR' $_.Exception.Message}
}
function Reg($path,$name,$value,$type='DWord'){
 if(!(Test-Path $path)){New-Item $path -Force|Out-Null}
 New-ItemProperty $path $name $value -PropertyType $type -Force|Out-Null
}
function GPU{
 try{
  Get-CimInstance Win32_VideoController|Where-Object Name -notmatch 'Parsec|Virtual Display|Microsoft Basic|Indirect Display'|Select-Object -First 1
 }catch{$null}
}
function Admin{
 $p=[Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
 $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Scan{
 $os=Get-CimInstance Win32_OperatingSystem
 $cpu=Get-CimInstance Win32_Processor|select -First 1
 $bb=Get-CimInstance Win32_BaseBoard|select -First 1
 $bios=Get-CimInstance Win32_BIOS|select -First 1
 $g=GPU
 $ram=[math]::Round($os.TotalVisibleMemorySize/1MB,1)
 $sb=[Text.StringBuilder]::new()
 [void]$sb.AppendLine('WINDOWS 11 GAMING OPTIMIZER - DEVICE SCAN')
 [void]$sb.AppendLine(('='*68))
 [void]$sb.AppendLine("OS          : $($os.Caption) | Build $($os.BuildNumber)")
 [void]$sb.AppendLine("CPU         : $($cpu.Name)")
 [void]$sb.AppendLine("GPU         : $($g.Name)")
 [void]$sb.AppendLine("RAM         : $ram GB")
 [void]$sb.AppendLine("Motherboard : $($bb.Manufacturer) $($bb.Product)")
 [void]$sb.AppendLine("BIOS        : $($bios.SMBIOSBIOSVersion)")
 [void]$sb.AppendLine('')
 [void]$sb.AppendLine('STORAGE')
 [void]$sb.AppendLine(('='*68))
 foreach($d in (Get-CimInstance Win32_DiskDrive|sort Index)){
  [void]$sb.AppendLine(("Disk {0} | {1} | {2} GB | {3}" -f $d.Index,$d.Model,[math]::Round($d.Size/1GB,2),$d.InterfaceType))
  $parts=Get-CimInstance Win32_DiskPartition -Filter "DiskIndex=$($d.Index)" -EA SilentlyContinue
  if(!$parts){[void]$sb.AppendLine('  -> NO PARTITIONS / UNALLOCATED DISK DETECTED (not modified)')}
 }
 [void]$sb.AppendLine('')
 [void]$sb.AppendLine('VOLUMES')
 foreach($v in (Get-Volume|sort DriveLetter)){
  $l=if($v.DriveLetter){$v.DriveLetter}else{'-'}
  [void]$sb.AppendLine("$l | $($v.FileSystemLabel) | $($v.FileSystem) | $([math]::Round($v.Size/1GB,2)) GB | $($v.HealthStatus)")
 }
 Log 'Device Scan' 'Hardware and storage scan' 'SUCCESS'
 $scanBox.Text=$sb.ToString()
 $grid.DataSource=$null;$grid.DataSource=@($Results)
}

# Optimizations requested by user. Snipping Tool, Xbox, Hyper-V, thumbnails, ClearType,
# camera/microphone permissions are intentionally untouched.
$Opts=@(
 @{k='OneDrive';en='Remove OneDrive';ar='حذف OneDrive';a={ $p="$env:SystemRoot\SysWOW64\OneDriveSetup.exe";if(Test-Path $p){Start-Process $p '/uninstall' -Wait -WindowStyle Hidden}else{throw 'OneDrive not found'} }},
 @{k='Teams';en='Remove Microsoft Teams';ar='حذف Microsoft Teams';a={ $x=Get-AppxPackage -AllUsers '*MicrosoftTeams*';if(!$x){throw 'Teams not found'};$x|%{Remove-AppxPackage $_.PackageFullName -AllUsers -EA Stop} }},
 @{k='Widgets';en='Disable Widgets';ar='تعطيل Widgets';a={Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0;Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarDa' 0}},
 @{k='TaskView';en='Disable Task View';ar='تعطيل Task View';a={Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowTaskViewButton' 0}},
 @{k='Recall';en='Disable Recall';ar='تعطيل Recall';a={Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableRecall' 1;Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 1}},
 @{k='Search';en='Search as icon';ar='تحويل البحث إلى أيقونة';a={Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'SearchboxTaskbarMode' 1}},
 @{k='Dark';en='Dark theme';ar='الثيم الداكن';a={Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'AppsUseLightTheme' 0;Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'SystemUsesLightTheme' 0}},
 @{k='Wallpaper';en='Black desktop background';ar='خلفية سطح المكتب سوداء';a={Reg 'HKCU:\Control Panel\Colors' 'Background' '0 0 0' String;Reg 'HKCU:\Control Panel\Desktop' 'Wallpaper' '' String}},
 @{k='Privacy';en='Reduce telemetry / advertising ID';ar='تقليل جمع البيانات ومعرف الإعلانات';a={Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0;Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0}},
 @{k='GameMode';en='Enable Game Mode';ar='تفعيل Game Mode';a={Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1;Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1}},
 @{k='DVR';en='Disable Game DVR capture';ar='تعطيل Game DVR';a={Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0;Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0}},
 @{k='Power';en='Reduce power throttling';ar='تقليل Power Throttling';a={Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 1}},
 @{k='Network';en='Conservative network optimization';ar='تحسينات شبكة محافظة';a={netsh interface tcp set global rss=enabled|Out-Null;netsh interface tcp set global autotuninglevel=normal|Out-Null;netsh interface tcp set global timestamps=disabled|Out-Null}}
)

# Main window
$form=New-Object Windows.Forms.Form
$form.Text='Windows 11 Gaming Optimizer v1.3';$form.StartPosition='CenterScreen'
$form.Size=New-Object Drawing.Size(1180,760);$form.MinimumSize=New-Object Drawing.Size(1000,650)
$form.BackColor=$C.BG;$form.Font=New-Object Drawing.Font('Segoe UI',10)

$side=New-Object Windows.Forms.Panel;$side.Dock='Left';$side.Width=220;$side.BackColor=[Drawing.Color]::FromArgb(14,20,30);$form.Controls.Add($side)
$main=New-Object Windows.Forms.Panel;$main.Dock='Fill';$main.BackColor=$C.BG;$form.Controls.Add($main)

$brand=New-Object Windows.Forms.Label;$brand.Text='Windows 11 Gaming Optimizer';$brand.ForeColor=$C.Text;$brand.Font=New-Object Drawing.Font('Segoe UI Semibold',14)
$brand.Location=New-Object Drawing.Point(18,22);$brand.AutoSize=$true;$side.Controls.Add($brand)
$v=New-Object Windows.Forms.Label;$v.Text='v1.3 • Lightweight';$v.ForeColor=$C.Blue;$v.Location=New-Object Drawing.Point(20,52);$v.AutoSize=$true;$side.Controls.Add($v)

$nav=New-Object Windows.Forms.FlowLayoutPanel;$nav.Location=New-Object Drawing.Point(12,95);$nav.Size=New-Object Drawing.Size(195,470);$nav.FlowDirection='TopDown';$nav.WrapContents=$false;$nav.BackColor=$side.BackColor;$side.Controls.Add($nav)
function Nav($text){$b=New-Object Windows.Forms.Button;$b.Text="  $text";$b.Width=190;$b.Height=42;$b.FlatStyle='Flat';$b.FlatAppearance.BorderSize=0;$b.BackColor=$side.BackColor;$b.ForeColor=$C.Text;$b.TextAlign='MiddleLeft';$b.Font=New-Object Drawing.Font('Segoe UI Semibold',10);$b}
$home=Nav 'Home';$scan=Nav 'Device Scan';$opt=Nav 'Optimization';$apps=Nav 'Optional Apps';$res=Nav 'Results';$nav.Controls.AddRange(@($home,$scan,$opt,$apps,$res))

$lang=New-Object Windows.Forms.ComboBox;$lang.DropDownStyle='DropDownList';$lang.Items.AddRange(@('English','العربية'));$lang.SelectedIndex=0;$lang.Width=185;$lang.Location=New-Object Drawing.Point(18,610);$side.Controls.Add($lang)
$note=New-Object Windows.Forms.Label;$note.Text='No background service';$note.ForeColor=$C.Muted;$note.Location=New-Object Drawing.Point(18,650);$note.AutoSize=$true;$side.Controls.Add($note)

$pages=@{}
function Page($name){
 $p=New-Object Windows.Forms.Panel;$p.Dock='Fill';$p.BackColor=$C.BG;$p.Visible=$false;$main.Controls.Add($p);$pages[$name]=$p;$p
}
$pHome=Page Home;$pScan=Page Scan;$pOpt=Page Opt;$pApps=Page Apps;$pRes=Page Results
function Show($n){$pages.Values|%{$_.Visible=$false};$pages[$n].Visible=$true}
function Header($p,$en,$ar,$suben,$subar){
 $h=New-Object Windows.Forms.Label;$h.Text=$(T $en $ar);$h.Font=New-Object Drawing.Font('Segoe UI Semibold',22);$h.ForeColor=$C.Text;$h.AutoSize=$true;$h.Location=New-Object Drawing.Point(28,24);$p.Controls.Add($h)
 $s=New-Object Windows.Forms.Label;$s.Text=$(T $suben $subar);$s.ForeColor=$C.Muted;$s.AutoSize=$true;$s.Location=New-Object Drawing.Point(30,67);$p.Controls.Add($s)
}
Header $pHome 'Welcome' 'مرحبًا' 'Lightweight setup for new Windows 11 PCs or post-format systems.' 'أداة خفيفة للأجهزة الجديدة أو بعد الفورمات.'
$card=New-Object Windows.Forms.Label;$card.Text=$(T @'
No backup is created.
No personal files are deleted.
Camera/microphone permissions stay untouched.
Snipping Tool and Xbox stay installed.
Hyper-V stays untouched.
Thumbnails and ClearType stay untouched.
Unallocated disks are detected only — never formatted automatically.
'@ @'
لا يتم إنشاء Backup.
لا يتم حذف ملفاتك الشخصية.
صلاحيات الكاميرا والمايك لا تتغير.
Snipping Tool وXbox يبقيان.
Hyper-V لا يتم لمسه.
Thumbnails وClearType لا يتم تعديلهما.
الأقراص غير المخصصة يتم اكتشافها فقط — ولا تتم تهيئتها تلقائيًا.
'@)
$card.Location=New-Object Drawing.Point(28,115);$card.Size=New-Object Drawing.Size(850,230);$card.BackColor=$C.Panel;$card.ForeColor=$C.Text;$card.Font=New-Object Drawing.Font('Segoe UI',11);$card.Padding=New-Object Windows.Forms.Padding(24);$pHome.Controls.Add($card)
$start=New-Object Windows.Forms.Button;$start.Text=$(T 'Start Device Scan' 'بدء فحص الجهاز');$start.Size=New-Object Drawing.Size(190,45);$start.Location=New-Object Drawing.Point(28,380);$start.BackColor=$C.Blue;$start.ForeColor=[Drawing.Color]::White;$start.FlatStyle='Flat';$start.FlatAppearance.BorderSize=0;$pHome.Controls.Add($start)

Header $pScan 'Device Scan' 'فحص الجهاز' 'Hardware, GPU and storage details.' 'معلومات الجهاز وكرت الشاشة والتخزين.'
$scanBox=New-Object Windows.Forms.TextBox;$scanBox.Multiline=$true;$scanBox.ReadOnly=$true;$scanBox.ScrollBars='Vertical';$scanBox.Location=New-Object Drawing.Point(28,105);$scanBox.Size=New-Object Drawing.Size(900,470);$scanBox.BackColor=[Drawing.Color]::FromArgb(7,11,17);$scanBox.ForeColor=$C.Text;$scanBox.Font=New-Object Drawing.Font('Consolas',10);$pScan.Controls.Add($scanBox)
$again=New-Object Windows.Forms.Button;$again.Text=$(T 'Rescan' 'إعادة الفحص');$again.Size=New-Object Drawing.Size(140,40);$again.Location=New-Object Drawing.Point(28,595);$again.BackColor=$C.Panel2;$again.ForeColor=$C.Text;$again.FlatStyle='Flat';$pScan.Controls.Add($again)

Header $pOpt 'Optimization' 'تحسين النظام' 'Choose only the changes you want.' 'اختر فقط التعديلات التي تريدها.'
$of=New-Object Windows.Forms.FlowLayoutPanel;$of.Location=New-Object Drawing.Point(28,105);$of.Size=New-Object Drawing.Size(900,475);$of.AutoScroll=$true;$of.FlowDirection='TopDown';$of.WrapContents=$false;$of.BackColor=$C.BG;$pOpt.Controls.Add($of)
$oc=@{}
foreach($o in $Opts){
 $c=New-Object Windows.Forms.CheckBox;$c.Text=$(T $o.en $o.ar);$c.Tag=$o;$c.Width=850;$c.Height=36;$c.ForeColor=$C.Text;$c.BackColor=$C.Panel;$c.Font=New-Object Drawing.Font('Segoe UI Semibold',10);$of.Controls.Add($c);$oc[$o.k]=$c
}
$apply=New-Object Windows.Forms.Button;$apply.Text=$(T 'Review & Apply' 'مراجعة وتطبيق');$apply.Size=New-Object Drawing.Size(180,42);$apply.Location=New-Object Drawing.Point(28,600);$apply.BackColor=$C.Blue;$apply.ForeColor=[Drawing.Color]::White;$apply.FlatStyle='Flat';$pOpt.Controls.Add($apply)

Header $pApps 'Optional Apps' 'التطبيقات الاختيارية' 'Select apps to install with WinGet.' 'حدد التطبيقات لتثبيتها باستخدام WinGet.'
$af=New-Object Windows.Forms.FlowLayoutPanel;$af.Location=New-Object Drawing.Point(28,105);$af.Size=New-Object Drawing.Size(900,430);$af.AutoScroll=$true;$af.FlowDirection='TopDown';$af.WrapContents=$false;$af.BackColor=$C.BG;$pApps.Controls.Add($af)
$g=GPU;$gn=if($g){$g.Name}else{'Not detected'}
$gl=New-Object Windows.Forms.Label;$gl.Text=$(T "Detected GPU: $gn" "كرت الشاشة المكتشف: $gn";$gl.ForeColor=$C.Green;$gl.AutoSize=$true;$af.Controls.Add($gl))
$defs=@(
 @{n='Discord';id='Discord.Discord'},
 @{n='Google Chrome';id='Google.Chrome'},
 @{n='Brave Browser';id='Brave.Brave'},
 @{n='Parsec';id='Parsec.Parsec'}
)
if($gn -match 'NVIDIA|GeForce'){$defs+=@{n='NVIDIA App';id='Nvidia.NVIDIAApp'}}
elseif($gn -match 'AMD|Radeon'){$defs+=@{n='AMD Software: Adrenalin Edition';id='AMD.AMDSoftware'}}
$checks=@{}
foreach($a in $defs){$c=New-Object Windows.Forms.CheckBox;$c.Text=$a.n;$c.Tag=$a;$c.Width=850;$c.Height=38;$c.ForeColor=$C.Text;$c.BackColor=$C.Panel;$c.Font=New-Object Drawing.Font('Segoe UI Semibold',10);$af.Controls.Add($c);$checks[$a.n]=$c}
$install=New-Object Windows.Forms.Button;$install.Text=$(T 'Review & Install' 'مراجعة وتثبيت');$install.Size=New-Object Drawing.Size(180,42);$install.Location=New-Object Drawing.Point(28,565);$install.BackColor=$C.Blue;$install.ForeColor=[Drawing.Color]::White;$install.FlatStyle='Flat';$pApps.Controls.Add($install)
$wu=New-Object Windows.Forms.Button;$wu.Text=$(T 'Check Windows Update' 'فحص تحديثات Windows');$wu.Size=New-Object Drawing.Size(190,42);$wu.Location=New-Object Drawing.Point(225,565);$wu.BackColor=$C.Panel2;$wu.ForeColor=$C.Text;$wu.FlatStyle='Flat';$pApps.Controls.Add($wu)
$drv=New-Object Windows.Forms.Button;$drv.Text=$(T 'Check Hardware Drivers' 'فحص التعريفات');$drv.Size=New-Object Drawing.Size(180,42);$drv.Location=New-Object Drawing.Point(430,565);$drv.BackColor=$C.Panel2;$drv.ForeColor=$C.Text;$drv.FlatStyle='Flat';$pApps.Controls.Add($drv)

Header $pRes 'Results' 'النتائج' 'Applied, skipped and error items.' 'ما تم تطبيقه أو تخطيه أو فشل فيه.'
$grid=New-Object Windows.Forms.DataGridView;$grid.Location=New-Object Drawing.Point(28,105);$grid.Size=New-Object Drawing.Size(900,475);$grid.ReadOnly=$true;$grid.AllowUserToAddRows=$false;$grid.AutoSizeColumnsMode='Fill';$grid.BackgroundColor=$C.Panel;$grid.RowHeadersVisible=$false;$pRes.Controls.Add($grid)
$save=New-Object Windows.Forms.Button;$save.Text=$(T 'Save Report' 'حفظ التقرير');$save.Size=New-Object Drawing.Size(150,42);$save.Location=New-Object Drawing.Point(28,600);$save.BackColor=$C.Panel2;$save.ForeColor=$C.Text;$save.FlatStyle='Flat';$pRes.Controls.Add($save)

function RefreshGrid{$grid.DataSource=$null;$grid.DataSource=@($Results)}
function Confirm($title,$msg){[Windows.Forms.MessageBox]::Show($msg,$title,[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning)-eq 'Yes'}

$home.Add_Click({Show Home});$scan.Add_Click({Show Scan;Scan});$opt.Add_Click({Show Opt});$apps.Add_Click({Show Apps});$res.Add_Click({Show Results;RefreshGrid})
$start.Add_Click({Show Scan;Scan});$again.Add_Click({Scan})

$apply.Add_Click({
 $sel=$Opts|?{$oc[$_.k].Checked}
 if(!$sel){[Windows.Forms.MessageBox]::Show($(T 'Select at least one optimization.' 'حدد تعديلًا واحدًا على الأقل.'))|Out-Null;return}
 $list=($sel|%{'• '+($(T $_.en $_.ar))})-join "`r`n"
 if(Confirm ($(T 'Confirm changes' 'تأكيد التعديلات')) ($(T "The following changes will be applied:`r`n`r`n$list`r`n`r`nContinue?" "سيتم تطبيق التعديلات التالية:`r`n`r`n$list`r`n`r`nهل تريد المتابعة؟"))){
  foreach($o in $sel){Safe (T $o.en $o.ar) $o.a}
  try{Stop-Process explorer -Force -EA SilentlyContinue;Start-Sleep -m 500;Start-Process explorer.exe}catch{}
  RefreshGrid
 }
})

$install.Add_Click({
 $sel=@($checks.Values|?{$_.Checked}|%{$_.Tag})
 if(!$sel){[Windows.Forms.MessageBox]::Show($(T 'Select an app.' 'حدد تطبيقًا واحدًا على الأقل.'))|Out-Null;return}
 $list=($sel|%{'• '+$_.n})-join "`r`n"
 if(Confirm ($(T 'Confirm installation' 'تأكيد التثبيت')) ($(T "WinGet will install:`r`n`r`n$list`r`n`r`nContinue?" "سيتم تثبيت:`r`n`r`n$list`r`n`r`nهل تريد المتابعة؟"))){
  foreach($a in $sel){
   try{
    if(!(Get-Command winget -EA SilentlyContinue)){throw 'WinGet is not available'}
    $p=Start-Process winget.exe -ArgumentList @('install','--id',$a.id,'--exact','--accept-source-agreements','--accept-package-agreements') -Wait -PassThru -WindowStyle Hidden
    if($p.ExitCode -eq 0){Log 'Apps' $a.n 'SUCCESS'}else{Log 'Apps' $a.n 'ERROR' "WinGet exit code $($p.ExitCode)"}
   }catch{Log 'Apps' $a.n 'ERROR' $_.Exception.Message}
  }
  RefreshGrid
 }
})

$wu.Add_Click({
 try{if(Get-Command usoclient.exe -EA SilentlyContinue){Start-Process usoclient.exe 'StartScan' -WindowStyle Hidden;Log 'Windows Update' 'Update scan requested' 'SUCCESS'}else{Log 'Windows Update' 'Update scan' 'SKIPPED' 'Update client unavailable'}}catch{Log 'Windows Update' 'Update scan' 'ERROR' $_.Exception.Message}
 RefreshGrid
})
$drv.Add_Click({
 try{
  $d=Get-CimInstance Win32_PnPSignedDriver|?{$_.DeviceName -and $_.DriverVersion}|?{$_.DeviceName -match 'NVIDIA|AMD|Radeon|Intel|Realtek|Wi-Fi|Wireless|Ethernet|Audio|Bluetooth|Chipset'}|select DeviceName,Manufacturer,DriverVersion,DriverDate
  [Windows.Forms.MessageBox]::Show(($d|Format-Table -AutoSize|Out-String),($(T 'Hardware drivers' 'تعريفات الجهاز')))|Out-Null
  Log 'Drivers' 'Hardware driver inventory' 'SUCCESS'
 }catch{Log 'Drivers' 'Hardware driver inventory' 'ERROR' $_.Exception.Message}
 RefreshGrid
})
$save.Add_Click({
 $s=New-Object Windows.Forms.SaveFileDialog;$s.Filter='Text files (*.txt)|*.txt';$s.FileName="Windows11_Gaming_Optimizer_Report_$(Get-Date -f yyyyMMdd_HHmmss).txt"
 if($s.ShowDialog()-eq 'OK'){$Results|Format-Table -AutoSize|Out-String|Set-Content $s.FileName -Encoding UTF8;[Windows.Forms.MessageBox]::Show($(T 'Report saved.' 'تم حفظ التقرير.'))|Out-Null}
})
$lang.Add_SelectedIndexChanged({
 $script:Lang=if($lang.SelectedIndex -eq 1){'ar'}else{'en'}
 [Windows.Forms.MessageBox]::Show($(T 'Restart the script after changing language for the complete translated interface.' 'أعد تشغيل السكربت بعد تغيير اللغة لتحديث الواجهة بالكامل.'))|Out-Null
})
$form.Add_Shown({
 if(!(Admin)){[Windows.Forms.MessageBox]::Show($(T 'Run PowerShell as Administrator for system changes.' 'شغّل PowerShell كمسؤول حتى تعمل تعديلات النظام.'))|Out-Null}
})
Show Home
[void]$form.ShowDialog()
