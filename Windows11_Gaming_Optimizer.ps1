#requires -Version 5.1
<#
    Windows 11 Gaming Optimizer
    ----------------------------
    v1.4.2 - Scan | Optimize | Optional Apps | Results
    Safe-first: no file deletion, no disk formatting, nothing touched
    without explicit user selection + confirmation.
#>

# ============================================================
# REGION: Assemblies
# ============================================================
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ============================================================
# REGION: Global state
# ============================================================
$script:Results = New-Object System.Collections.ObjectModel.ObservableCollection[PSObject]

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Add-ResultLog {
    param(
        [string]$Category,
        [string]$Item,
        [ValidateSet('OK','SKIPPED','ERROR')][string]$Status,
        [string]$Message = ''
    )
    $icon = switch ($Status) {
        'OK'      { '✅' }
        'SKIPPED' { '⏭️' }
        'ERROR'   { '❌' }
    }
    $script:Results.Add([PSCustomObject]@{
        Icon     = $icon
        Category = $Category
        Item     = $Item
        Status   = $Status
        Message  = $Message
    })
}

# ============================================================
# REGION: XAML (UI definition)
# ============================================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows 11 Gaming Optimizer" Height="720" Width="1080"
        WindowStartupLocation="CenterScreen" Background="#0B1220"
        FontFamily="Segoe UI">
    <Window.Resources>
        <SolidColorBrush x:Key="Accent" Color="#3B82F6"/>
        <SolidColorBrush x:Key="Sidebar" Color="#0F1729"/>
        <SolidColorBrush x:Key="Panel" Color="#111A2E"/>
        <SolidColorBrush x:Key="Border" Color="#1E293B"/>
        <SolidColorBrush x:Key="TextMuted" Color="#94A3B8"/>

        <Style x:Key="NavBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#CBD5E1"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Padding" Value="14,10"/>
            <Setter Property="HorizontalAlignment" Value="Stretch"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Margin" Value="8,3"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#16233D"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="PrimaryBtn" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource Accent}"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="16,10"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="SecondaryBtn" TargetType="Button" BasedOn="{StaticResource PrimaryBtn}">
            <Setter Property="Background" Value="#1E293B"/>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Margin" Value="0,6"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="230"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- SIDEBAR -->
        <Border Grid.Column="0" Background="{StaticResource Sidebar}">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="20,24,20,10">
                    <TextBlock Text="🛠️" FontSize="30" HorizontalAlignment="Left"/>
                    <TextBlock Text="Gaming Optimizer" Foreground="White" FontSize="15" FontWeight="Bold" Margin="0,8,0,0"/>
                    <TextBlock Text="v1.4.2" Foreground="{StaticResource Accent}" FontSize="11" Margin="0,2,0,0"/>
                </StackPanel>

                <StackPanel Grid.Row="1" Margin="0,10,0,0">
                    <Button x:Name="btnHome" Content="🏠  Home" Style="{StaticResource NavBtn}"/>
                    <Button x:Name="btnScan" Content="🖥️  Device Scan" Style="{StaticResource NavBtn}"/>
                    <Button x:Name="btnOptimize" Content="⚙️  Optimization" Style="{StaticResource NavBtn}"/>
                    <Button x:Name="btnApps" Content="📦  Optional Apps" Style="{StaticResource NavBtn}"/>
                    <Button x:Name="btnResults" Content="📊  Results" Style="{StaticResource NavBtn}"/>
                </StackPanel>

                <StackPanel Grid.Row="2" Margin="20,10,20,20">
                    <TextBlock Text="Language" Foreground="{StaticResource TextMuted}" FontSize="11" Margin="0,0,0,4"/>
                    <ComboBox x:Name="cmbLang" SelectedIndex="0">
                        <ComboBoxItem Content="English"/>
                        <ComboBoxItem Content="العربية"/>
                    </ComboBox>
                    <StackPanel Orientation="Horizontal" Margin="0,14,0,0">
                        <TextBlock Text="🛡️ " Foreground="{StaticResource TextMuted}" FontSize="11"/>
                        <TextBlock Text="No background service&#10;Safe-first" Foreground="{StaticResource TextMuted}" FontSize="11" TextWrapping="Wrap"/>
                    </StackPanel>
                </StackPanel>
            </Grid>
        </Border>

        <!-- CONTENT -->
        <Grid Grid.Column="1" Margin="34,26,34,26">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <TextBlock x:Name="txtPageTitle" Grid.Row="0" Text="Home" Foreground="White" FontSize="24" FontWeight="Bold" Margin="0,0,0,18"/>

            <Grid Grid.Row="1">

                <!-- HOME PAGE -->
                <StackPanel x:Name="pageHome" Visibility="Visible">
                    <Border Background="{StaticResource Panel}" CornerRadius="10" Padding="24" BorderBrush="{StaticResource Border}" BorderThickness="1">
                        <StackPanel>
                            <TextBlock Text="Prepares a fresh Windows 11 install for gaming." Foreground="#E2E8F0" FontSize="15" TextWrapping="Wrap"/>
                            <TextBlock Foreground="{StaticResource TextMuted}" FontSize="13" Margin="0,10,0,0" TextWrapping="Wrap"
                                       Text="Scan your device, choose the optimizations and optional apps you want, review every result — nothing is applied without your confirmation."/>
                            <StackPanel Orientation="Horizontal" Margin="0,20,0,0">
                                <Button x:Name="btnGoScan" Content="🔍 Start Device Scan" Style="{StaticResource PrimaryBtn}" Margin="0,0,10,0"/>
                                <Button x:Name="btnGoOptimize" Content="⚙️ Go to Optimization" Style="{StaticResource SecondaryBtn}"/>
                            </StackPanel>
                        </StackPanel>
                    </Border>

                    <Border Background="{StaticResource Panel}" CornerRadius="10" Padding="20" BorderBrush="{StaticResource Border}" BorderThickness="1" Margin="0,16,0,0">
                        <StackPanel>
                            <TextBlock Text="This tool never does automatically:" Foreground="White" FontWeight="SemiBold" Margin="0,0,0,8"/>
                            <TextBlock Foreground="{StaticResource TextMuted}" FontSize="12.5" TextWrapping="Wrap"
Text="❌ Delete personal files    ❌ Format any disk    ❌ Touch unallocated space&#10;❌ Create backups    ❌ Run background services&#10;❌ Remove Snipping Tool or Xbox app    ❌ Disable camera/microphone permissions&#10;❌ Install optional apps without your selection"/>
                        </StackPanel>
                    </Border>
                </StackPanel>

                <!-- DEVICE SCAN PAGE -->
                <Grid x:Name="pageScan" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Border Grid.Row="0" Background="#0D1526" CornerRadius="10" BorderBrush="{StaticResource Border}" BorderThickness="1" Padding="18">
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <RichTextBox x:Name="rtbScan" Background="Transparent" Foreground="#CBD5E1" BorderThickness="0"
                                         IsReadOnly="True" FontFamily="Consolas" FontSize="13" IsDocumentEnabled="True"/>
                        </ScrollViewer>
                    </Border>
                    <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,14,0,0">
                        <Button x:Name="btnRefreshScan" Content="🔄 Refresh Scan" Style="{StaticResource PrimaryBtn}" Margin="0,0,10,0"/>
                        <Button x:Name="btnWindowsUpdate" Content="🪟 Open Windows Update" Style="{StaticResource SecondaryBtn}"/>
                    </StackPanel>
                </Grid>

                <!-- OPTIMIZATION PAGE -->
                <Grid x:Name="pageOptimize" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto">
                        <StackPanel>
                            <Border Background="{StaticResource Panel}" CornerRadius="10" Padding="20" BorderBrush="{StaticResource Border}" BorderThickness="1">
                                <StackPanel>
                                    <TextBlock Text="Choose what to apply — nothing runs until you press Apply and confirm." Foreground="{StaticResource TextMuted}" FontSize="12.5" Margin="0,0,0,12" TextWrapping="Wrap"/>
                                    <CheckBox x:Name="chkRemoveOneDrive" Content="🗑️ Remove OneDrive"/>
                                    <CheckBox x:Name="chkRemoveTeams" Content="🗑️ Remove Microsoft Teams"/>
                                    <CheckBox x:Name="chkDisableWidgets" Content="⚙️ Disable Widgets"/>
                                    <CheckBox x:Name="chkDisableTaskView" Content="⚙️ Disable Task View button"/>
                                    <CheckBox x:Name="chkDisableRecall" Content="⚙️ Disable Recall"/>
                                </StackPanel>
                            </Border>
                            <Border Background="{StaticResource Panel}" CornerRadius="10" Padding="20" BorderBrush="{StaticResource Border}" BorderThickness="1" Margin="0,14,0,0">
                                <StackPanel>
                                    <TextBlock Text="Always kept, no matter what:" Foreground="White" FontWeight="SemiBold" Margin="0,0,0,8"/>
                                    <TextBlock Foreground="{StaticResource TextMuted}" FontSize="12.5" TextWrapping="Wrap"
                                               Text="🛡️ Snipping Tool    🎮 Xbox app    🎙️ Camera / Microphone permissions"/>
                                </StackPanel>
                            </Border>
                        </StackPanel>
                    </ScrollViewer>
                    <Button Grid.Row="1" x:Name="btnApplyOptimizations" Content="✅ Apply Selected" Style="{StaticResource PrimaryBtn}" HorizontalAlignment="Left" Margin="0,14,0,0"/>
                </Grid>

                <!-- OPTIONAL APPS PAGE -->
                <Grid x:Name="pageApps" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Border Grid.Row="0" Background="{StaticResource Panel}" CornerRadius="10" Padding="20" BorderBrush="{StaticResource Border}" BorderThickness="1" VerticalAlignment="Top">
                        <StackPanel>
                            <TextBlock Text="Installed via winget — only the apps you check are installed." Foreground="{StaticResource TextMuted}" FontSize="12.5" Margin="0,0,0,12" TextWrapping="Wrap"/>
                            <CheckBox x:Name="chkChrome" Content="🌐 Google Chrome"/>
                            <CheckBox x:Name="chkBrave" Content="🦁 Brave"/>
                            <CheckBox x:Name="chkDiscord" Content="💬 Discord"/>
                            <CheckBox x:Name="chkParsec" Content="🎮 Parsec"/>
                        </StackPanel>
                    </Border>
                    <Button Grid.Row="1" x:Name="btnInstallApps" Content="📦 Install Selected" Style="{StaticResource PrimaryBtn}" HorizontalAlignment="Left" Margin="0,14,0,0"/>
                </Grid>

                <!-- RESULTS PAGE -->
                <Grid x:Name="pageResults" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Border Grid.Row="0" Background="{StaticResource Panel}" CornerRadius="10" BorderBrush="{StaticResource Border}" BorderThickness="1" Padding="4">
                        <ListView x:Name="lvResults" Background="Transparent" BorderThickness="0" Foreground="#E2E8F0">
                            <ListView.View>
                                <GridView>
                                    <GridViewColumn Header="" Width="34" DisplayMemberBinding="{Binding Icon}"/>
                                    <GridViewColumn Header="Category" Width="150" DisplayMemberBinding="{Binding Category}"/>
                                    <GridViewColumn Header="Item" Width="200" DisplayMemberBinding="{Binding Item}"/>
                                    <GridViewColumn Header="Status" Width="90" DisplayMemberBinding="{Binding Status}"/>
                                    <GridViewColumn Header="Message" Width="380" DisplayMemberBinding="{Binding Message}"/>
                                </GridView>
                            </ListView.View>
                        </ListView>
                    </Border>
                    <Button Grid.Row="1" x:Name="btnClearResults" Content="🧹 Clear Log" Style="{StaticResource SecondaryBtn}" HorizontalAlignment="Left" Margin="0,14,0,0"/>
                </Grid>

            </Grid>
        </Grid>
    </Grid>
</Window>
"@

# ============================================================
# REGION: Load window
# ============================================================
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Named controls
$ctrl = @{}
foreach ($name in @(
    'btnHome','btnScan','btnOptimize','btnApps','btnResults','cmbLang',
    'txtPageTitle','pageHome','pageScan','pageOptimize','pageApps','pageResults',
    'btnGoScan','btnGoOptimize','rtbScan','btnRefreshScan','btnWindowsUpdate',
    'chkRemoveOneDrive','chkRemoveTeams','chkDisableWidgets','chkDisableTaskView','chkDisableRecall','btnApplyOptimizations',
    'chkChrome','chkBrave','chkDiscord','chkParsec','btnInstallApps',
    'lvResults','btnClearResults'
)) { $ctrl[$name] = $window.FindName($name) }

$ctrl.lvResults.ItemsSource = $script:Results

# ============================================================
# REGION: Navigation
# ============================================================
$pages = @{
    Home      = @{ Panel = $ctrl.pageHome;     Title = 'Home' }
    Scan      = @{ Panel = $ctrl.pageScan;     Title = 'Device Scan' }
    Optimize  = @{ Panel = $ctrl.pageOptimize; Title = 'Optimization' }
    Apps      = @{ Panel = $ctrl.pageApps;     Title = 'Optional Apps' }
    Results   = @{ Panel = $ctrl.pageResults;  Title = 'Results' }
}

function Show-Page {
    param([string]$Name)
    foreach ($p in $pages.Values) { $p.Panel.Visibility = 'Collapsed' }
    $pages[$Name].Panel.Visibility = 'Visible'
    $ctrl.txtPageTitle.Text = $pages[$Name].Title
    if ($Name -eq 'Scan' -and $ctrl.rtbScan.Document.Blocks.Count -eq 0) { Update-ScanDisplay }
}

$ctrl.btnHome.Add_Click({ Show-Page 'Home' })
$ctrl.btnScan.Add_Click({ Show-Page 'Scan' })
$ctrl.btnOptimize.Add_Click({ Show-Page 'Optimize' })
$ctrl.btnApps.Add_Click({ Show-Page 'Apps' })
$ctrl.btnResults.Add_Click({ Show-Page 'Results' })
$ctrl.btnGoScan.Add_Click({ Show-Page 'Scan' })
$ctrl.btnGoOptimize.Add_Click({ Show-Page 'Optimize' })

# ============================================================
# REGION: Device Scan
# ============================================================
function Get-DiskSummary {
    $rows = @()
    try {
        $disks = Get-Disk | Sort-Object Number
        foreach ($d in $disks) {
            $partitions = Get-Partition -DiskNumber $d.Number -ErrorAction SilentlyContinue
            $usedB = 0; $freeB = 0; $allocB = 0
            foreach ($p in $partitions) {
                $vol = $p | Get-Volume -ErrorAction SilentlyContinue
                if ($vol) {
                    $freeB += $vol.SizeRemaining
                    $usedB += ($vol.Size - $vol.SizeRemaining)
                    $allocB += $vol.Size
                } else { $allocB += $p.Size }
            }
            $unallocB = $d.Size - $allocB
            if ($unallocB -lt 0) { $unallocB = 0 }
            $rows += [PSCustomObject]@{
                Disk        = $d.Number
                Model       = $d.FriendlyName
                Type        = $d.BusType
                TotalGB     = [math]::Round($d.Size/1GB,2)
                UsedGB      = [math]::Round($usedB/1GB,2)
                FreeGB      = [math]::Round($freeB/1GB,2)
                UnallocGB   = [math]::Round($unallocB/1GB,2)
            }
        }
    } catch { }
    return $rows
}

function Add-Heading($doc, [string]$text) {
    $p = New-Object System.Windows.Documents.Paragraph
    $p.Margin = '0,10,0,2'
    $run = New-Object System.Windows.Documents.Run($text)
    $run.Foreground = [System.Windows.Media.Brushes]::DeepSkyBlue
    $run.FontWeight = 'Bold'
    $p.Inlines.Add($run)
    $doc.Blocks.Add($p)
}

function Add-Line($doc, [string]$text) {
    $p = New-Object System.Windows.Documents.Paragraph
    $p.Margin = '0,0,0,0'
    $run = New-Object System.Windows.Documents.Run($text)
    $p.Inlines.Add($run)
    $doc.Blocks.Add($p)
}

function Update-ScanDisplay {
    $doc = New-Object System.Windows.Documents.FlowDocument
    $doc.PagePadding = '0'

    try {
        $os     = Get-CimInstance Win32_OperatingSystem
        $cs     = Get-CimInstance Win32_ComputerSystem
        $cpu    = Get-CimInstance Win32_Processor | Select-Object -First 1
        $board  = Get-CimInstance Win32_BaseBoard
        $bios   = Get-CimInstance Win32_BIOS
        $ram    = Get-CimInstance Win32_PhysicalMemory
        $gpu    = Get-CimInstance Win32_VideoController | Select-Object -First 1

        Add-Heading $doc 'System'
        Add-Line $doc "OS: $($os.Caption) | Build: $($os.BuildNumber)"
        Add-Line $doc "Computer Name: $($cs.Name)"
        Add-Line $doc "User: $($env:USERNAME)"

        Add-Heading $doc 'CPU'
        Add-Line $doc "$($cpu.Name)"
        Add-Line $doc "Cores: $($cpu.NumberOfCores) | Threads: $($cpu.NumberOfLogicalProcessors)"
        Add-Line $doc "Base: $([math]::Round($cpu.MaxClockSpeed/1000,2)) GHz"

        Add-Heading $doc 'Motherboard'
        Add-Line $doc "Manufacturer: $($board.Manufacturer)"
        Add-Line $doc "Model: $($board.Product)"

        Add-Heading $doc 'BIOS'
        Add-Line $doc "Version: $($bios.SMBIOSBIOSVersion) | Date: $($bios.ReleaseDate)"

        Add-Heading $doc 'Memory (RAM)'
        $totalRam = [math]::Round(($ram | Measure-Object Capacity -Sum).Sum/1GB,2)
        Add-Line $doc "Installed: $totalRam GB | Modules: $($ram.Count)"

        Add-Heading $doc 'GPU'
        Add-Line $doc "$($gpu.Name)"
        Add-Line $doc "Driver: $($gpu.DriverVersion) | Driver Date: $($gpu.DriverDate)"

        Add-Heading $doc 'Storage (Disks)'
        $disks = Get-DiskSummary
        foreach ($row in $disks) {
            Add-Line $doc "Disk $($row.Disk) | $($row.Model) | $($row.Type) | Total: $($row.TotalGB) GB | Used: $($row.UsedGB) GB | Free: $($row.FreeGB) GB | Unallocated: $($row.UnallocGB) GB"
        }

        Add-Heading $doc 'Note'
        $noteP = New-Object System.Windows.Documents.Paragraph
        $noteRun = New-Object System.Windows.Documents.Run('Unallocated space is only detected and displayed. No disks will be formatted.')
        $noteRun.Foreground = [System.Windows.Media.Brushes]::LimeGreen
        $noteP.Inlines.Add($noteRun)
        $doc.Blocks.Add($noteP)
    }
    catch {
        Add-Line $doc "Scan error: $($_.Exception.Message)"
    }

    $ctrl.rtbScan.Document = $doc
}

$ctrl.btnRefreshScan.Add_Click({ Update-ScanDisplay })
$ctrl.btnWindowsUpdate.Add_Click({ Start-Process 'ms-settings:windowsupdate' })

# ============================================================
# REGION: Optimization actions
# ============================================================
function Invoke-RemoveOneDrive {
    try {
        $oneDrive = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
        if (-not (Test-Path $oneDrive)) { $oneDrive = "$env:SystemRoot\System32\OneDriveSetup.exe" }
        if (Test-Path $oneDrive) {
            Start-Process $oneDrive -ArgumentList '/uninstall' -NoNewWindow -Wait
            Add-ResultLog 'Optimization' 'OneDrive' 'OK' 'Uninstalled.'
        } else {
            Add-ResultLog 'Optimization' 'OneDrive' 'SKIPPED' 'OneDrive not found on this system.'
        }
    } catch { Add-ResultLog 'Optimization' 'OneDrive' 'ERROR' $_.Exception.Message }
}

function Invoke-RemoveTeams {
    try {
        $pkg = Get-AppxPackage -AllUsers *MicrosoftTeams* -ErrorAction SilentlyContinue
        if ($pkg) {
            $pkg | Remove-AppxPackage -ErrorAction Stop
            Add-ResultLog 'Optimization' 'Microsoft Teams' 'OK' 'Removed.'
        } else {
            Add-ResultLog 'Optimization' 'Microsoft Teams' 'SKIPPED' 'Not installed as an app package.'
        }
    } catch { Add-ResultLog 'Optimization' 'Microsoft Teams' 'ERROR' $_.Exception.Message }
}

function Invoke-DisableWidgets {
    try {
        $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name 'TaskbarDa' -Value 0 -Type DWord
        Add-ResultLog 'Optimization' 'Widgets' 'OK' 'Taskbar widget icon disabled.'
    } catch { Add-ResultLog 'Optimization' 'Widgets' 'ERROR' $_.Exception.Message }
}

function Invoke-DisableTaskView {
    try {
        $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name 'ShowTaskViewButton' -Value 0 -Type DWord
        Add-ResultLog 'Optimization' 'Task View button' 'OK' 'Taskbar Task View button disabled.'
    } catch { Add-ResultLog 'Optimization' 'Task View button' 'ERROR' $_.Exception.Message }
}

function Invoke-DisableRecall {
    try {
        $path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
        if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name 'DisableAIDataAnalysis' -Value 1 -Type DWord
        Add-ResultLog 'Optimization' 'Recall' 'OK' 'Recall (AI snapshots) disabled via policy.'
    } catch { Add-ResultLog 'Optimization' 'Recall' 'ERROR' $_.Exception.Message }
}

$ctrl.btnApplyOptimizations.Add_Click({
    $selected = @()
    if ($ctrl.chkRemoveOneDrive.IsChecked) { $selected += 'Remove OneDrive' }
    if ($ctrl.chkRemoveTeams.IsChecked)    { $selected += 'Remove Microsoft Teams' }
    if ($ctrl.chkDisableWidgets.IsChecked) { $selected += 'Disable Widgets' }
    if ($ctrl.chkDisableTaskView.IsChecked){ $selected += 'Disable Task View button' }
    if ($ctrl.chkDisableRecall.IsChecked)  { $selected += 'Disable Recall' }

    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show('No optimizations selected.','Nothing to apply') | Out-Null
        return
    }

    $msg = "The following will be applied:`n`n - " + ($selected -join "`n - ") + "`n`nContinue?"
    $confirm = [System.Windows.MessageBox]::Show($msg,'Confirm Optimization','YesNo','Question')
    if ($confirm -ne 'Yes') { return }

    if (-not (Test-IsAdmin)) {
        [System.Windows.MessageBox]::Show('Not running as Administrator — some steps may fail. Consider restarting the script elevated.','Warning','OK','Warning') | Out-Null
    }

    if ($ctrl.chkRemoveOneDrive.IsChecked)  { Invoke-RemoveOneDrive }
    if ($ctrl.chkRemoveTeams.IsChecked)     { Invoke-RemoveTeams }
    if ($ctrl.chkDisableWidgets.IsChecked)  { Invoke-DisableWidgets }
    if ($ctrl.chkDisableTaskView.IsChecked) { Invoke-DisableTaskView }
    if ($ctrl.chkDisableRecall.IsChecked)   { Invoke-DisableRecall }

    Add-ResultLog 'Optimization' 'Snipping Tool' 'SKIPPED' 'Intentionally kept.'
    Add-ResultLog 'Optimization' 'Xbox app' 'SKIPPED' 'Intentionally kept.'
    Add-ResultLog 'Optimization' 'Camera / Microphone permissions' 'SKIPPED' 'Intentionally kept.'

    Show-Page 'Results'
})

# ============================================================
# REGION: Optional Apps
# ============================================================
$appMap = @{
    'Google Chrome' = 'Google.Chrome'
    'Brave'         = 'BraveSoftware.BraveBrowser'
    'Discord'       = 'Discord.Discord'
    'Parsec'        = 'Parsec.Parsec'
}

function Invoke-WingetInstall([string]$displayName, [string]$id) {
    try {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Add-ResultLog 'Optional Apps' $displayName 'ERROR' 'winget is not available on this system.'
            return
        }
        $p = Start-Process winget -ArgumentList @('install','--id',$id,'-e','--silent','--accept-package-agreements','--accept-source-agreements') -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -eq 0) {
            Add-ResultLog 'Optional Apps' $displayName 'OK' 'Installed via winget.'
        } else {
            Add-ResultLog 'Optional Apps' $displayName 'ERROR' "winget exit code $($p.ExitCode)."
        }
    } catch { Add-ResultLog 'Optional Apps' $displayName 'ERROR' $_.Exception.Message }
}

$ctrl.btnInstallApps.Add_Click({
    $selected = @()
    if ($ctrl.chkChrome.IsChecked)  { $selected += 'Google Chrome' }
    if ($ctrl.chkBrave.IsChecked)   { $selected += 'Brave' }
    if ($ctrl.chkDiscord.IsChecked) { $selected += 'Discord' }
    if ($ctrl.chkParsec.IsChecked)  { $selected += 'Parsec' }

    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show('No apps selected.','Nothing to install') | Out-Null
        return
    }

    $msg = "The following apps will be installed via winget:`n`n - " + ($selected -join "`n - ") + "`n`nContinue?"
    $confirm = [System.Windows.MessageBox]::Show($msg,'Confirm Install','YesNo','Question')
    if ($confirm -ne 'Yes') { return }

    foreach ($name in $selected) { Invoke-WingetInstall $name $appMap[$name] }

    Show-Page 'Results'
})

# ============================================================
# REGION: Results
# ============================================================
$ctrl.btnClearResults.Add_Click({ $script:Results.Clear() })

# ============================================================
# REGION: Startup
# ============================================================
$window.Add_Loaded({ Update-ScanDisplay })
$window.ShowDialog() | Out-Null
