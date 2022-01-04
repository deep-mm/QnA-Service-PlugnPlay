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
    $question,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    $subscriptionKey
)

$question = $question.Replace('@bot', '');

$body = @{"top"                  = 1
    "question"                   = "$question"
    "includeUnstructuredSources" = $true
    "confidenceScoreThreshold"   = 0
}

$response = Invoke-RestMethod -Uri "https://$($QnAName)-language.cognitiveservices.azure.com/language/:query-knowledgebases/?projectName=$($projectName)&api-version=2021-10-01&deploymentName=production" -Method POST -Headers @{"Ocp-Apim-Subscription-Key" = "$subscriptionKey"; "Content-Type" = "application/json" } -ContentType "application/json" -Body $($body | ConvertTo-Json)

Write-Output($response.answers[0].answer);
echo "::set-output name=answer::$($response.answers[0].answer)"