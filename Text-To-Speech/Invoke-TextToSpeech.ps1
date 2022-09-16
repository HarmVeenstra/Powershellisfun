function Invoke-TextToSpeech {
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)][ValidateNotNullOrEmpty()][string]$Text,
        [parameter(Mandatory = $false)][string]$Computername
    )
    
    #If Computername is not specified, run local convert text to speech and output it
    if (-not $Computername) {
        try {
            Add-Type -AssemblyName System.Speech
            $synth = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
            $synth.Speak($text)
        }
        catch {
            Write-Warning ("Could not output text to speech")
        }
    }

    #try to connect to remote computer, convert to speech and output it
    if ($computername) {
        try {
            Invoke-Command -ScriptBlock {
                Add-Type -AssemblyName System.Speech
                $synth = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
                $synth.Speak($Using:Computername)
            } -ComputerName $Computername -ErrorAction Stop
        }
        catch {
            Write-Warning ("Could not connect to {0}" -f $Computername)
        }
    }
}