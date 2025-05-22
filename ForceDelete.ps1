Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Main Form Configuration
$form = New-Object System.Windows.Forms.Form
$form.Text = "ForceDelete Tool"
$form.Size = New-Object System.Drawing.Size(520, 240)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(230, 240, 255) 
$form.Padding = New-Object System.Windows.Forms.Padding(15)

# Title Panel (Header)
$titlePanel = New-Object System.Windows.Forms.Panel
$titlePanel.Location = New-Object System.Drawing.Point(0, 0)
$titlePanel.Size = New-Object System.Drawing.Size(520, 10)
$titlePanel.BackColor = [System.Drawing.Color]::FromArgb(65, 105, 225) 
$form.Controls.Add($titlePanel)

# Folder Path Label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Folder path to delete:"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(20, 25)
$label.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$label.ForeColor = [System.Drawing.Color]::FromArgb(25, 25, 112)  
$form.Controls.Add($label)

# Folder Path TextBox
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(20, 50)
$textBox.Size = New-Object System.Drawing.Size(380, 25)
$textBox.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$textBox.BackColor = [System.Drawing.Color]::White
$textBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$textBox.ForeColor = [System.Drawing.Color]::FromArgb(0, 0, 128) 
$form.Controls.Add($textBox)

# Browse Button
$browseBtn = New-Object System.Windows.Forms.Button
$browseBtn.Text = "Browse"
$browseBtn.Location = New-Object System.Drawing.Point(410, 50)
$browseBtn.Size = New-Object System.Drawing.Size(80, 25)
$browseBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$browseBtn.BackColor = [System.Drawing.Color]::FromArgb(100, 149, 237)  
$browseBtn.ForeColor = [System.Drawing.Color]::White
$browseBtn.FlatStyle = 'Flat'
$browseBtn.FlatAppearance.BorderSize = 0
$browseBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($browseBtn)

$browseBtn.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderDialog.ShowDialog() -eq "OK") {
        $textBox.Text = $folderDialog.SelectedPath
    }
})

# Delete Button
$deleteBtn = New-Object System.Windows.Forms.Button
$deleteBtn.Text = "Force Delete"
$deleteBtn.Location = New-Object System.Drawing.Point(200, 95)
$deleteBtn.Size = New-Object System.Drawing.Size(120, 35)
$deleteBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$deleteBtn.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)  
$deleteBtn.ForeColor = [System.Drawing.Color]::White
$deleteBtn.FlatStyle = 'Flat'
$deleteBtn.FlatAppearance.BorderSize = 0
$deleteBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($deleteBtn)

$deleteBtn.Add_Click({
    $path = $textBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path $path)) {
        [System.Windows.Forms.MessageBox]::Show("Path doesn't exist or is empty.", "Error", "OK", "Error")
        $statusLabel.Text = "Error: Invalid path"
        $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)  
        return
    }

    $confirm = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to permanently delete this folder?`n`n$path", "Confirm Delete", "YesNo", "Warning")
    if ($confirm -ne "Yes") { 
        $statusLabel.Text = "Deletion cancelled"
        $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 153, 0) 
        return 
    }

    $statusLabel.Text = "Deleting folder..."
    $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 123, 255) 
    $form.Refresh()
    
    try {
        attrib -r -h -s "$path" /S /D | Out-Null
        Remove-Item -LiteralPath "$path" -Recurse -Force -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show("Folder deleted successfully!", "Success")
        $textBox.Clear()
        $statusLabel.Text = "Folder deleted successfully"
        $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(40, 167, 69) 
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error deleting folder:`n$_", "Deletion Error")
        $statusLabel.Text = "Error: Failed to delete folder"
        $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)  
    }
})

# Help Button
$helpBtn = New-Object System.Windows.Forms.Button
$helpBtn.Text = "Help"
$helpBtn.Location = New-Object System.Drawing.Point(20, 160)
$helpBtn.Size = New-Object System.Drawing.Size(60, 25)
$helpBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$helpBtn.BackColor = [System.Drawing.Color]::FromArgb(255, 193, 7)  
$helpBtn.ForeColor = [System.Drawing.Color]::FromArgb(33, 37, 41) 
$helpBtn.FlatStyle = 'Flat'
$helpBtn.FlatAppearance.BorderSize = 0
$helpBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($helpBtn)

$helpBtn.Add_Click({
    [System.Windows.Forms.MessageBox]::Show(
        "This tool helps force delete stubborn folders.`n`n1. Select a folder using the Browse button or type the path manually.`n2. Click 'Force Delete'.`n3. Confirm deletion.`n`nIt will remove read-only and hidden attributes before deleting.",
        "Help")
})

# Status Label (for feedback)
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(90, 165)
$statusLabel.Size = New-Object System.Drawing.Size(400, 25) 
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(40, 167, 69)  
$statusLabel.Text = "Ready to delete folders"
$form.Controls.Add($statusLabel)

# Bottom accent
$bottomPanel = New-Object System.Windows.Forms.Panel
$bottomPanel.Location = New-Object System.Drawing.Point(0, 200)
$bottomPanel.Size = New-Object System.Drawing.Size(520, 10)
$bottomPanel.BackColor = [System.Drawing.Color]::FromArgb(65, 105, 225) 
$form.Controls.Add($bottomPanel)

# Run the Form
$form.Topmost = $true
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
