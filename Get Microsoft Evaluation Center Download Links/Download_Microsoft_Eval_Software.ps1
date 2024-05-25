#Reset totalcount to null
$totalcount = $null
 
#Set output file location
$outputfile = 'D:\Temp\EvalCenterDownloads.csv'
 
#List of Evalution Center links with downloadable content
$urls = @(
    'https://www.microsoft.com/en-us/evalcenter/download-biztalk-server-2016',
    'https://www.microsoft.com/en-us/evalcenter/download-host-integration-server-2020',
    'https://www.microsoft.com/en-us/evalcenter/download-hyper-v-server-2016',
    'https://www.microsoft.com/en-us/evalcenter/download-hyper-v-server-2019',
    'https://www.microsoft.com/en-us/evalcenter/download-lab-kit',
    'https://www.microsoft.com/en-us/evalcenter/download-mem-evaluation-lab-kit',
    'https://www.microsoft.com/en-us/evalcenter/download-microsoft-endpoint-configuration-manager',
    'https://www.microsoft.com/en-us/evalcenter/download-microsoft-endpoint-configuration-manager-technical-preview',
    'https://www.microsoft.com/en-us/evalcenter/download-microsoft-identity-manager-2016',
    'https://www.microsoft.com/en-us/evalcenter/download-sharepoint-server-2013',
    'https://www.microsoft.com/en-us/evalcenter/download-sharepoint-server-2016',
    'https://www.microsoft.com/en-us/evalcenter/download-sharepoint-server-2019',
    'https://www.microsoft.com/en-us/evalcenter/download-skype-business-server-2019',
    'https://www.microsoft.com/en-us/evalcenter/download-sql-server-2016',
    'https://www.microsoft.com/en-us/evalcenter/download-sql-server-2017-rtm',
    'https://www.microsoft.com/en-us/evalcenter/download-sql-server-2019',
    'https://www.microsoft.com/en-us/evalcenter/download-system-center-2019',
    'https://www.microsoft.com/en-us/evalcenter/download-system-center-2022',
    'https://www.microsoft.com/en-us/evalcenter/download-windows-10-enterprise',
    'https://www.microsoft.com/en-us/evalcenter/download-windows-11-enterprise',
    'https://www.microsoft.com/en-us/evalcenter/download-windows-11-office-365-lab-kit',
    'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2012-r2',
    'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2012-r2-essentials',
    'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2012-r2-essentials',
    'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2016',
    'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2016-essentials',
    'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2019',
    'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2019-essentials',
    'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022'
)
 
#Loop through the urls, search for download links and add to totalfound array and display number of downloads
$ProgressPreference = "SilentlyContinue"
$totalfound = foreach ($url in $urls) {
    try {
        $content = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop 
        $downloadlinks = $content.links | Where-Object { `
                $_.'aria-label' -match 'Download' `
                -and $_.outerHTML -match 'fwlink' `
                -or $_.'aria-label' -match '64-bit edition' }    
        $count = $DownloadLinks.href.Count
        $totalcount += $count
        Write-host ("Processing {0}, Found {1} Download(s)..." -f $url, $count) -ForegroundColor Green
        foreach ($DownloadLink in $DownloadLinks) {
            [PSCustomObject]@{
                Title  = $url.split('/')[5].replace('-', ' ').replace('download ', '')
                Name   = $DownloadLink.'aria-label'.Replace('Download ', '')
                Tag    = $DownloadLink.'data-bi-tags'.Split('&')[3].split(';')[1]
                Format = $DownloadLink.'data-bi-tags'.Split('-')[1].ToUpper()
                Link   = $DownloadLink.href
            }
        }
    }
    catch {
        Write-Warning ("{0} is not accessible" -f $url)
    }
}


#Output total downloads found and exports result to the $outputfile path specified
Write-Host ("Found a total of {0} Downloads" -f $totalcount) -ForegroundColor Green
$totalfound | Sort-Object Title, Name, Tag, Format | Export-Csv -NoTypeInformation -Encoding UTF8 -Delimiter ';' -Path $outputfile