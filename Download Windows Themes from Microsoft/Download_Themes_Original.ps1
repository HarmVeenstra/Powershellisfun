# Define the URL of the Microsoft Themes page
$url = "https://support.microsoft.com/en-us/windows/windows-themes-94880287-6046-1d35-6d2f-35dee759701e"

# Fetch the HTML content of the page
$response = Invoke-WebRequest -Uri $url -UseBasicParsing

# Extract all links ending with .themepack or .deskthemepack
$themeLinks = ($response.Links | Where-Object { $_.href -match "\.themepack$" -or $_.href -match "\.deskthemepack$" }).href

# Display each link
# $themeLinks

# Remove duplicate links and sort
$uniqueLinks = $themeLinks | Sort-Object -Unique

# Output the links
# $uniqueLinks

# Folder to store themes
$destinationFolder = "$env:OneDrive\Pictures\Theme"
New-Item -ItemType Directory -Path $destinationFolder -Force -ErrorAction SilentlyContinue

# Download loop
foreach ($url in $uniqueLinks) 
    {
    $fileName = Split-Path -Path $url -Leaf
    $destinationPath = Join-Path -Path $destinationFolder -ChildPath $fileName

    Write-Host "Downloading $url to $destinationPath"
    Invoke-WebRequest -Uri $url -OutFile $destinationPath -ErrorAction SilentlyContinue
    }