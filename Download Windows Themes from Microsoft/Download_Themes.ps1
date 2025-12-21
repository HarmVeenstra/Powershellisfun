param (
    [parameter(Mandatory = $false, HelpMessage = "Enter the destination folder to save the .Themepack files")][string]$DestinationFolder = "$ENV:OneDrive\Pictures\Theme"
)

# Define the URL of the Microsoft Themes page
$URL = "https://support.microsoft.com/en-us/windows/windows-themes-94880287-6046-1d35-6d2f-35dee759701e"

# Set ProgressPreference to SilentlyContinue to avoid download status messages
$ProgressPreference = 'SilentlyContinue'

# Fetch the HTML content of the page
$Response = Invoke-WebRequest -Uri $URL -UseBasicParsing

# Extract all links ending with .themepack or .deskthemepack
$ThemeLinks = ($Response.Links | Where-Object { $_.href -match "\.themepack$" -or $_.href -match "\.deskthemepack$" }).href

# Remove duplicate links and sort
$UniqueLinks = $ThemeLinks | Select-Object -Unique

# Folder to store themes, create it if it doesn't exist
if (-not (Test-Path -LiteralPath $DestinationFolder)) {
    try {
        New-Item -ItemType Directory -Path $destinationFolder -Force -ErrorAction Stop | Out-Null
        Write-Host ("Created specified destination folder {0}" -f $DestinationFolder) -ForegroundColor Green
    }
    catch {
        Write-Warning ("Could create destination folder {0}, check permissions. Exiting..." -f $DestinationFolder)
    }
}

# Download all .themepack files and save them to specified destination folder
foreach ($url in $UniqueLinks) {
    $FileName = Split-Path -Path $URL -Leaf
    $DestinationPath = Join-Path -Path $destinationFolder -ChildPath $FileName
    try {
        Invoke-WebRequest -Uri $URL -OutFile $destinationPath -UseBasicParsing -ErrorAction Stop
        Write-Host ("Downloading {0} to {1}" -f $FileName, $DestinationPath) -ForegroundColor Green
    }
    catch {
        Write-Warning ("Error downloading/saving {0} to {1}" -f $FileName, $DestinationFolder)
    } 
}