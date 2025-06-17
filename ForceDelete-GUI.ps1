Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Test-SystemFolder {
    param([string]$Path)
    $systemPaths = @(
        $env:SystemRoot,
        "$env:SystemRoot\System32",
        "$env:ProgramFiles",
        ${env:ProgramFiles(x86)},
        $env:ProgramData
    )
    foreach ($systemPath in $systemPaths) {
        if ($Path -eq $systemPath) { return $true }
    }
    return $false
}

function Write-DeletionLog {
    param($Path, $Success, $ErrorInfo)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logFolder = "$env:USERPROFILE\AppData\Local\ForceDeleteTool"
    $logFile = "$logFolder\deletion_log.csv"
    
    if (-not (Test-Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path $logFile)) {
        "Timestamp,Path,Success,ErrorInfo" | Out-File -FilePath $logFile
    }
    
    "$timestamp,`"$Path`",$Success,`"$ErrorInfo`"" | Out-File -FilePath $logFile -Append
}

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "ForceDelete Tool"
$form.Size = New-Object System.Drawing.Size(600, 400)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 246, 250)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# Title
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "ForceDelete Tool"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(13, 110, 253)
$titleLabel.AutoSize = $false
$titleLabel.Size = New-Object System.Drawing.Size(400, 40)
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$form.Controls.Add($titleLabel)

# Description
$descLabel = New-Object System.Windows.Forms.Label
$descLabel.Text = "Delete stubborn files and folders that resist normal deletion"
$descLabel.Size = New-Object System.Drawing.Size(560, 30)
$descLabel.Location = New-Object System.Drawing.Point(20, 60)
$form.Controls.Add($descLabel)

# Path Label
$pathLabel = New-Object System.Windows.Forms.Label
$pathLabel.Text = "Target Path:"
$pathLabel.Size = New-Object System.Drawing.Size(100, 25)
$pathLabel.Location = New-Object System.Drawing.Point(20, 100)
$form.Controls.Add($pathLabel)

# Path TextBox
$pathTextBox = New-Object System.Windows.Forms.TextBox
$pathTextBox.Size = New-Object System.Drawing.Size(400, 25)
$pathTextBox.Location = New-Object System.Drawing.Point(20, 125)
$form.Controls.Add($pathTextBox)

# Browse Button
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse"
$browseButton.Size = New-Object System.Drawing.Size(80, 25)
$browseButton.Location = New-Object System.Drawing.Point(430, 125)
$browseButton.BackColor = [System.Drawing.Color]::FromArgb(13, 110, 253)
$browseButton.ForeColor = [System.Drawing.Color]::White
$browseButton.FlatStyle = "Flat"
$form.Controls.Add($browseButton)

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Enter a path and check the confirmation box below."
$statusLabel.Size = New-Object System.Drawing.Size(560, 25)
$statusLabel.Location = New-Object System.Drawing.Point(20, 160)
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
$form.Controls.Add($statusLabel)

# Confirmation Checkbox
$confirmCheckbox = New-Object System.Windows.Forms.CheckBox
$confirmCheckbox.Text = "I understand this will permanently delete the selected item"
$confirmCheckbox.Size = New-Object System.Drawing.Size(560, 25)
$confirmCheckbox.Location = New-Object System.Drawing.Point(20, 190)
$form.Controls.Add($confirmCheckbox)

# Delete Button
$deleteButton = New-Object System.Windows.Forms.Button
$deleteButton.Text = "FORCE DELETE"
$deleteButton.Size = New-Object System.Drawing.Size(200, 40)
$deleteButton.Location = New-Object System.Drawing.Point(200, 230)
$deleteButton.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
$deleteButton.ForeColor = [System.Drawing.Color]::White
$deleteButton.FlatStyle = "Flat"
$deleteButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$deleteButton.Enabled = $false
$form.Controls.Add($deleteButton)

# Update button state function
function Update-ButtonState {
    if (-not [string]::IsNullOrWhiteSpace($pathTextBox.Text) -and $confirmCheckbox.Checked) {
        $deleteButton.Enabled = $true
        $statusLabel.Text = "Ready to delete. Press Force Delete to continue."
    } else {
        $deleteButton.Enabled = $false
        if ([string]::IsNullOrWhiteSpace($pathTextBox.Text)) {
            $statusLabel.Text = "Enter a path to continue."
        } elseif (-not $confirmCheckbox.Checked) {
            $statusLabel.Text = "Check the confirmation box to enable deletion."
        }
    }
}

# Event handlers
$pathTextBox.Add_TextChanged({ Update-ButtonState })
$confirmCheckbox.Add_CheckedChanged({ Update-ButtonState })

$browseButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select folder to delete"
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $pathTextBox.Text = $folderBrowser.SelectedPath
        Update-ButtonState
    }
})

$deleteButton.Add_Click({
    $targetPath = $pathTextBox.Text.Trim()
    
    if (-not (Test-Path -Path $targetPath)) {
        [System.Windows.Forms.MessageBox]::Show("The specified path does not exist.", "Error")
        return
    }
    
    if (Test-SystemFolder -Path $targetPath) {
        [System.Windows.Forms.MessageBox]::Show("Cannot delete system folders for safety reasons.", "Error")
        return
    }
    
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to force delete '$targetPath'? This action cannot be undone.",
        "Confirm Deletion", 
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($result -eq "Yes") {
        try {
            $statusLabel.Text = "Deleting... Please wait."
            $form.Refresh()
            
            if (Test-Path -Path $targetPath -PathType Container) {
                $items = Get-ChildItem -Path $targetPath -Force -Recurse -ErrorAction SilentlyContinue
                foreach ($item in $items) {
                    $item.Attributes = "Normal"
                }
                Remove-Item -Path $targetPath -Recurse -Force
            } else {
                $item = Get-Item -Path $targetPath -Force
                $item.Attributes = "Normal"
                Remove-Item -Path $targetPath -Force
            }
            
            Write-DeletionLog -Path $targetPath -Success $true -ErrorInfo "None"
            [System.Windows.Forms.MessageBox]::Show("Deletion completed successfully.", "Success")
            $pathTextBox.Text = ""
            $confirmCheckbox.Checked = $false
            Update-ButtonState
        }
        catch {
            Write-DeletionLog -Path $targetPath -Success $false -ErrorInfo $_.Exception.Message
            [System.Windows.Forms.MessageBox]::Show("Error deleting: $($_.Exception.Message)", "Error")
            $statusLabel.Text = "Deletion failed. Try running as administrator."
        }
    }
})

$form.Add_KeyDown({
    if ($_.KeyCode -eq "D" -and $_.Control -and $deleteButton.Enabled) {
        $deleteButton.PerformClick()
    }
})

# Show form
[void]$form.ShowDialog()