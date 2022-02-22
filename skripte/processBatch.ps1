<#
 # in $dir, we need a JSON array
 #>
param([string] $dir)

# redmine login data
$key = 'bf1d31917b5d1c2a2a225f7e68efbc971cd6ba49'
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add('X-Redmine-API-Key', $key)
$headers.add('charset', 'utf-8')
$headers.add('Content-Type', 'application/json')

# Digitarium login data
$dServer = "https://diarium-reporting-exist.minerva.arz.oeaw.ac.at"
$dLogin = "$dServer/exist/apps/edoc/login"

"Log in to Transkribus"
# log in to Transkribus REST service
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $tLoginRes = Invoke-RestMethod -Uri https://transkribus.eu/TrpServer/rest/auth/login -Body "user=dario.kampkaspar@oeaw.ac.at&pw=21ec2020" -Method Post -SessionVariable trpsession

"Log in to Diarium"
    $dLoginRes = Invoke-RestMethod -Uri $dLogin -Method Post -SessionVariable diasession -Body "user=kampkaspar&password=21Ec2020"

# some frequently used variables (Transkribus)
$collectionId = 448
$mdReq = "https://transkribus.eu/TrpServer/rest/jobs/list"
$pullRequest = "https://transkribus.eu/TrpServer/rest/collections/$collectionId/"
$pars = @{
	"doWriteMets"="false"
	"doWriteImages"="false"
	"doExportPageXml"="false"
	"doExpoertAltoXml"="false"
	"doWriteTei"="true"
	"doTeiWithZonePerRegion"="true"
	"doTeiWithZonePerLine"="true"
	"doTeiWithLineTags"="false"
	"doTeiWithLineBreaks"="true"
}

# some more FUV (redmine)
$projectID = 91
$trackerID = 19
$userID = 256

<#
	1. download
	2. setRedmine
	3. upload to IIIF
	4. setstatus in Transkribus (takes a long time, is not incredibly important
#>

"Preparing..."
mkdir temp
$newfile = New-Item temp/temp.zip -force

"Trying to get documentIDs..."
# TODO später aus 100-done.json übernehmen
$oldStatus = Get-Content $dir/11-post-htr-status.json | ConvertFrom-Json
$ids = $oldStatus | Sort-Object { $_.docId }

$from = $ids[0].id
$to = $ids[$ids.Count - 1].id
$count = $ids.Count

$i = 0
"processing docs $from to $to"
$ids | % {
    $i++
    $docId = $_.docId
    $name = $_.name
    
    "[$i/$count]"
    "    documentID: $docId, name: $name"
    
    # TODO später aus 100-done.json übernehmen
    $issue = Invoke-RestMethod -Uri "https://redmine.acdh.oeaw.ac.at/issues.json?subject=$name" -Headers $headers -Method Get
    $issueId = $issue.issues.id
    "    redmine issue: $issueId"
    
## export document from Transkribus
    "    - Processing in Transkribus..."
    $pagesReq = "https://transkribus.eu/TrpServer/rest/collections/$collectionId/$docId/fulldoc"
    $pa = Invoke-RestMethod -Uri $pagesReq -Method Get -WebSession $trpsession
    $numPages = $pa.pageList.pages.Count
    
    $req = $pullRequest + $docId + "/export"
    $cp = $pars
    $cp["pages"]="1-$numPages"
    $cpars = @{ "commonPars" = $cp} | ConvertTo-Json
    $pa = Invoke-RestMethod -Uri $req -Method Post -Headers @{"Content-Type"="application/json"} -Body $cpars -WebSession $trpsession
    
    $jobreq = "https://transkribus.eu/TrpServer/rest/jobs/$pa"
    $jo = Invoke-RestMethod -Uri $jobreq -Method Get -WebSession $trpsession -Headers @{"Accept"="application/json"}
    
    while ($jo.state -ne "FINISHED") {
    "        waiting for export to finish..."
        Start-Sleep -Seconds 15
        $jo = Invoke-RestMethod -Uri $jobreq -Method Get -WebSession $trpsession -Headers @{"Accept"="application/json"}
    }
    
## Expand zip download from Transkribus
    # TODO NOTE parameters will be different under Windows (-OutFile)
    $link = $jo.result
    "    - downloading and expanding"
    "        getting $link"
    wget $link -nv -O "temp/temp.zip" *> $null
    
    # Force to overwrite log.txt...
    Expand-Archive -Path "temp/temp.zip" -DestinationPath temp -Force
    $Path = "./temp/" + $docId
    $name = (Get-ChildItem -Path $Path).Name
    $xml = $Path + '/' + $name
    
## Upload the expanded TEI to Digitarium
## Refactoring is done by the upload script
    "    - upload $xml to Digitarium"
    $up = Invoke-WebRequest -Uri "$dServer/exist/apps/edoc/upload.xql" -Method Post -WebSession $diasession -ContentType application/xml -InFile $xml
    
## Update redmine status
    "    - updating redmine status"
    # status values:
    # 24 = HTRfertig; 17=Kollationiert; 15=needs review; 14=published
    $newStatus = @{
        issue=@{
            status_id=24
            custom_fields=@(
                @{
                    value=$up
                    name="online_status"
                    id="5"
                }
            )
        }
    } | ConvertTo-Json -Depth 3
    
    $res = Invoke-RestMethod -Uri "https://redmine.acdh.oeaw.ac.at/issues/$issueId.json" -Headers $headers -Method Put -Body $newStatus
    
## Process images to IIIF
# TODO add later

## Update status in Transkribus
    "    - updating Transkribus status"
    
    $threadArgs = ($collectionId, $docId)
    $job = Start-Job $PSScriptRoot/setstatus.ps1 -ArgumentList $threadArgs
}

## CLEANUP
<#
    let ${batch} := format-number(numerus_currens, '000')
    move images to ${projectDir}/601_imgs_raster/${batch}
    move status JSON files to ${projectDir}/090_metadata_generic/${batch}
    move processed files to “04 processed/${tranche}”
#>












