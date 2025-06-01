
# Import required .NET assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Security function to check if a path is a system-critical folder
function Test-SystemFolder {
    param([string]$Path)
    
    $systemPaths = @(
        $env:windir,
        "$env:windir\System32",
        "$env:ProgramFiles",
        "$env:ProgramFiles(x86)",
        "$env:ProgramData",
        [Environment]::GetFolderPath('System'),
        [Environment]::GetFolderPath('Windows')
    )
    
    foreach ($sysPath in $systemPaths) {
        if ($Path -eq $sysPath -or $Path -like "$sysPath*") {
            return $true
        }
    }
    return $false
}

# Function to log deletion operations
function Write-DeletionLog {
    param(
        [string]$Path,
        [string]$Result,
        [string]$Message
    )
    
    $logFolder = Join-Path -Path $env:APPDATA -ChildPath "ForceDeleteTool"
    if (-not (Test-Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
    }
    
    $logFile = Join-Path -Path $logFolder -ChildPath "deletion_log.csv"
    if (-not (Test-Path $logFile)) {
        "Timestamp,User,Path,Result,Message" | Out-File -FilePath $logFile -Encoding utf8
    }
    
    # Format CSV line with proper escaping for commas in paths
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $user = $env:USERNAME
    $csvPath = "`"$Path`""
    "$timestamp,$user,$csvPath,$Result,`"$Message`"" | Out-File -FilePath $logFile -Encoding utf8 -Append
}

# Import custom modules
$scriptPath = if ($PSScriptRoot) { 
    $PSScriptRoot 
} elseif ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $PWD.Path
}

Import-Module "$scriptPath\themes\WinUI3-Colors.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$scriptPath\utils\FileOperations.psm1" -Force -ErrorAction SilentlyContinue

# Color scheme (modern theme with accent colors)
function Get-EnhancedColors {
    return @{
        ColorPrimary = [System.Drawing.Color]::FromArgb(25, 113, 194)       # Deeper blue
        ColorPrimaryLight = [System.Drawing.Color]::FromArgb(51, 137, 214)  # Lighter blue
        ColorBackground = [System.Drawing.Color]::FromArgb(250, 250, 252)   # Off-white background
        ColorSurface = [System.Drawing.Color]::White
        ColorText = [System.Drawing.Color]::FromArgb(33, 33, 33)
        ColorTextSecondary = [System.Drawing.Color]::FromArgb(102, 102, 102)
        ColorDanger = [System.Drawing.Color]::FromArgb(209, 52, 56)         # Red
        ColorDangerHover = [System.Drawing.Color]::FromArgb(189, 42, 46)    # Darker red
        ColorSuccess = [System.Drawing.Color]::FromArgb(46, 174, 79)        # Green
        ColorWarning = [System.Drawing.Color]::FromArgb(246, 134, 31)       # Orange
        ColorSeparator = [System.Drawing.Color]::FromArgb(230, 230, 230)    # Light gray for separators
        ColorInfo = [System.Drawing.Color]::FromArgb(240, 246, 252)         # Light blue for info panels
    }
}

# Get colors
$colors = Get-EnhancedColors

# Font settings
$fontRegular = New-Object System.Drawing.Font("Segoe UI", 9)
$fontMedium = New-Object System.Drawing.Font("Segoe UI", 10)
$fontMediumBold = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$fontTitle = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$fontHeading = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$fontSmall = New-Object System.Drawing.Font("Segoe UI", 8)

#---------------------------------------
# Main Form
#---------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "ForceDelete Tool"
$form.Size = New-Object System.Drawing.Size(800, 520)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.BackColor = $colors.ColorBackground
$form.Font = $fontRegular
$form.Icon = [System.Drawing.SystemIcons]::Application

#---------------------------------------
# Header
#---------------------------------------
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = "Top"
$headerPanel.Height = 80
$headerPanel.BackColor = $colors.ColorPrimary
$form.Controls.Add($headerPanel)

# Add logo to header
$logoPanel = New-Object System.Windows.Forms.Panel
$logoPanel.Size = New-Object System.Drawing.Size(60, 60)
$logoPanel.Location = New-Object System.Drawing.Point(20, 10)
$logoPanel.BackColor = [System.Drawing.Color]::Transparent
$headerPanel.Controls.Add($logoPanel)

$logoPanel.Add_Paint({
    param($src, $e)
    
    # Draw a simple delete icon
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 3)
    
    # Create X shape
    $e.Graphics.DrawLine($pen, 15, 15, 45, 45)
    $e.Graphics.DrawLine($pen, 45, 15, 15, 45)
    
    # Draw circle around X
    $e.Graphics.DrawEllipse($pen, 10, 10, 40, 40)
})  # End of event handler script block

$headerTitle = New-Object System.Windows.Forms.Label
$headerTitle.Text = "ForceDelete Tool"
$headerTitle.ForeColor = [System.Drawing.Color]::White
$headerTitle.Font = $fontTitle
$headerTitle.AutoSize = $false
$headerTitle.Size = New-Object System.Drawing.Size(300, 40)
$headerTitle.Location = New-Object System.Drawing.Point(90, 12)
$headerPanel.Controls.Add($headerTitle)

$headerSubtitle = New-Object System.Windows.Forms.Label
$headerSubtitle.Text = "Remove stubborn folders and files with ease"
$headerSubtitle.ForeColor = [System.Drawing.Color]::FromArgb(225, 225, 225)
$headerSubtitle.Font = $fontMedium
$headerSubtitle.AutoSize = $false
$headerSubtitle.Size = New-Object System.Drawing.Size(300, 20)
$headerSubtitle.Location = New-Object System.Drawing.Point(90, 48)
$headerPanel.Controls.Add($headerSubtitle)

$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Text = "v1.0"
$versionLabel.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
$versionLabel.Font = $fontSmall
$versionLabel.AutoSize = $true
$versionLabel.Location = New-Object System.Drawing.Point(750, 60)
$headerPanel.Controls.Add($versionLabel)

#---------------------------------------
# Main Container
#---------------------------------------
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Dock = "Fill"
$mainPanel.Padding = New-Object System.Windows.Forms.Padding(20, 20, 20, 20)
$mainPanel.BackColor = $colors.ColorSurface
$form.Controls.Add($mainPanel)

#---------------------------------------
# Instructions Section
#---------------------------------------
$instructionsPanel = New-Object System.Windows.Forms.Panel
$instructionsPanel.Dock = "Top"
$instructionsPanel.Height = 70
$instructionsPanel.BackColor = $colors.ColorInfo
$instructionsPanel.Padding = New-Object System.Windows.Forms.Padding(10, 5, 10, 5)
$mainPanel.Controls.Add($instructionsPanel)

$infoIcon = New-Object System.Windows.Forms.Label
$infoIcon.Text = "i"
$infoIcon.Size = New-Object System.Drawing.Size(30, 30)
$infoIcon.Location = New-Object System.Drawing.Point(15, 20)
$infoIcon.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
$infoIcon.ForeColor = $colors.ColorPrimary
$infoIcon.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$instructionsPanel.Controls.Add($infoIcon)

$instructionsLabel = New-Object System.Windows.Forms.Label
$instructionsLabel.Text = "This tool helps you delete stubborn folders that resist normal deletion. It removes read-only, hidden, and system attributes before performing a force delete operation."
$instructionsLabel.Size = New-Object System.Drawing.Size(700, 60)
$instructionsLabel.Location = New-Object System.Drawing.Point(50, 5)
$instructionsLabel.ForeColor = $colors.ColorText
$instructionsLabel.Font = $fontMedium
$instructionsPanel.Controls.Add($instructionsLabel)

# Separator
$separator1 = New-Object System.Windows.Forms.Panel
$separator1.Height = 1
$separator1.Dock = "Top"
$separator1.BackColor = $colors.ColorSeparator
$mainPanel.Controls.Add($separator1)

# Add spacing after separator
$spacer1 = New-Object System.Windows.Forms.Panel
$spacer1.Height = 15
$spacer1.Dock = "Top"
$mainPanel.Controls.Add($spacer1)

#---------------------------------------
# Path Selection Section
#---------------------------------------
$pathPanel = New-Object System.Windows.Forms.Panel
$pathPanel.Dock = "Top"
$pathPanel.Height = 80
$pathPanel.Padding = New-Object System.Windows.Forms.Padding(0, 10, 0, 10)
$mainPanel.Controls.Add($pathPanel)

$pathLabel = New-Object System.Windows.Forms.Label
$pathLabel.Text = "Select Target Folder:"
$pathLabel.Size = New-Object System.Drawing.Size(140, 25)
$pathLabel.Location = New-Object System.Drawing.Point(0, 7)
$pathLabel.Font = $fontMediumBold
$pathLabel.ForeColor = $colors.ColorText
$pathPanel.Controls.Add($pathLabel)

$textBoxBorderPanel = New-Object System.Windows.Forms.Panel
$textBoxBorderPanel.Size = New-Object System.Drawing.Size(522, 32)
$textBoxBorderPanel.Location = New-Object System.Drawing.Point(140, 5)
$textBoxBorderPanel.BorderStyle = "FixedSingle"
$textBoxBorderPanel.BackColor = [System.Drawing.Color]::White
$pathPanel.Controls.Add($textBoxBorderPanel)

$pathTextBox = New-Object System.Windows.Forms.TextBox
$pathTextBox.Size = New-Object System.Drawing.Size(518, 28)
$pathTextBox.Location = New-Object System.Drawing.Point(1, 1)
$pathTextBox.Font = $fontMedium
$pathTextBox.BorderStyle = "None"
$pathTextBox.BackColor = [System.Drawing.Color]::White
$textBoxBorderPanel.Controls.Add($pathTextBox)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse..."
$browseButton.Size = New-Object System.Drawing.Size(100, 32)
$browseButton.Location = New-Object System.Drawing.Point(670, 5)
$browseButton.FlatStyle = "Flat"
$browseButton.BackColor = $colors.ColorPrimary
$browseButton.ForeColor = [System.Drawing.Color]::White
$browseButton.Font = $fontMediumBold
$browseButton.FlatAppearance.BorderSize = 0
$browseButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$pathPanel.Controls.Add($browseButton)

$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = "X"
$clearButton.Size = New-Object System.Drawing.Size(32, 32)
$clearButton.Location = New-Object System.Drawing.Point(632, 5)
$clearButton.FlatStyle = "Flat"
$clearButton.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$clearButton.ForeColor = $colors.ColorTextSecondary
$clearButton.Font = $fontMedium
$clearButton.FlatAppearance.BorderSize = 0
$clearButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$clearButton.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$pathPanel.Controls.Add($clearButton)

# Escaped ampersand with backtick
$dragDropLabel = New-Object System.Windows.Forms.Label
$dragDropLabel.Text = "Tip: You can also drag `& drop a folder here"
$dragDropLabel.Size = New-Object System.Drawing.Size(300, 20)
$dragDropLabel.Location = New-Object System.Drawing.Point(140, 40)
$dragDropLabel.Font = $fontSmall
$dragDropLabel.ForeColor = $colors.ColorTextSecondary
$pathPanel.Controls.Add($dragDropLabel)

# Add spacing
$spacer2 = New-Object System.Windows.Forms.Panel
$spacer2.Height = 10
$spacer2.Dock = "Top"
$mainPanel.Controls.Add($spacer2)

#---------------------------------------
# Warning Section
#---------------------------------------
$warningPanel = New-Object System.Windows.Forms.Panel
$warningPanel.Dock = "Top"
$warningPanel.Height = 80
$warningPanel.BackColor = [System.Drawing.Color]::FromArgb(255, 244, 229)
$mainPanel.Controls.Add($warningPanel)

$warningIcon = New-Object System.Windows.Forms.Label
$warningIcon.Text = "!"
$warningIcon.Size = New-Object System.Drawing.Size(40, 40)
$warningIcon.Location = New-Object System.Drawing.Point(15, 20)
$warningIcon.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$warningIcon.ForeColor = $colors.ColorWarning
$warningIcon.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$warningPanel.Controls.Add($warningIcon)

$warningLabel = New-Object System.Windows.Forms.Label
$warningLabel.Text = "WARNING: Deleted folders cannot be recovered. This operation permanently removes data from your system."
$warningLabel.Size = New-Object System.Drawing.Size(680, 60)
$warningLabel.Location = New-Object System.Drawing.Point(60, 10)
$warningLabel.Font = $fontMedium
$warningLabel.ForeColor = $colors.ColorWarning
$warningPanel.Controls.Add($warningLabel)

$confirmCheckbox = New-Object System.Windows.Forms.CheckBox
$confirmCheckbox.Text = "I understand that this operation is permanent and cannot be undone"
$confirmCheckbox.Size = New-Object System.Drawing.Size(500, 20)
$confirmCheckbox.Location = New-Object System.Drawing.Point(60, 50)
$confirmCheckbox.Font = $fontMedium
$confirmCheckbox.ForeColor = $colors.ColorTextSecondary
$warningPanel.Controls.Add($confirmCheckbox)

# Add spacing
$spacer3 = New-Object System.Windows.Forms.Panel
$spacer3.Height = 15
$spacer3.Dock = "Top"
$mainPanel.Controls.Add($spacer3)

#---------------------------------------
# Action Section
#---------------------------------------
$actionPanel = New-Object System.Windows.Forms.Panel
$actionPanel.Dock = "Fill"
$actionPanel.Padding = New-Object System.Windows.Forms.Padding(0, 10, 0, 0)
$mainPanel.Controls.Add($actionPanel)

# Progress panel (initially hidden)
$progressPanel = New-Object System.Windows.Forms.Panel
$progressPanel.Size = New-Object System.Drawing.Size(740, 60)
$progressPanel.Location = New-Object System.Drawing.Point(0, 0)
$progressPanel.Visible = $false
$actionPanel.Controls.Add($progressPanel)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Style = "Marquee"
$progressBar.MarqueeAnimationSpeed = 30
$progressBar.Size = New-Object System.Drawing.Size(740, 8)
$progressBar.Location = New-Object System.Drawing.Point(0, 30)
$progressPanel.Controls.Add($progressBar)

$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.Text = "Deleting folder..."
$progressLabel.Size = New-Object System.Drawing.Size(740, 20)
$progressLabel.Location = New-Object System.Drawing.Point(0, 5)
$progressLabel.Font = $fontMedium
$progressLabel.ForeColor = $colors.ColorTextSecondary
$progressPanel.Controls.Add($progressLabel)

$progressDetails = New-Object System.Windows.Forms.Label
$progressDetails.Text = ""
$progressDetails.Size = New-Object System.Drawing.Size(740, 20)
$progressDetails.Location = New-Object System.Drawing.Point(0, 40)
$progressDetails.Font = $fontSmall
$progressDetails.ForeColor = $colors.ColorTextSecondary
$progressPanel.Controls.Add($progressDetails)

# Delete button
$deleteButton = New-Object System.Windows.Forms.Button
$deleteButton.Text = "FORCE DELETE (Ctrl+D)"
$deleteButton.Size = New-Object System.Drawing.Size(220, 50)
$deleteButton.Location = New-Object System.Drawing.Point(260, 20)
$deleteButton.FlatStyle = "Flat"
$deleteButton.BackColor = $colors.ColorDanger
$deleteButton.ForeColor = [System.Drawing.Color]::White
$deleteButton.Font = $fontHeading
$deleteButton.FlatAppearance.BorderSize = 0
$deleteButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$deleteButton.Enabled = $false  # Disabled until checkbox is checked
$actionPanel.Controls.Add($deleteButton)

# Add a "Safe Mode" checkbox
$safeModeCheckbox = New-Object System.Windows.Forms.CheckBox
$safeModeCheckbox.Text = "Safe Mode (Preview deletion without removing files)"
$safeModeCheckbox.Size = New-Object System.Drawing.Size(400, 20)
$safeModeCheckbox.Location = New-Object System.Drawing.Point(195, 75)
$safeModeCheckbox.Font = $fontMedium
$safeModeCheckbox.ForeColor = $colors.ColorTextSecondary
$actionPanel.Controls.Add($safeModeCheckbox)

# Add a hint below delete button
$securityHint = New-Object System.Windows.Forms.Label
$securityHint.Text = "Security Tip: Always verify the folder path before deletion"
$securityHint.Size = New-Object System.Drawing.Size(400, 20)
$securityHint.Location = New-Object System.Drawing.Point(170, 95)
$securityHint.Font = $fontSmall
$securityHint.ForeColor = $colors.ColorTextSecondary
$actionPanel.Controls.Add($securityHint)

# Recent operations panel
$recentLabel = New-Object System.Windows.Forms.Label
$recentLabel.Text = "Recent Operations:"
$recentLabel.Size = New-Object System.Drawing.Size(200, 20)
$recentLabel.Location = New-Object System.Drawing.Point(0, 125)
$recentLabel.Font = $fontMediumBold
$recentLabel.ForeColor = $colors.ColorText
$actionPanel.Controls.Add($recentLabel)

$recentList = New-Object System.Windows.Forms.ListView
$recentList.View = [System.Windows.Forms.View]::Details
$recentList.Size = New-Object System.Drawing.Size(740, 80)
$recentList.Location = New-Object System.Drawing.Point(0, 150)
$recentList.FullRowSelect = $true
$recentList.GridLines = $false
$actionPanel.Controls.Add($recentList)

$recentList.Columns.Add("Time", 120)
$recentList.Columns.Add("Path", 450)
$recentList.Columns.Add("Status", 150)

#---------------------------------------
# Status Strip
#---------------------------------------
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusStrip.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
$form.Controls.Add($statusStrip)

$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Ready"
$statusLabel.ForeColor = $colors.ColorTextSecondary
$statusStrip.Items.Add($statusLabel)

$shortcutLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$shortcutLabel.Text = "Press F1 for help"
$shortcutLabel.ForeColor = $colors.ColorTextSecondary
$shortcutLabel.Alignment = [System.Windows.Forms.ToolStripItemAlignment]::Right
$statusStrip.Items.Add($shortcutLabel)

#---------------------------------------
# Tooltips
#---------------------------------------
$warningTooltip = New-Object System.Windows.Forms.ToolTip
$warningTooltip.SetToolTip($warningIcon, "Warning: This operation cannot be undone")

$browseTooltip = New-Object System.Windows.Forms.ToolTip
$browseTooltip.SetToolTip($browseButton, "Browse for folder (Ctrl+B)")

$clearTooltip = New-Object System.Windows.Forms.ToolTip
$clearTooltip.SetToolTip($clearButton, "Clear path (Esc)")

$safeTooltip = New-Object System.Windows.Forms.ToolTip
$safeTooltip.SetToolTip($safeModeCheckbox, "Test what would be deleted without actually removing files")

#---------------------------------------
# Event Handlers
#---------------------------------------
# Enable drag and drop for textbox
$textBoxBorderPanel.AllowDrop = $true

$textBoxBorderPanel.Add_DragEnter({
    param($src, $e)
    if ($e.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effect = [Windows.Forms.DragDropEffects]::Copy
    } else {
        $e.Effect = [Windows.Forms.DragDropEffects]::None
    }
}) # End of $deleteButton.Add_Click script block

$textBoxBorderPanel.Add_DragDrop({
    param($src, $e)
    $files = $e.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    if ($files.Count -gt 0) {
        if (Test-Path -Path $files[0] -PathType Container) {
            $pathTextBox.Text = $files[0]
            $statusLabel.Text = "Folder dropped: " + [System.IO.Path]::GetFileName($files[0])
        } else {
            [System.Windows.Forms.MessageBox]::Show("Please drop a folder, not a file.", "Invalid Drop", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    }
})

# Path textbox change event
$pathTextBox.Add_TextChanged({
    if (-not [string]::IsNullOrWhiteSpace($pathTextBox.Text) -and $confirmCheckbox.Checked) {
        $deleteButton.Enabled = $true
    } else {
        $deleteButton.Enabled = $false
    }
})

# Confirmation checkbox
$confirmCheckbox.Add_CheckedChanged({
    if (-not [string]::IsNullOrWhiteSpace($pathTextBox.Text) -and $confirmCheckbox.Checked) {
        $deleteButton.Enabled = $true
    } else {
        $deleteButton.Enabled = $false
    }
})

# Clear button
$clearButton.Add_Click({
    $pathTextBox.Clear()
    $statusLabel.Text = "Path cleared"
})

# Browse button
$browseButton.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "Select folder to delete"
    $folderDialog.ShowNewFolderButton = $false
    
    if ($folderDialog.ShowDialog() -eq "OK") {
        $pathTextBox.Text = $folderDialog.SelectedPath
        $statusLabel.Text = "Selected: " + [System.IO.Path]::GetFileName($folderDialog.SelectedPath)
    }
})

# Button hover effects
$browseButton.Add_MouseEnter({
    $this.BackColor = $colors.ColorPrimaryLight
})
$browseButton.Add_MouseLeave({
    $this.BackColor = $colors.ColorPrimary
})

$clearButton.Add_MouseEnter({
    $this.BackColor = [System.Drawing.Color]::FromArgb(225, 225, 225)
    $this.ForeColor = $colors.ColorDanger
})
$clearButton.Add_MouseLeave({
    $this.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $this.ForeColor = $colors.ColorTextSecondary
})

$deleteButton.Add_MouseEnter({
    if ($this.Enabled) {
        $this.BackColor = $colors.ColorDangerHover
    }
})
$deleteButton.Add_MouseLeave({
    if ($this.Enabled) {
        $this.BackColor = $colors.ColorDanger
    }
})

# Delete button operation with security enhancements
$deleteButton.Add_Click({
    $path = $pathTextBox.Text.Trim()
    
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -Path $path)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a valid folder path.", "Invalid Path", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        $statusLabel.Text = "Error: Invalid path"
        return
    }

    # Security check for system folders
    if (Test-SystemFolder -Path $path) {
        $systemConfirm = [System.Windows.Forms.MessageBox]::Show(
            "WARNING! You are attempting to delete a system folder.`n`n$path`n`nDeleting system folders can break your operating system. Are you absolutely sure you want to continue?", 
            "System Folder Warning", 
            [System.Windows.Forms.MessageBoxButtons]::YesNo, 
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        
        if ($systemConfirm -ne "Yes") {
            $statusLabel.Text = "System folder deletion cancelled"
            return
        }
    }
    
    # Normal confirmation
    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to permanently delete this folder?`n`n$path`n`nThis action cannot be undone.", 
        "Confirm Delete", 
        [System.Windows.Forms.MessageBoxButtons]::YesNo, 
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($confirm -eq "Yes") {
        $deleteButton.Visible = $false
        $progressPanel.Visible = $true
        $statusLabel.Text = if ($safeModeCheckbox.Checked) { "Simulating deletion..." } else { "Deleting folder..." }
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $confirmCheckbox.Enabled = $false
        $browseButton.Enabled = $false
        $clearButton.Enabled = $false
        $pathTextBox.Enabled = $false
        $safeModeCheckbox.Enabled = $false
        
        # Log the operation start
        Write-DeletionLog -Path $path -Result "Started" -Message "Deletion operation initiated"
        
        # Start deletion in a background job
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 100
        $timer.Tag = @{
            StartTime = Get-Date
            Path = $path
            Status = "Running"
            Stage = "Preparing"
            SafeMode = $safeModeCheckbox.Checked
        }
        
        $timer.Add_Tick({
            $data = $this.Tag
            
            if ($data.Stage -eq "Preparing") {
                $progressLabel.Text = if ($data.SafeMode) { "Simulating deletion..." } else { "Removing file attributes..." }
                $progressDetails.Text = "Processing $($path)"
                $data.Stage = "RemovingAttributes"
                
                # Start actual work
                Start-Job -ScriptBlock {
                    param($path, $safeMode)
                    try {
                        # Count items for logging
                        $itemCount = (Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object).Count
                        
                        if (-not $safeMode) {
                            # Remove attributes
                            attrib -r -h -s "$path\*.*" /S /D 2>$null
                            
                            # Delete folder
                            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                            return @{ 
                                Success = $true; 
                                Message = "Folder deleted successfully";
                                ItemCount = $itemCount;
                                SafeMode = $safeMode
                            }
                        } else {
                            # Safe mode - just simulate
                            Start-Sleep -Seconds 1  # Simulate some work
                            return @{ 
                                Success = $true; 
                                Message = "Simulation complete - would have deleted $itemCount items"; 
                                ItemCount = $itemCount;
                                SafeMode = $true
                            }
                        }
                    } catch {
                        return @{ 
                            Success = $false; 
                            Message = $_.Exception.Message;
                            SafeMode = $safeMode
                        }
                    }
                } -ArgumentList $path, $data.SafeMode -Name "DeleteFolder" | Out-Null
                
            } elseif ($data.Stage -eq "RemovingAttributes") {
                $job = Get-Job -Name "DeleteFolder" -ErrorAction SilentlyContinue
                
                if ($job -and $job.State -eq "Completed") {
                    $result = Receive-Job -Job $job
                    Remove-Job -Job $job
                    
                    $timer.Stop()
                    $elapsed = (Get-Date) - $data.StartTime
                    $elapsedText = "{0:mm\:ss}" -f $elapsed
                    
                    # Update UI based on result
                    if ($result.Success) {
                        $data.Status = "Success"
                        
                        if ($result.SafeMode) {
                            $statusLabel.Text = "Simulation complete - Would have deleted $($result.ItemCount) items"
                            Write-DeletionLog -Path $path -Result "Simulated" -Message "Successfully simulated deletion of $($result.ItemCount) items"
                        } else {
                            $statusLabel.Text = "Folder deleted successfully ($elapsedText)"
                            Write-DeletionLog -Path $path -Result "Success" -Message "Successfully deleted folder containing $($result.ItemCount) items"
                        }
                        
                        $item = New-Object System.Windows.Forms.ListViewItem((Get-Date).ToString("HH:mm:ss"))
                        $item.SubItems.Add($path)
                        if ($result.SafeMode) {
                            $statusText = "Simulated"
                        } else {
                            $statusText = "Success"
                        }
                        $item.SubItems.Add($statusText)
                        $item.ForeColor = $colors.ColorSuccess
                        $recentList.Items.Add($item)
                        
                        $msgTitle = if ($result.SafeMode) { "Simulation Complete" } else { "Success" }
                        [System.Windows.Forms.MessageBox]::Show($result.Message, $msgTitle, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                    } else {
                        $data.Status = "Failed"
                        $statusLabel.Text = "Error: Failed to delete folder"
                        Write-DeletionLog -Path $path -Result "Failed" -Message $result.Message
                        
                        $item = New-Object System.Windows.Forms.ListViewItem((Get-Date).ToString("HH:mm:ss"))
                        $item.SubItems.Add($path)
                        $item.SubItems.Add("Failed")
                        $item.ForeColor = $colors.ColorDanger
                        $recentList.Items.Add($item)
                        
                        [System.Windows.Forms.MessageBox]::Show("Error deleting folder: $($result.Message)", "Deletion Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    }
                    
                    # Reset UI
                    $deleteButton.Visible = $true
                    $progressPanel.Visible = $false
                    $form.Cursor = [System.Windows.Forms.Cursors]::Default
                    $confirmCheckbox.Enabled = $true
                    $confirmCheckbox.Checked = $false
                    $deleteButton.Enabled = $false
                    $browseButton.Enabled = $true
                    $clearButton.Enabled = $true
                    $pathTextBox.Enabled = $true
                    $safeModeCheckbox.Enabled = $true
                    $pathTextBox.Clear()
                    
                } elseif ($job -and $job.State -eq "Failed") {
                    # Job failed unexpectedly
                    $timer.Stop()
                    Remove-Job -Job $job -Force
                    
                    $statusLabel.Text = "Error: Internal operation failed"
                    Write-DeletionLog -Path $path -Result "InternalError" -Message "Job execution failed"
                    [System.Windows.Forms.MessageBox]::Show("The deletion operation failed unexpectedly.", "Operation Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    
                    # Reset UI
                    $deleteButton.Visible = $true
                    $progressPanel.Visible = $false
                    $form.Cursor = [System.Windows.Forms.Cursors]::Default
                    $confirmCheckbox.Enabled = $true
                    $browseButton.Enabled = $true
                    $clearButton.Enabled = $true
                    $pathTextBox.Enabled = $true
                    $safeModeCheckbox.Enabled = $true
                    
                } else {
                    # Update progress info
                    $elapsed = (Get-Date) - $data.StartTime
                    $progressDetails.Text = "Elapsed time: {0:mm\:ss}" -f $elapsed
                }
            }
        })
        
        $timer.Start()
    }
}) # End of $deleteButton.Add_Click script block

# Help menu
$helpMenu = New-Object System.Windows.Forms.MenuStrip
$helpMenu.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 252)
$helpMenu.RenderMode = "Professional"
$form.MainMenuStrip = $helpMenu
$form.Controls.Add($helpMenu)

$helpItem = New-Object System.Windows.Forms.ToolStripMenuItem
$helpItem.Text = "Help"
$helpMenu.Items.Add($helpItem)

$aboutItem = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutItem.Text = "About"
$helpItem.DropDownItems.Add($aboutItem)

$helpContentItem = New-Object System.Windows.Forms.ToolStripMenuItem
$helpContentItem.Text = "Help Contents"
$helpItem.DropDownItems.Add($helpContentItem)

$helpContentItem.Add_Click({
    # Escaped ampersand with backtick
    [System.Windows.Forms.MessageBox]::Show(
        "ForceDelete Tool Help`n`n" +
        "1. Select a folder using the Browse button or drag `& drop a folder`n" +
        "2. Check the confirmation checkbox to acknowledge permanent deletion`n" +
        "3. Click the FORCE DELETE button`n" +
        "4. Wait for the operation to complete`n`n" +
        "Security Features:`n" +
        "- Safe Mode: Test deletion without removing files`n" +
        "- System folder protection prevents accidental OS damage`n`n" +
        "Keyboard Shortcuts:`n" +
        "F1 - Show this help`n" +
        "Ctrl+B - Open browse dialog`n" +
        "Ctrl+D - Force delete (when enabled)`n" +
        "Esc - Clear path",
        "Help Contents",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
})

$aboutItem.Add_Click({
    [System.Windows.Forms.MessageBox]::Show(
        "ForceDelete Tool v1.0`n`n" + 
        "Created by: YadavNikhil03`n`n" +
        "A utility to permanently delete stubborn folders that resist normal deletion methods.`n" +
        "This tool removes read-only, hidden, and system attributes before deletion.",
        "About ForceDelete Tool",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
})

# Add keyboard shortcuts
$form.KeyPreview = $true
$form.Add_KeyDown({
    param($src, $e)
    
    # F1 - Help
    if ($e.KeyCode -eq 'F1') {
        $helpContentItem.PerformClick()
    }
    
    # Ctrl+B - Browse
    if ($e.Control -and $e.KeyCode -eq 'B') {
        $browseButton.PerformClick()
    }
    
    # Ctrl+D - Delete (if enabled)
    if ($e.Control -and $e.KeyCode -eq 'D' -and $deleteButton.Enabled) {
        $deleteButton.PerformClick()
    }
    
    # Esc - Clear path
    if ($e.KeyCode -eq 'Escape') {
        $pathTextBox.Clear()
    }
})

# Show the form
$form.BringToFront()
[void]$form.ShowDialog()