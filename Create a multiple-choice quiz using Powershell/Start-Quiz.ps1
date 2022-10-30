param (
    [Parameter(Mandatory = $true, HelpMessage = "Enter the complete path to the .xlsx")][string]$FilePath,
    [Parameter(Mandatory = $false, HelpMessage = "Skip the ImportExcel module check")][switch]$SkipImportExcelModuleCheck
)
    
#Validate complete path and extension of the file
if (-not (Test-Path $FilePath)) {
    Write-Warning ("Specified file {0} can't be found or accessed, check path and permissions...." -f $FilePath)
    return
}
else {
    Write-Host ("Specified file {0} found, continuing..." -f $FilePath) -ForegroundColor Green
}

if (-not ($FilePath.EndsWith('.xlsx'))) {
    Write-Warning ("Specified file {0} has no .xlsx extension, exiting..." -f $FilePath)
    return
}

#Check if ImportExcel module is installed if not skipped by NoImportExcelModuleCheck parameter
if (-not ($SkipImportExcelModuleCheck)) {
    Write-Host ("Checking if ImportExcel module is installed...") -ForegroundColor Green
    if (-not (Get-Module -ListAvailable | Where-Object Name -Match 'ImportExcel')) {
        Write-Warning ("Required ImportExcel module is not installed, installing now...")
        Install-Module -Name ImportExcel -SkipPublisherCheck:$true -Force:$true
    }
}

#Read questions into $questions variable
$questions = Import-Excel -Path $FilePath -ErrorAction SilentlyContinue
if ($questions.question -and $questions.CorrectAnswer) {
    Write-Host ("{0} Questions imported..." -f $questions.Count) -ForegroundColor Green
}
else {
    Write-Warning ("Error importing {0}, check the format in the file or if ImportExcel module is installed. Exiting..." -f $FilePath)
    return
}
    
#Start quiz
$goodanswers = 0
$badanswers = 0
$totalquestions = $questions.Count
$currentquestionnumber = 1
Write-Host ("Starting quiz...") -ForegroundColor Green
Pause
Clear-Host

#Loop through questions from the Excel file and show the score when done
foreach ($question in $questions) {
    Clear-Host
    Write-Host ("Question {0} of {1}" -f $currentquestionnumber, $totalquestions)
    Write-Host ("$($question.question)")
    Write-Host ("`n")
    Write-Host ("Answer A: {0}" -f $question.AnswerA)
    Write-Host ("Answer B: {0}" -f $question.AnswerB)
    Write-Host ("Answer C: {0}" -f $question.AnswerC)
    Write-Host ("Answer D: {0}" -f $question.AnswerD)
    Write-Host ("`n")
    Write-Host ("Type A,B,C or D to answer the question")

    #Wait until a,b,c or d is pressed
    do {
        $key = [Console]::ReadKey($true)
        $value = $key.KeyChar
        switch ($value) {
            a { $answer = 'a' }
            b { $answer = 'b' }
            c { $answer = 'c' }
            d { $answer = 'd' }
        }
    }
    while ($value -notmatch 'a|b|c|d')
       
    #Check if the answer is correct
    if ($answer -eq $question.CorrectAnswer) {
        Write-Host ("Correct! {0} is the correct answer`n" -f $question.CorrectAnswer) -ForegroundColor Green -NoNewline
        $goodanswers++
        pause
    }
    else {
        Write-Warning ("Incorrect! {0} is the correct answer`n" -f $question.CorrectAnswer)
        $badanswers++
        pause
    }
    $currentquestionnumber++
}
    
#Display totals
Clear-Host
Write-Host ("Your results are:`n`n{0} correctly answered`n{1} incorrectly answered`n`n" -f $goodanswers, $badanswers) -ForegroundColor Green