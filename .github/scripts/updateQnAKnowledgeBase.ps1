param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    $QnAName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    $projectName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    $subscriptionKey,
            
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    $faqFolderPath
)

function Update-KnowledgeBase {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $QnAName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $projectName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $subscriptionKey,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.ArrayList]
        $sources,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.ArrayList]
        $questions
    )

    $body = [System.Collections.ArrayList]::new()

    foreach ($source in $sources) {
        $body.Add(@{
                "op"    = "delete"
                "value" = @{
                    "source" = "$source"
                }
            })
    }

    if ($body.Count -gt 0) {
        Invoke-RestMethod -Uri "https://$($QnAName)-language.cognitiveservices.azure.com/language/query-knowledgebases/projects/$($projectName)/sources?api-version=2021-10-01" -Method PATCH -Headers @{"Ocp-Apim-Subscription-Key" = "$subscriptionKey"; "Content-Type" = "application/json" } -ContentType "application/json" -Body $($body | ConvertTo-Json)
        Start-Sleep -s 20
    }

    $body = [System.Collections.ArrayList]::new()

    foreach ($question in $questions) {
        $body.Add(@{
                "op"    = "add"
                "value" = $question
            })
    }

    $body = ConvertTo-json ($body) -Depth 6
    Write-Output ($body)

    Invoke-RestMethod -Uri "https://$($QnAName)-language.cognitiveservices.azure.com/language/query-knowledgebases/projects/$($projectName)/qnas?api-version=2021-10-01" -Method PATCH -Headers @{"Ocp-Apim-Subscription-Key" = "$subscriptionKey"; "Content-Type" = "application/json" } -ContentType "application/json" -Body $body
        
    Start-Sleep -s 40

    Invoke-RestMethod -Uri "https://$($QnAName)-language.cognitiveservices.azure.com/language/query-knowledgebases/projects/$($projectName)/deployments/production?api-version=2021-10-01" -Method PUT -Headers @{"Ocp-Apim-Subscription-Key" = "$subscriptionKey"; "Content-Type" = "application/json" }
}

$faq_files_updated = Get-ChildItem -Path $faqFolderPath -Name -Include *.md
$sources = [System.Collections.ArrayList]::new()
$questions = [System.Collections.ArrayList]::new()

foreach ($faqFile in $faq_files_updated) {

    Write-Host "Scanning FAQ file $faqFile"
    #Get questions from FAQ file
    $fileName = $faqFile.Split('.md')[0];
    $file = "$faqFolderPath/$faqFile"
    foreach ($line in Get-Content $file) {
        if ($line -match '<!-- Question -->') {
            $question = @{ "questions" = @(''); "answer" = ''; "source" = "$fileName"; "metadata" = @{}; "dialog" = @{"isContextOnly" = $false; "prompts" = @() } }
        }
        elseif ($line -match "Question:") {
            $primaryQuestion = ($line.Split(': ')[1]).Split('**')[0]
            $allQuestions = [System.Collections.ArrayList]::new()
            $allQuestions.Add("$primaryQuestion")
            $question.questions = $allQuestions
        }
        elseif ($line -match '<!-- Answer -->') {
            $answer = ""
        }
        elseif ($line -match '<!-- Answer End -->') {
            $question.answer = "$answer"
            if ($answer -ne "") {
                $questions.Add($question)
            }
        }
        else {
            $answer = $answer + $line + "`r`n"
        }
    }

    $sources.Add("$fileName")
}

Update-KnowledgeBase "$QnAName" "$projectName" "$subscriptionKey" $sources $questions