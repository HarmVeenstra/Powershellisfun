Function Out-MarkDown {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]$InputObject,
        [parameter(Mandatory = $false, Position = 1)][string]$OutputFile,
        [switch]$Overwrite
    )

    Begin {
        #Remove the # below and configure the default location for the outputfile
        #$outputfile = 'c:\Data\powershellisfun.md'

        #Remove the # below and configure the default to overwrite the existing file
        #$overwrite = $true
        
        #Exit if $outputfile was not configured or used
        if (-not $OutputFile) {
            Write-Warning ("The -Outputfile parameter was not used, or the outputfile variable was not set at the top of the script. Exiting...")
            break
        }
                
        #Validate write access to specified $OutputFile location if Overwrite switch was used
        if ((Test-Path -Path $OutputFile) -and $Overwrite) {
            try {
                New-Item -Path $OutputFile -ItemType File -force:$Overwrite -ErrorAction Stop | Out-Null
                Write-Host ("Overwriting existing file {0}" -f $OutputFile) -ForegroundColor Green
            }
            catch {
                Write-Warning ("Couldn't overwrite {0}, please check path/permissions or if the file is locked. Exiting..." -f $OutputFile)
                break
            }
        }

        #Validate if $outputfile is an existing file or a new file, and if the Overwrite switch was not used
        if ((Test-Path -Path $OutputFile) -and -not $Overwrite) {
            Write-Host ("Appending pipeline input to existing file {0}" -f $OutputFile) -ForegroundColor Green
        }
        else {
            Write-Host ("Saving pipeline input to file {0}" -f $OutputFile) -ForegroundColor Green
        }

        #Set codeblock back-ticks in $codeblock, an empty line in $emptyline and horizontal line in $horizontalline variable
        $codeblock = "``````"
        $emptyline = ""
        $horizontalline = "___"

        #Add time-stamp header to outputfile and the data from Pipeline in a codeblock
        ("{0}" -f $emptyline) | Out-File -FilePath $OutputFile -Encoding utf8 -Append -Width 1024
        ("{0}" -f $horizontalline) | Out-File -FilePath $OutputFile -Encoding utf8 -Append -Width 1024
        ("# Data added using Out-MarkDown.ps1 on {0}" -f $(Get-Date -Format "dd-mm-yyyy HH:mm:ss")) | Out-File -FilePath $OutputFile -Encoding utf8 -Append -Width 1024
        ("{0}" -f $codeblock) | Out-File -FilePath $OutputFile -Encoding utf8 -Append -Width 1024

    }

    Process {
        $InputObject | Out-File -FilePath $OutputFile -Append -Encoding utf8 -Width 1024
    }

    End {
        #Add end of codeblock to file and exit
        ("{0}" -f $codeblock) | Out-File -FilePath $OutputFile -Encoding utf8 -Append -Width 1024
        ("{0}" -f $horizontalline) | Out-File -FilePath $OutputFile -Encoding utf8 -Append -Width 1024
        ("{0}" -f $emptyline) | Out-File -FilePath $OutputFile -Encoding utf8 -Append -Width 1024
        Write-Host ("Done, exported data to {0}" -f $OutputFile) -ForegroundColor Green
    }
}