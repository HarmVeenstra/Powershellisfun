<#
.SYNOPSIS
  
Gets a random picture or movieclip from 9Gag using PowerShell and launches it in your browser (Except when NSFW ;) )
  
.DESCRIPTION
  
Gets a random picture or movieclip from 9Gag using PowerShell and launches it in your browser (Except when NSFW ;) )
  
.PARAMETER Funny
Get a random Funny category item in your browser
  
.PARAMETER Meme
Get a random Meme category item in your browser
 
.PARAMETER Random
Get a random Random category item in your browser
 
.PARAMETER WTF
Get a random WTF category item in your browser
 
.INPUTS
  
Defaults to Random unless Funny, Random or WTF parameter was specified
  
.OUTPUTS
  
Random 9Gag item in your browser
  
.EXAMPLE
  
PS> Get_Meme.ps1
Get a 9Gag Random category item in your browser
  
.EXAMPLE
  
PS> Get_Meme.ps1 -WTF
Get a 9Gaf WTF category item in your browser
  
.LINK
  
https://powershellisfun.com
  
#>
  
#Parameters
[CmdletBinding(DefaultParameterSetName = "Random")]
param (
    [Parameter(Mandatory = $False, HelpMessage = "Get a 9GAG random Funny category item in your browser", ParameterSetName = "Funny")][Switch]$Funny,
    [Parameter(Mandatory = $false, HelpMessage = "Get a random 9GAG Meme category item in your browser", ParameterSetName = "Meme")][Switch]$Meme,
    [Parameter(Mandatory = $false, HelpMessage = "Get a 9GAG random WTF category item in your browser", ParameterSetName = "WTF")][Switch]$WTF
)
$selection = $PSCmdlet.ParameterSetName
$ProgressPreference = "SilentlyContinue"
$contents = Invoke-WebRequest -Uri "https://9gagrss.xyz/json.php?channel=$($selection)&limit=100"
$number = Get-Random -Minimum 1 -Maximum 101
$9gag = ($contents | convertfrom-json).data.posts[$number]
 
if ($9gag.nsfw -eq '1' ) {
    Write-Host ("Get_9GAG found a NSFW Picture/Movieclip, skipping because NSFW ;)") -ForegroundColor Yellow
    exit
}
 
Write-Host ("Get_9GAG found '{0}', launching now..." -f $9gag.title) -ForegroundColor Green
 
try {
    Start-Process $9gag.content_url
}
catch {
    Write-Warning ("Error loading, please try again...")
} 