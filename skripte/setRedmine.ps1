param ([int] $parentID)

$key = 'bf1d31917b5d1c2a2a225f7e68efbc971cd6ba49'
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add('X-Redmine-API-Key', $key)
$headers.add('charset', 'utf-8')
$headers.add('Content-Type', 'application/json')

$projectID = 91
$trackerID = 19
$userID = 256

$tr1 = Invoke-RestMethod -Uri "https://redmine.acdh.oeaw.ac.at/projects/91/issues.json?limit=50&parent_id=$parentID" -Headers $headers -Method Get
$num = $tr1.issues.Count
$i = 0

"Update redmine issues..."
$tr1.issues | % {
    $i++
    $id = $_.id
"    [$i/$num] $id"
    
    # status values:
    # 24 = HTRfertig; 17=Kollationiert; 15=needs review; 14=published
    
    $issue = @{
        issue=@{
            status_id=24
        }
    } | ConvertTo-Json -Depth 3
    
    $res = Invoke-RestMethod -Uri "https://redmine.acdh.oeaw.ac.at/issues/$id.json" -Headers $headers -Method Put -Body $issue
}