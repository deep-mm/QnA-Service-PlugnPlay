param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    $QnAEndpoint,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    $KnowledgeBaseId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    $subscriptionKey,
            
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Collections.ArrayList]
    $updatedFiles
)

function Update-KnowledgeBase {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $QnAEndpoint,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $KnowledgeBaseId,

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

    $body = @{"delete" = @{
            "sources" = $sources
        };
        "add"          = @{
            "qnaList" = $questions
        }
    }

    $body = ConvertTo-json ($body) -Depth 6

    Write-Host $($body)
        
    Invoke-RestMethod -Uri "$($QnAEndpoint)qnamaker/v4.0/knowledgebases/$KnowledgeBaseId" -Method PATCH -Headers @{"Ocp-Apim-Subscription-Key" = "$subscriptionKey"; "Content-Type" = "application/json" } -Body $($body) -ContentType "application/json"

    Start-Sleep -s 180
    #Call Publish API
    Invoke-RestMethod -Uri "$($QnAEndpoint)qnamaker/v4.0/knowledgebases/$KnowledgeBaseId" -Method POST -Headers @{"Ocp-Apim-Subscription-Key" = "$subscriptionKey"; "Content-Type" = "application/json" } -ContentType "application/json"
}

$faq_files_updated = $updatedFiles
$sources = [System.Collections.ArrayList]::new()
$questions = [System.Collections.ArrayList]::new()

$context = @{ "isContextOnly" = $false; "prompts" = @(@{"displayOrder" = 1; "qnaId" = 213; "displayText" = 'Improve Answer' }, @{"displayOrder" = 2; "qnaId" = 214; "displayText" = 'Not satisfied with the answer? Ask Experts' }) }

foreach ($faqFile in $faq_files_updated) {

    Write-Host "Scanning FAQ file $faqFile"
    #Get questions from FAQ file
    $file = "$faqFile"
    $fileName = $file.Split('\')[-1].Split('.')[0]
    foreach ($line in Get-Content $file) {
        if ($line -match '<!-- Question -->') {
            $question = @{ "questions" = @(''); "answer" = ''; "source" = "$fileName"; "metadata" = @(); "context" = $context }
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

$result = Update-KnowledgeBase "$QnAEndpoint" "$KnowledgeBaseId" "$subscriptionKey" $sources $questions
if ($null -eq $result.operationId) {
    Write-Host "Failed"
}
else {
    Write-Host "Success"
}