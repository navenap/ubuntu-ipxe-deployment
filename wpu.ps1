# 1. Configuration - Use the credentials from your manual [cite: 704, 1237]
$ServerIP   = "10.130.50.4"
$SharePath  = "\\$ServerIP\BootShare"
$User       = "smbuser"
$Password   = '$Amb@'  # Use the password from your setup [cite: 384]

# Define Paths (Using your Samba share)
$WimPath = "$SharePath\wpu\install.wim"
$WimPath1 = "$SharePath\wpu\clean_install.wim" # Optional: for backup before modification
$MountDir = "C:\mount" # Temporary mount point
$UpdateDir = "C:\packages\update" # Place your downloaded .msu files here

# 2. Authenticate to the Ubuntu Samba Share [cite: 1268]
Write-Host "Connecting to Samba Share..." -ForegroundColor Cyan
# Clear any old sessions first to avoid Error 86
net use $SharePath /delete /y
net use $SharePath /user:$User $Password /persistent:no

# 3. Create Mount Directory if missing
if (!(Test-Path $MountDir)) { New-Item -ItemType Directory $MountDir }

# 4. Mount the WIM (Index 1 for Pro)
Write-Host "Mounting Image..." -ForegroundColor Cyan
dism /Mount-Wim /WimFile:$WimPath /Index:1 /MountDir:$MountDir

# 5. Inject all updates in the folder
Write-Host "Injecting packages..." -ForegroundColor Green
dism /Image:$MountDir /Add-Package /PackagePath:$UpdateDir

# 6. Old component cleanup (optional but recommended)
Write-Host "Cleaning up old components..." -ForegroundColor Green
dism /Image:$MountDir /Cleanup-Image /StartComponentCleanup

# 7. Commit and Unmount
Write-Host "Saving changes and Unmounting..." -ForegroundColor Yellow
dism /Unmount-Wim /MountDir:$MountDir /Commit

#8. compress the updated WIM (optional, but reduces size)
Write-Host "Compressing the updated WIM..." -ForegroundColor Yellow
dism /Export-Image /SourceImageFile:$WimPath /SourceIndex:1 /DestinationImageFile:$WimPath1 /Compress:max /CheckIntegrity

# 8. Disconnect Share
net use $SharePath /delete /y
