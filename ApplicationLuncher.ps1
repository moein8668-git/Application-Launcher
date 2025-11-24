<#
# Application Launcher - Licensed under GPLv3
# IMPORTANT NOTE: This project is provided "AS IS". I may not be able to
# provide regular bug fixes, updates, or active support. Contributions
# from the community are welcomed to keep the project up-to-date.
# Copyright (C) 2025 Moein
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#>
<#
.SYNOPSIS
    Application Launcher with modern UI.
.DESCRIPTION
    Enhanced GUI for selecting and running tasks from config.json,
    supporting both sequential and parallel execution.
    Includes Select All/Unselect All controls for easy task management.
#>
# STEP 1: Load the required GUI libraries first.
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
} catch {
    [System.Windows.Forms.MessageBox]::Show("Failed to load UI components: $_", "Error")
    exit
}

# STEP 2: Now that the library is loaded, you can enable visual styles.
[System.Windows.Forms.Application]::EnableVisualStyles()


# Force the window to stay open
if ($Host.Name -eq "ConsoleHost") {
    $Host.UI.RawUI.WindowTitle = "Application Launcher - DO NOT CLOSE"
}

# Load assemblies (Redundant, but kept for robustness after initial step 1)
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
} catch {
    [System.Windows.Forms.MessageBox]::Show("Failed to load UI components: $_", "Error")
    exit
}


# Read config file (for sequential/parallel tasks)
try {
    $configPath = Join-Path $PSScriptRoot "config.json"
    # Check if config.json exists before trying to read it
    if (Test-Path $configPath) {
        $configJson = Get-Content $configPath -Raw | ConvertFrom-Json
        if (-not $configJson.sequential -or -not $configJson.parallel) {
            throw "Invalid config format - missing required sections (sequential or parallel)."
        }
    } else {
        # If config.json doesn't exist, initialize empty arrays for sequential/parallel tasks
        $configJson = @{
            sequential = @()
            parallel = @()
        }
        [System.Windows.Forms.MessageBox]::Show("config.json not found. Sequential and Parallel tasks will be empty.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Config Error: $_", "Error")
    if ($Host.Name -eq "ConsoleHost") {
        Write-Host "Press any key to exit..."
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    }
    exit
}




# ===== Modern UI Enhancements =====
$form = New-Object System.Windows.Forms.Form
# Load icon from an external .ico file in the script's directory
$iconFileName = "launcher.ico" # <--- IMPORTANT: Change this to your icon's filename if different
$iconPath = Join-Path $PSScriptRoot $iconFileName

if (Test-Path $iconPath) {
    try {
        $form.Icon = New-Object System.Drawing.Icon($iconPath)
    } catch {
        Write-Warning "Failed to load application icon from '$iconPath': $_"
    }
} else {
    Write-Warning "Icon file '$iconFileName' not found in script directory. Application will use default icon."
}
$form.Text = "Application Launcher"
$form.Size = New-Object System.Drawing.Size(800,700)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.MinimizeBox = $true
$form.MaximizeBox = $true
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle

# Modern color scheme
$primaryColor = [System.Drawing.Color]::FromArgb(0, 123, 255)
$successColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
$warningColor = [System.Drawing.Color]::FromArgb(255, 193, 7)
$dangerColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
$lightGray = [System.Drawing.Color]::FromArgb(248, 249, 250)
$buttonTextColor = [System.Drawing.Color]::White
$buttonBackColor = $primaryColor

# Header panel
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = "Top"
$headerPanel.Height = 60
$headerPanel.BackColor = $primaryColor

$headerLabel = New-Object System.Windows.Forms.Label
$headerLabel.Text = "APPLICATION LAUNCHER"
$headerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$headerLabel.ForeColor = [System.Drawing.Color]::White
$headerLabel.AutoSize = $true
$headerLabel.Location = New-Object System.Drawing.Point(20, 15)
$headerPanel.Controls.Add($headerLabel)


# --- Auto-Start Countdown Variables ---
$script:CountdownTimer = New-Object System.Windows.Forms.Timer
$script:CountdownSeconds = 30 
$script:InitialCountdownValue = $script:CountdownSeconds
$script:CountdownActive = $true

# --- Countdown Label UI Element ---
$countdownLabel = New-Object System.Windows.Forms.Label
$countdownLabel.Text = "Auto-Start in $($script:CountdownSeconds)s"
$countdownLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$countdownLabel.ForeColor = [System.Drawing.Color]::LightGreen
$countdownLabel.AutoSize = $true
$countdownLabel.Location = New-Object System.Drawing.Point(600, 18)
$countdownLabel.Cursor = [System.Windows.Forms.Cursors]::Hand 
$headerPanel.Controls.Add($countdownLabel)

# --- Countdown Label Click Event ---
$countdownLabel.Add_Click({
    if ($script:CountdownActive) {
        $script:StopCountdown.Invoke()
    } else {
        $script:ResumeCountdown.Invoke()
    }
})

# --- Timer Tick Handler ---
$script:CountdownTimer.Interval = 1000 # 1 second interval
$script:CountdownTimer.Add_Tick({
    if ($script:CountdownActive -and $script:CountdownSeconds -gt 0) {
        $script:CountdownSeconds--
        $countdownLabel.Text = "Auto-Start in $($script:CountdownSeconds)s"
        $countdownLabel.ForeColor = [System.Drawing.Color]::FromArgb(77, 255, 0) # green during countdown
    } elseif ($script:CountdownActive -and $script:CountdownSeconds -eq 0) {
        # Countdown reached zero - trigger the run button
        $script:CountdownTimer.Stop()
        $countdownLabel.Text = "INSTALLING..."
        $countdownLabel.ForeColor = [System.Drawing.Color]::FromArgb(22, 54, 29) # Green
        
        # Invoke the Run Button Click Handler
        $runButton.PerformClick()
    }
})

# --- Function to Stop/Reset the Timer ---
$script:StopCountdown = {
    if ($script:CountdownActive) {
        $countdownLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $script:CountdownActive = $false
        $script:CountdownTimer.Stop()
        $countdownLabel.Text = "Paused(Click to Resume)"
        $countdownLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 193, 7) # Warning Color
    }
}

# --- Function to Resume the Timer (and restart the count) ---
$script:ResumeCountdown = {
    if (-not $script:CountdownActive) {
        $countdownLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $countdownLabel.ForeColor = [System.Drawing.Color]::FromArgb(77, 255, 0)
        $script:CountdownActive = $true
        $script:CountdownSeconds = $script:InitialCountdownValue # Reset to initial value
        $countdownLabel.Text = "Auto-Start in $($script:CountdownSeconds)s"
        $script:CountdownTimer.Start()
    }
}


# Main container
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Dock = "Fill"
$mainPanel.BackColor = $lightGray
$mainPanel.Padding = New-Object System.Windows.Forms.Padding(10)

# Tab control with modern styling
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Dock = "Fill"
$tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$tabControl.Appearance = [System.Windows.Forms.TabAppearance]::Normal
$tabControl.SizeMode = [System.Windows.Forms.TabSizeMode]::FillToRight

$tabControl.Add_SelectedIndexChanged({
    $script:StopCountdown.Invoke()
})

# Modern progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Dock = "Bottom"
$progressBar.Height = 25
$progressBar.Style = "Continuous"
$progressBar.BackColor = [System.Drawing.Color]::FromArgb(10, 255, 130)
$progressBar.ForeColor = $primaryColor

# Status label with better styling
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Dock = "Bottom"
$statusLabel.Height = 30
$statusLabel.TextAlign = "MiddleCenter"
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$statusLabel.BackColor = [System.Drawing.Color]::White
$statusLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

# Sequential Tasks Tab
$sequentialList = New-Object System.Windows.Forms.FlowLayoutPanel
$sequentialTab = New-Object System.Windows.Forms.TabPage
$sequentialTab.Text = " Sequential Tasks "
$sequentialTab.BackColor = $lightGray
$sequentialTab.Padding = New-Object System.Windows.Forms.Padding(5)
$sequentialList.Add_MouseWheel({ $script:StopCountdown.Invoke() })

# --- Panel for Select All/Unselect All buttons for Sequential Tab ---
$sequentialButtonPanel = New-Object System.Windows.Forms.Panel
$sequentialButtonPanel.Dock = "Top"
$sequentialButtonPanel.Height = 30
$sequentialButtonPanel.BackColor = $lightGray

$btnSequentialSelectAll = New-Object System.Windows.Forms.Button
$btnSequentialSelectAll.Text = "Select All"
$btnSequentialSelectAll.Size = New-Object System.Drawing.Size(80, 25)
$btnSequentialSelectAll.Location = New-Object System.Drawing.Point(5, 2)
$btnSequentialSelectAll.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnSequentialSelectAll.BackColor = $buttonBackColor
$btnSequentialSelectAll.ForeColor = $buttonTextColor

$btnSequentialUnselectAll = New-Object System.Windows.Forms.Button
$btnSequentialUnselectAll.Text = "Unselect All"
$btnSequentialUnselectAll.Size = New-Object System.Drawing.Size(80, 25)
$btnSequentialUnselectAll.Location = New-Object System.Drawing.Point(90, 2)
$btnSequentialUnselectAll.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnSequentialUnselectAll.BackColor = $buttonBackColor
$btnSequentialUnselectAll.ForeColor = $buttonTextColor

$sequentialButtonPanel.Controls.Add($btnSequentialSelectAll)
$sequentialButtonPanel.Controls.Add($btnSequentialUnselectAll)
# --- END Panel for Select All/Unselect All buttons ---

$sequentialList = New-Object System.Windows.Forms.FlowLayoutPanel
$sequentialList.Dock = "Fill"
$sequentialList.AutoScroll = $true
$sequentialList.BackColor = [System.Drawing.Color]::White
$sequentialList.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

# Parallel Tasks Tab
$parallelList = New-Object System.Windows.Forms.FlowLayoutPanel
$parallelTab = New-Object System.Windows.Forms.TabPage
$parallelTab.Text = " Parallel Tasks "
$parallelTab.BackColor = $lightGray
$parallelTab.Padding = New-Object System.Windows.Forms.Padding(5)
$parallelList.Add_MouseWheel({ $script:StopCountdown.Invoke() })

# --- Panel for Select All/Unselect All buttons for Parallel Tab ---
$parallelButtonPanel = New-Object System.Windows.Forms.Panel
$parallelButtonPanel.Dock = "Top"
$parallelButtonPanel.Height = 30
$parallelButtonPanel.BackColor = $lightGray

$btnParallelSelectAll = New-Object System.Windows.Forms.Button
$btnParallelSelectAll.Text = "Select All"
$btnParallelSelectAll.Size = New-Object System.Drawing.Size(80, 25)
$btnParallelSelectAll.Location = New-Object System.Drawing.Point(5, 2)
$btnParallelSelectAll.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnParallelSelectAll.BackColor = $buttonBackColor
$btnParallelSelectAll.ForeColor = $buttonTextColor


$btnParallelUnselectAll = New-Object System.Windows.Forms.Button
$btnParallelUnselectAll.Text = "Unselect All"
$btnParallelUnselectAll.Size = New-Object System.Drawing.Size(80, 25)
$btnParallelUnselectAll.Location = New-Object System.Drawing.Point(90, 2)
$btnParallelUnselectAll.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnParallelUnselectAll.BackColor = $buttonBackColor
$btnParallelUnselectAll.ForeColor = $buttonTextColor

$parallelButtonPanel.Controls.Add($btnParallelSelectAll)
$parallelButtonPanel.Controls.Add($btnParallelUnselectAll)
# --- END Panel for Select All/Unselect All buttons ---

$parallelList = New-Object System.Windows.Forms.FlowLayoutPanel
$parallelList.Dock = "Fill"
$parallelList.AutoScroll = $true
$parallelList.BackColor = [System.Drawing.Color]::White
$parallelList.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

# About Tab Definition
$aboutTab = New-Object System.Windows.Forms.TabPage
$aboutTab.Text = " About "
$aboutTab.BackColor = $lightGray
$aboutTab.Padding = New-Object System.Windows.Forms.Padding(20)

# About Content Panel (A FlowLayoutPanel for easy vertical stacking)
$aboutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$aboutPanel.Dock = "Fill"
$aboutPanel.AutoScroll = $true
$aboutPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
$aboutPanel.WrapContents = $false
$aboutPanel.Padding = New-Object System.Windows.Forms.Padding(10)
$aboutPanel.BackColor = [System.Drawing.Color]::White

# --- Content Labels ---

$aboutLabelTitle = New-Object System.Windows.Forms.Label
$aboutLabelTitle.Text = "APPLICATION LAUNCHER"
$aboutLabelTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$aboutLabelTitle.AutoSize = $true
$aboutLabelTitle.Margin = New-Object System.Windows.Forms.Padding(0, 20, 0, 10)
$aboutPanel.Controls.Add($aboutLabelTitle)

$aboutLabelVersion = New-Object System.Windows.Forms.Label
$aboutLabelVersion.Text = "Version 1.2"
$aboutLabelVersion.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$aboutLabelVersion.AutoSize = $true
$aboutLabelVersion.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 20)
$aboutPanel.Controls.Add($aboutLabelVersion)

$aboutLabelCreator = New-Object System.Windows.Forms.Label
$aboutLabelCreator.Text = "Created by: Moein" 
$aboutLabelCreator.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$aboutLabelCreator.AutoSize = $true
$aboutLabelCreator.Margin = New-Object System.Windows.Forms.Padding(0, 10, 0, 5)
$aboutPanel.Controls.Add($aboutLabelCreator)

# GitHub Link (Styled as a link)
$aboutLabelGithub = New-Object System.Windows.Forms.Label
$aboutLabelGithub.Text = "GitHub: https://github.com/moein8668-git/Application-Launcher" 
$aboutLabelGithub.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Underline)
$aboutLabelGithub.ForeColor = $primaryColor
$aboutLabelGithub.AutoSize = $true
$aboutLabelGithub.Cursor = [System.Windows.Forms.Cursors]::Hand # Looks clickable
# Add click event to open the link in a browser
$aboutLabelGithub.Add_Click({
    Start-Process "https://github.com/moein8668-git/Application-Launcher"
})
$aboutPanel.Controls.Add($aboutLabelGithub)


$aboutLabelLicenseTitle = New-Object System.Windows.Forms.Label
$aboutLabelLicenseTitle.Text = "Licensing Information:"
$aboutLabelLicenseTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$aboutLabelLicenseTitle.AutoSize = $true
$aboutLabelLicenseTitle.Margin = New-Object System.Windows.Forms.Padding(0, 30, 0, 5)
$aboutPanel.Controls.Add($aboutLabelLicenseTitle)

$aboutLabelLicense = New-Object System.Windows.Forms.Label
$aboutLabelLicense.Text = "This software is licensed under the GNU General Public License v3 (GPLv3).`nCheck the LICENSE file in the project directory for full details."
$aboutLabelLicense.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$aboutLabelLicense.AutoSize = $true
$aboutPanel.Controls.Add($aboutLabelLicense)

# Add the content panel to the tab
$aboutTab.Controls.Add($aboutPanel)

# Define Dynamic Panel Width based on Form Size (800)
# (800 Form Width) - (10px MainPanel Padding * 2) - (10px TabPage Padding * 2) - (~20px Scrollbar) = 750px
$DynamicPanelWidth = 362
$StatusIconWidth = 120
$TypeBadgeWidth = 50
$Spacing = 2

# Calculate the maximum space for the CheckBox:
# Panel Width - Left Margin (10) - Type Badge - Spacing - Status Icon - Right Margin (10)
$DynamicNameMaxWidth = $DynamicPanelWidth - 10 - $TypeBadgeWidth - $Spacing - $StatusIconWidth - 10
# $DynamicNameMaxWidth will be about 555px wide.
$MaxNameChars = 65 # Approximate character limit for this width

# Function to create modern task items
function Create-TaskItem {
    param($task, $type)
    
    # Use the globally defined dynamic variables
    $panelWidth = $DynamicPanelWidth
    $statusIconWidth = $StatusIconWidth
    $typeBadgeWidth = $TypeBadgeWidth
    $spacing = $Spacing
    $nameMaxWidth = $DynamicNameMaxWidth # Max width for the checkbox
    $maxChars = $MaxNameChars # Max characters for trimming

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Width = $panelWidth # Set the dynamic width
    $panel.Height = 60
    $panel.Margin = New-Object System.Windows.Forms.Padding($spacing)
    $panel.BackColor = [System.Drawing.Color]::White
    $panel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    
    # 1. Status Icon Position Calculation (Starting from the right edge of the new dynamic panel)
    $statusIconX = $panelWidth - $statusIconWidth - 10 # 10px padding from right edge

    # 2. File Type Badge Position Calculation
    $typeBadgeX = $statusIconX - $typeBadgeWidth - $spacing # 5px spacing between badge and icon

    # --- Checkbox (Task Name) ---
    $chkBox = New-Object System.Windows.Forms.CheckBox
    $chkBox.Tag = $task
    $chkBox.Checked = $task.selected
    $chkBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    
    # FIX: Set a fixed width and disable AutoSize
    $chkBox.Width = $nameMaxWidth 
    $chkBox.AutoSize = $false 
    
    # FIX: Use Substring for reliable text trimming
    if ($task.name.Length -gt $maxChars) {
        $chkBox.Text = $task.name.Substring(0, $maxChars - 3) + "..."
    } else {
        $chkBox.Text = $task.name
    }
    
    $chkBox.Location = New-Object System.Drawing.Point(10, 20)
    $chkBox.Add_Click({ $script:StopCountdown.Invoke() })
    
    # --- Status Indicator ---
    $statusIcon = New-Object System.Windows.Forms.Label
    $statusIcon.Width = $statusIconWidth
    $statusIcon.Height = 25
    $statusIcon.Text = "PENDING"
    $statusIcon.ForeColor = [System.Drawing.Color]::White
    $statusIcon.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
    $statusIcon.TextAlign = "MiddleCenter"
    $statusIcon.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $statusIcon.Name = "status_$($task.name)"
    $statusIcon.Location = New-Object System.Drawing.Point($statusIconX, 15) # Position is relative to new $panelWidth

    # --- File Type Badge ---
    $typeBadge = New-Object System.Windows.Forms.Label
    $typeBadge.Text = $task.type.ToUpper()
    $typeBadge.Width = $typeBadgeWidth
    $typeBadge.Height = 20
    $typeBadge.BackColor = [System.Drawing.Color]::FromArgb(233, 236, 239)
    $typeBadge.ForeColor = [System.Drawing.Color]::FromArgb(73, 80, 87)
    $typeBadge.TextAlign = "MiddleCenter"
    $typeBadge.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
    $typeBadge.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $typeBadge.Location = New-Object System.Drawing.Point($typeBadgeX, 18) # Position is relative to new $statusIconX
    
    $panel.Controls.Add($chkBox)
    $panel.Controls.Add($typeBadge)
    $panel.Controls.Add($statusIcon)
    
    if ($type -eq "sequential") {
        $sequentialList.Controls.Add($panel)
    } else {
        $parallelList.Controls.Add($panel)
    }
}


# Add tasks to UI
foreach ($task in $configJson.sequential) {
    Create-TaskItem $task "sequential"
}

foreach ($task in $configJson.parallel) {
    Create-TaskItem $task "parallel"
}

# Modern button styling
$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "INSTALL SELECTED"
$runButton.Dock = "Bottom"
$runButton.Height = 45
$runButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$runButton.BackColor = $primaryColor
$runButton.ForeColor = [System.Drawing.Color]::White
$runButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$runButton.FlatAppearance.BorderSize = 0
$runButton.Cursor = [System.Windows.Forms.Cursors]::Hand

# Hover effects for button
$runButton.Add_MouseEnter({
    $this.BackColor = [System.Drawing.Color]::FromArgb(0, 105, 217)
})
$runButton.Add_MouseLeave({
    $this.BackColor = $primaryColor
})

# --- Event Handlers for Select/Unselect All Buttons ---
$btnSequentialSelectAll.Add_Click({
    foreach ($panel in $sequentialList.Controls) {
        if ($panel.Controls[0] -is [System.Windows.Forms.CheckBox]) {
            $panel.Controls[0].Checked = $true
        }
    }
    $script:StopCountdown.Invoke()
})

$btnSequentialUnselectAll.Add_Click({
    foreach ($panel in $sequentialList.Controls) {
        if ($panel.Controls[0] -is [System.Windows.Forms.CheckBox]) {
            $panel.Controls[0].Checked = $false
        }
    }
    $script:StopCountdown.Invoke()
})

$btnParallelSelectAll.Add_Click({
    foreach ($panel in $parallelList.Controls) {
        if ($panel.Controls[0] -is [System.Windows.Forms.CheckBox]) {
            $panel.Controls[0].Checked = $true
        }
    }
})

$btnParallelUnselectAll.Add_Click({
    foreach ($panel in $parallelList.Controls) {
        if ($panel.Controls[0] -is [System.Windows.Forms.CheckBox]) {
            $panel.Controls[0].Checked = $false
        }
    }
})
# --- END NEW: Event Handlers ---


# [Keep your existing click handler code exactly as is - only UI changes] (Existing)
$runButton.Add_Click({
    $script:StopCountdown.Invoke() # Stop countdown on manual click
    $runButton.Enabled = $false
    $statusLabel.Text = "Starting installation..."
    $progressBar.Value = 0
    $form.Refresh()

    # Get all selected tasks
    $allTasks = @()
    foreach ($control in $sequentialList.Controls) {
        $chkBox = $control.Controls[0] # Assuming checkbox is the first control in the panel
        if ($chkBox -is [System.Windows.Forms.CheckBox] -and $chkBox.Checked) {
            $allTasks += @{
                Task = $chkBox.Tag
                Control = $control # This is the panel itself
                Type = "sequential"
            }
        }
    }
    
    foreach ($control in $parallelList.Controls) {
         $chkBox = $control.Controls[0] # Assuming checkbox is the first control in the panel
        if ($chkBox -is [System.Windows.Forms.CheckBox] -and $chkBox.Checked) {
            $allTasks += @{
                Task = $chkBox.Tag
                Control = $control # This is the panel itself
                Type = "parallel"
            }
        }
    }
    
    if ($allTasks.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No tasks selected!", "Warning")
        $runButton.Enabled = $true
        return
    }

    $totalTasks = $allTasks.Count
    $completed = 0
    
    # Run sequential tasks first
    $sequentialTasksToRun = $allTasks | Where-Object { $_.Type -eq "sequential" }
    foreach ($item in $sequentialTasksToRun) {
        $task = $item.Task
        # The status control is the third control (index 2) in the task item panel
        $statusControl = $item.Control.Controls | Where-Object {$_.Name -eq "status_$($task.name)"}
        
        $statusControl.Text = "Installing..."
        $statusControl.ForeColor = [System.Drawing.Color]::Blue 
        $statusLabel.Text = "Running: $($task.name)"
        $form.Refresh()
        
        try {
            $filePath = Join-Path $PSScriptRoot $task.file
            $directory = Split-Path -Path $filePath -Parent
            if (-not (Test-Path $filePath)) {
                throw "File not found: $filePath"
            }

            # Handle empty/whitespace arguments
            $arguments = if ([string]::IsNullOrWhiteSpace($task.args)) { $null } else { $task.args }

            switch ($task.type) {
                "reg"   { Start-Process "regedit" -ArgumentList "/s `"$filePath`"" -Wait -NoNewWindow }
                "exe"   { 
                    if ($arguments) {
                        Write-Host "exe with arg $($arguments) Installing: $($filePath)"
                        Start-Process -FilePath $filePath -WorkingDirectory $directory -ArgumentList $arguments -Wait 
                        
                    } else {
                        Write-Host "Starting process: $filePath"
                        $process = Start-Process -FilePath $filePath -WorkingDirectory $directory -Verb RunAs -PassThru
                        $process.WaitForExit() # We wait on the process object directly
                            
                        # After the process has finished, write its exit code to the console
                        Write-Host "Process finished with Exit Code: $($process.ExitCode)"
    
                        # Check if the exit code indicates an error
                        if ($process.ExitCode -ne 0) {
                            throw "The process exited with error code: $($process.ExitCode)"
                        }
                    }
                }
                "msi"   { 
                    $msiArgs = "/i `"$filePath`""
                    if ($arguments) { $msiArgs += " $arguments" }
                    Write-Host "msi installing $($msiArgs)"
                    Start-Process "msiexec" -ArgumentList $msiArgs -Wait 
                }
                "bat"   { 
                    if ($arguments) {
                        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$filePath`" $arguments" -Wait -NoNewWindow
                    } else {
                        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$filePath`"" -Wait -NoNewWindow
                    }
                }
                "cmd"   { 
                    if ($arguments) {
                        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$filePath`" $arguments" -Wait -NoNewWindow
                    } else {
                        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$filePath`"" -Wait -NoNewWindow
                    }
                }
                default { 
                    if ($arguments) {
                        Start-Process -FilePath $filePath -ArgumentList $arguments -Wait 
                    } else {
                        Start-Process -FilePath $filePath -Wait 
                    }
                }
            }
            
            $statusControl.Text = "OK Installed"
            $statusControl.ForeColor = [System.Drawing.Color]::Green 
            Write-Host "Success: $($task.name)"

        }
        catch {
            $statusControl.Text = "X Failed"
            $statusControl.ForeColor = [System.Drawing.Color]::Red 
            Write-Host "Failed: $($task.name) - $_"

            [System.Windows.Forms.MessageBox]::Show("Failed to install $($task.name): $_", "Error")
        }
        
        $completed++
        $progressBar.Value = ($completed / $totalTasks) * 100
        $form.Refresh()
    }
    
    # Run parallel tasks with proper status tracking
    $parallelTasksToRun = $allTasks | Where-Object { $_.Type -eq "parallel" }
    $jobs = @()

    foreach ($item in $parallelTasksToRun) {
        $task = $item.Task
        $statusControl = $item.Control.Controls | Where-Object {$_.Name -eq "status_$($task.name)"}
        $statusControl.Text = "Installing..."
        $statusControl.ForeColor = [System.Drawing.Color]::Blue 
        Write-Host "Parallel Installing: $($statusControl.Name)" 
        $form.Refresh()

        $filePath = Join-Path $PSScriptRoot $task.file
        if (-not (Test-Path $filePath)) {
            $statusControl.Text = "X File Missing"
            $statusControl.ForeColor = [System.Drawing.Color]::Red 
            continue
        }

        $arguments = if ([string]::IsNullOrWhiteSpace($task.args)) { $null } else { $task.args }

        $scriptBlock = {
            param($filePath, $type, $arguments)
            try {
                switch ($type) {
                    "reg"   { Start-Process "regedit" -ArgumentList "/s `"$filePath`"" -Wait -NoNewWindow }
                    "exe"   { Start-Process -FilePath $filePath -ArgumentList $arguments -Wait  }
                    "msi"   { Start-Process "msiexec" -ArgumentList "/i `"$filePath`" $arguments" -Wait  }
                    "bat"   { Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$filePath`" $arguments" -Wait  }
                    "cmd"   { Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$filePath`" $arguments" -Wait  }
                    default { Start-Process -FilePath $filePath -ArgumentList $arguments -Wait  }
                }
                return @{ Status = "Success" }
            } catch {
                return @{ Status = "Failed"; Error = $_.ToString() }
            }
        }

        $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $filePath, $task.type, $arguments
        
        $job | Add-Member -MemberType NoteProperty -Name StatusControl -Value $statusControl
        Write-Host "parallel job start: $($job.StatusControl.Name) - $_" 
        $jobs += $job
    }

    # Wait and update UI for each job
    foreach ($job in $jobs) {
        Wait-Job $job
        $result = Receive-Job $job
        $statusControl = $job.StatusControl
        
        if ($result.Status -eq "Success") {
            $statusControl.Text = "OK Installed"
            $statusControl.ForeColor = [System.Drawing.Color]::Green 
            Write-Host "Parallel Success: $($statusControl.Name)" 

        } else {
            Write-Host "Parallel Failed: $($statusControl.Name) - $($result.Error)" 

            $statusControl.Text = "X Failed"
            $statusControl.ForeColor = [System.Drawing.Color]::Red 
            [System.Windows.Forms.MessageBox]::Show("Parallel install failed: $($result.Error)", "Error")
        }

        Remove-Job $job
        $completed++
        $progressBar.Value = ($completed / $totalTasks) * 100
        $form.Refresh()
    }

    
    $statusLabel.Text = "All selected tasks completed!"
    $progressBar.Value = 100
    $runButton.Enabled = $true
})

# Add controls to form
$sequentialTab.Controls.Add($sequentialList)
$sequentialTab.Controls.Add($sequentialButtonPanel)

$parallelTab.Controls.Add($parallelList)
$parallelTab.Controls.Add($parallelButtonPanel)

$tabControl.Controls.Add($sequentialTab)
$tabControl.Controls.Add($parallelTab)
$tabControl.Controls.Add($aboutTab)

$mainPanel.Controls.Add($tabControl)
$mainPanel.Controls.Add($tabControl)
$mainPanel.Controls.Add($statusLabel)
$mainPanel.Controls.Add($progressBar)
$mainPanel.Controls.Add($runButton)

$form.Controls.Add($mainPanel)
$form.Controls.Add($headerPanel)


# --- Global Interaction Handlers (Stops timer on any activity) ---
$form.Add_KeyPress({ $script:StopCountdown.Invoke() })

$script:CountdownTimer.Start()

# Show form
[void]$form.ShowDialog()