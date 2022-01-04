param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    $QnAName = "qna-maker-ip",

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    $projectName = "qna-maker-ip",

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    $subscriptionKey = "09fdb01632734be2bf0c7754b1d52ac7"
)

$body = @{"defaultAnswer" = "Sorry, I cannot help you with that right now"
    "language"   = "en"
    "multilingualResource" = $false
    "name" = $projectName
    "projectName" = $projectName
    "settings" = @{
        "defaultAnswer" = "Sorry, I cannot help you with that right now"
    }
}

Invoke-RestMethod -Uri "https://$($QnAName)-language.cognitiveservices.azure.com/language/query-knowledgebases/projects/$($projectName)?api-version=2021-10-01" -Method PATCH -Headers @{"Ocp-Apim-Subscription-Key" = "$subscriptionKey"; "Content-Type" = "application/json" } -ContentType "application/json" -Body $($body | ConvertTo-Json)

Start-Sleep -s 60

#"files"      = @( @{
#    "fileName"       = "qna_chitchat_Friendly.tsv"
#    "fileUri"        = "https://qnamakerstore.blob.core.windows.net/qnamakerdata/editorial/english/qna_chitchat_friendly.tsv"
#    "isUnstructured" = $false
#} )

#$knowledgeBases = (Invoke-RestMethod -Uri "$($QnAEndpoint)qnamaker/v4.0/knowledgebases" -Method GET -Headers @{"Ocp-Apim-Subscription-Key" = "$subscriptionKey"; "Content-Type" = "application/json" }).knowledgebases | Sort-Object -Property createdTimestamp -Descending
#$knowledgeBaseId = $knowledgeBases[0].id
#
#Write-Output($knowledgeBaseId);