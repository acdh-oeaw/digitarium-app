<# 
.NOTES
    File Name: step1.ps1
    Author: Dario Kampkaspar (dario.kampkaspar@oeaw.ac.at)
    Created: 2017-05-30
    Prerequisite: PowerShell V2 or greater
.SYNOPSIS
    Batch process all ANNO sources for the year specified.
    We assume that we get an XML list of all URL to be processed;
    The expected XPath to the URLs is /list/issue/url.
    Use from a directory containing 00-current ... 05-status
#>
param(
    [string] $y,
    [string] $modelID
)

#######################################################################################################################
# Start time; used to get jobIDs
$start = Get-Date -Format yyyy-MM-dd
$startTime = $(Get-Date)

"Starting batch processing for $y " + $startTime 

$server = "ftp://transkribus.eu"
$user = "Dario.Kampkaspar@oeaw.ac.at"
$pass = "21ec2020"

# log in to Transkribus REST service
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $login = Invoke-RestMethod -Uri https://transkribus.eu/TrpServer/rest/auth/login -Body "user=$user&pw=$pass" -Method Post -SessionVariable session

# Check that we are in diarium-processing and not one of the subdirectories
If (!(Test-Path "00-current")) {
    "Directory '00-current' not found – exiting!"
    Exit -1
}

$url = "https://diarium-exist.acdh-dev.oeaw.ac.at/exist/apps/edoc/data/anno.xql?y=" + $y
##########################################
#####! Enter correct filename here !######
[xml]$doc = Invoke-RestMethod -Uri $url ##
##########################################
##########################################
##### STEP 0: Create collection or get collection ID #####
"
Getting or creating Collection 'WrDiarium-$y'"
$colls = Invoke-RestMethod -Uri https://transkribus.eu/TrpServer/rest/collections/list -WebSession $session
$tempCollectionId = $colls | Where-Object { $_.colName -eq "WrDiarium-$y" } | % { $_.colId }

If ($tempCollectionId -gt 0) {
    $collectionID = $tempCollectionId
} Else {
  $collectionID = Invoke-RestMethod -Uri "https://transkribus.eu/TrpServer/rest/collections/createCollection?collName=WrDiarium-$y" -Method POST -WebSession $session
	$shareUri = "https://transkribus.eu/TrpServer/rest/recognition/51215/$modelID/add?collId=$collectionID"
  $share = Invoke-RestMethod -Uri $shareUri -Method POST -WebSession $session
}

"Collection 'WrDiarium-$y': $collectionID"

#### List jobs – get only jobs for this collection
$mdReq = "https://transkribus.eu/TrpServer/rest/jobs/list?collId=$collectionID"

##### TODO #####
# Farbtiefe für allIssues übernehmen
# IDs für verschiedene Modelle eintragen
###################

Get-Date
"Starting ingest"

cd "00-current"

# STEP 1: Extract images, deskew and upload to Transkribus FTP
$j = 0
$jobs = @{} # name : jobNumber
$doc.list.issue | % {
    $j++
    
    $url = $_.url
    $issue = $_.name
    
# 1a: create a directory for each issue and do the necessary steps there
    "Processing No. $j : $issue"
    mkdir $issue | out-null
    cd $issue
    $fileName = $issue + ".pdf"
    
# 1b: Get the File
    "    fetching PDF..."
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.add('User-Agent', "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36")
        $headers.add("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3")
        $headers.add("Accept-Encoding", "gzip, deflate")
        $headers.add("Pragma", "no-cache")
        $headers.add("Referer", "http://anno.onb.ac.at/cgi-content/anno?aid=wrz&datum=" + $issue + "&zoom=33")
    
        $dl = Invoke-RestMethod -Uri $url -Headers $headers -OutFile $fileName
    
# 1c: Extract the images from the PDF and prefix the auto generated file name with the date
    "    extracting images"
    pdfimages $fileName i
    
# 1d: convert to JPEG
    "    converting to JPEG"
    $filter = "i-*"
    $items = Get-ChildItem . -Filter $filter
    $len = $items.Length
    $i = 0
    ForEach ($item in $items) {
        # Fancy Progress bar
        $i++
        $perc = (($i - 0.5) / $len) * 100
        Write-Progress -Activity "    converting images" -status "image $i of $len" -PercentComplete $perc
        
        $outFile = $issue + $item.Name.Substring(1,4) + ".jpg"
        #..\deskew64.exe -o $outFile $item.Name | out-null
    convert -quality 100 $item.Name $outFile

    ## TODO convert $outfile -format "%[colorspace]" info:
    ## Farbtiefe

    }

# 1e: create directory on Transkribus FTP
    $dir = $server + "/wd" + $issue
    $request = [Net.WebRequest]::Create($dir)
      $request.Credentials = New-Object System.Net.NetworkCredential($user, $pass)

        try {        
            $request.Method = [System.Net.WebRequestMedhods.FTP]::GetFileSize
            $request.GetResponse() | Out-Null
            "    directory $dir already present on FTP"
        } catch {
            "    trying to create $dir"
            $request.Method = [System.Net.WebRequestMethods+FTP]::MakeDirectory
        $resp = $request.GetResponse()
        $resp.Close()
        }

# 1f: upload file to Transkribus FTP - use directory created earlier
    $filter = $issue + "-*"
    $items = Get-ChildItem . -Filter $filter
    $i = 0
    $webclient = New-Object System.Net.WebClient
    $webclient.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
    ForEach ($item in $items) {
        # Fancy Progress bar
        $i++
        $perc = (($i - 0.5) / $len) * 100
        Write-Progress -Activity "    uploading images to $dir" -status "image $i of $len" -PercentComplete $perc
        $uri = $dir + "/" + $item.Name
        $webclient.UploadFile($uri, $item.FullName)
    }

# 1g: import these files into Transkribus
    "    importing into Transkribus."
    $rImport = Invoke-RestMethod -Uri "https://transkribus.eu/TrpServer/rest/collections/$collectionID/ingest?fileName=wd$issue" -Method Post -WebSession $session
    $jobs.Add("wd$issue", $rImport)
    "    job number: $rImport"

    ## Object creation goes here

    cd ..
}

cd ~/diarium-processing
$jobs | ConvertTo-Json | Out-File -FilePath '00-current/01-jobs.json'

# To be sure all ingest jobs have finished, we wait for 10 Minutes
Get-Date -Format HH:mm:ss
"Waiting for 10 minutes to give all import jobs time to finish"
$wait = 600
Start-Sleep -Seconds $wait

# TODO!!! Loop to check whether they are really finished (as below for OCR and HTR)
# Go through the jobs until all have finished and see which have finished or failed
$ocrFailed = @()
do {
    $md = Invoke-RestMethod -Uri $mdReq -Method Get -WebSession $session

  # not yet finished or failed
  $open = 0
  $md | Where-Object { $_.type -eq "Create Document" -and ($_.state -ne "FINISHED" -and $_.state -ne "FAILED") } | % {
    $id = $_.ingestJobId
    $state = ($md | Where-Object { $_.jobId -eq $id }).state
    
    # This could be done more nicely by checking instead of forcing but for now I'm okay with it
    $_ | Add-Member -NotePropertyName ingestResult -NotePropertyValue $state -Force
    
    # If the job failed, add it to the list
    if ($state -eq 'FAILED') {
      $ingestFailed += $_.docId
    }
        if ($state -ne 'FAILED' -and $state -ne 'FINISHED') {
      $open++
    }
    }
    If ($open -gt 0) {
    $wait = 300
    Get-Date -Format HH:mm:ss
    "Still waiting for ' create document' jobs to finish; $open still open"
    Start-Sleep -Seconds $wait
  }
}
while (($md | Where-Object { $_.created -gt $start -and $_.state -eq 'CREATED' -and $_.type -eq 'Create Document'}).Count -gt 0)


# From here on, we work with the array of objects
# No, instead we get a list of all successful Create Document jobs since the start to account for problems during step 1

$md = Invoke-RestMethod -Uri $mdReq -Method Get -WebSession $session

$allIssues = @()
$allIssues.Clear()
$md | Where-Object { $_.state -eq 'FINISHED' -and $_.type -eq 'Create Document' } | Sort-Object -Property $_.docId  | Foreach {
    $index = $_.jobData.indexOf("at/") + 3
    $prop = @{
        'createJobId' = $_.jobId;
        'name' = $_.jobData.substring($index)
        'docId' = $_.docId
    }
    
    $allIssues += New-Object -TypeName PSObject -Prop $prop
}
$allIssues | ConvertTo-Json -Depth 3 | Out-File -FilePath '00-current/02-pre-ocr.json'

# Use the data of issue objects
# OCR
# TODO Later, try to use P2PaLA oder the block segmentation LA instead of Abbyy (which is only used because of better LA results)
$allIssues | % {
    $docId = $_.docId
    #$numP = $_.numberOfPages
    "Starting OCR for $docId"
    $request = "https://transkribus.eu/TrpServer/rest/recognition/ocr?collId=$collectionID&id=$docId&typeFace=Combined&language=German,OldGerman&pages=-1"
    #$request = "https://transkribus.eu/TrpServer/rest/recognition/ocr?collId=5454&id=$docId&typeFace=Combined&language=German,OldGerman&pages=1-$numP" # For debugging purposes
    
    try {
        $rOcr = Invoke-RestMethod -Uri $request -Method Post -WebSession $session
        $_ | Add-Member -NotePropertyName ocrJobId -NotePropertyValue $rOcr
        $_ | Add-Member -NotePropertyName ocrRequest -NotePropertyValue $request
    } catch {
        $_ | Add-Member -NotePropertyName ocrErr -NotePropertyValue $_.Exception.Response.StatusCode.value__
    }
}
$allIssues | ConvertTo-Json -Depth 3 | Out-File -FilePath '00-current/03-post-ocr1.json'


# To be sure all OCR jobs have finished, we wait for 1 Minute per issue – assume 4 parallel jobs
$wait = 20 * $allIssues.Length
$ts = New-TimeSpan -Seconds $wait
"Waiting to allow OCR jobs to finish until " + ((Get-Date) + $ts)
Start-Sleep -Seconds $wait

#$allIssues = Get-Content "00-current/03-post-ocr1.json" | ConvertFrom-Json

# Go through the jobs until all have finished and see which have finished or failed
$ocrFailed = @()
do {
  try {
    $md = Invoke-RestMethod -Uri $mdReq -Method Get -WebSession $session
  } catch {
    $login = Invoke-RestMethod -Uri https://transkribus.eu/TrpServer/rest/auth/login -Body "user=$user&pw=$pass" -Method Post -SessionVariable session
    $md = Invoke-RestMethod -Uri $mdReq -Method Get -WebSession $session
  }

    # not yet finished or failed
    $open = 0
    $allIssues | Where-Object { $_.ocrResult -eq $null -or ($_.ocrResult -ne 'FINISHED' -and $_.ocrResult -ne 'FAILED') } | % {
        $id = $_.ocrJobId
        $state = ($md | Where-Object { $_.jobId -eq $id }).state

        # This could be done more nicely by checking instead of forcing but for now I'm okay with it
        $_ | Add-Member -NotePropertyName ocrResult -NotePropertyValue $state -Force

        # If the job failed, add it to the list
        if ($state -eq 'FAILED') {
            $ocrFailed += $_.docId
        }
    if ($state -ne 'FAILED' -and $state -ne 'FINISHED') { $open++ }
    }

    $wait = 15 * $open
    Get-Date -Format HH:mm:ss
    "Still waiting $wait seconds for OCR jobs to finish; $open still open"
    Start-Sleep -Seconds $wait
}
while (($md | Where-Object { $_.created -gt $start -and $_.state -eq 'CREATED' -and $_.type -eq 'Optical Character Recognition'}).Count -gt 0)

# Save the file of failed OCR in case we need to resume later
$allIssues | ConvertTo-Json | Out-File -FilePath '00-current/04-post-ocr1.json'
$ocrFailed | ConvertTo-Json | Out-File -FilePath '00-current/05-post-ocr-failed.json'

# Try OCR pagewise on failed docs
$newOcrJobs = @{}
$ocrFailed | % {
    $docId = $_
    $pageJobs = @()

    $pagesReq = "https://transkribus.eu/TrpServer/rest/collections/$collectionID/$docId/fulldoc"
    $pa = Invoke-RestMethod -Uri $pagesReq -Method Get -WebSession $session
    
    $i = 0
    do {
        $i++
        $request = "https://transkribus.eu/TrpServer/rest/recognition/ocr?collId=$collectionID&id=$docId&typeFace=Combined&language=German,OldGerman&pages=$i"
            try {
        $rOcr = Invoke-RestMethod -Uri $request -Method Post -WebSession $session
      } catch {
        $login = Invoke-RestMethod -Uri https://transkribus.eu/TrpServer/rest/auth/login -Body "user=$user&pw=$pass" -Method Post -SessionVariable session
        $rOcr = Invoke-RestMethod -Uri $request -Method Post -WebSession $session
      }        

        $prop = @{
            'page' = $i;
            'ocrJobId' = $rOcr
        }
        $pageJobs += New-Object -TypeName PSObject -Prop $prop
    } until ($i -eq $pa.trpDoc.md.nrOfPages)

    $newOcrJobs.Add($docId, $pageJobs)
}
$test=@{}
$test.Clear()
foreach ($key in $newOcrJobs.Keys) {
    $test.Add($key.toString(), $newOcrJobs[$key])
}
$test | ConvertTo-Json -Depth 3 | Out-File -FilePath '00-current/06-ocr2-jobs.json'

# Poll regularly to get the state of all jobs; on average, it's about 2 minutes per page
do {
    $open = 0
    foreach($key in $newOcrJobs.Keys) {
        $newOcrJobs[$key] | % {
            $id = $_.ocrJobId
            $jobReq = "https://transkribus.eu/TrpServer/rest/jobs/$id"
            $md = Invoke-RestMethod -Uri $jobReq -Method Get -WebSession $session
            $state = $md.trpJobStatus.state
            $_ | Add-Member -NotePropertyName ocr2State -NotePropertyValue $state -Force
            if ($state -eq 'CREATED' -or $state -eq 'RUNNING') { $open++ }
        }
    }
    $wait = 120 * $open
    Get-Date -Format HH:mm:ss
    "Waiting for OCR jobs to finish - Open: $open"
    Start-Sleep -Seconds $wait
} while ($open -gt 0)

# Save results to file in case we need to resume later
$postnew=@{}
foreach ($key in $newOcrJobs.Keys) {
    $postnew.Add($key.toString(), $newOcrJobs[$key])
}
$postnew | ConvertTo-Json -Depth 3 | Out-File -FilePath '00-current/07-post-ocr2-jobs.json'

$failed = @()
foreach ($key in $newOcrJobs.Keys) {
    $ob = $allIssues | Where-Object { $_.docId -eq $key }
    $ob | Add-Member -NotePropertyName ocr2 -NotePropertyValue $newOcrJobs[$key] -Force

    $t = $newOcrJobs[$key] | ? { $_.ocr2State -eq 'FAILED' }
    $t | % {
        $p = $_.page
        $failed += "$key, $p"
    }
}
$allIssues | ConvertTo-Json | Out-File -FilePath '00-current/08-post-ocr2-status.json'
$failed | ConvertTo-Json | Out-File -FilePath '00-current/08a-ocr2-failedPages.json'    

#$allIssues = Get-Content .\10-htr-jobs.json | ConvertFrom-Json 

###################################
## CitLab Advanced LayoutAnalysis #
###################################
$LARequest = "https://transkribus.eu/TrpServer/rest/LA/analyze?doLineSeg=true&doCreateJobBatch=false&collId=$collectionID&doBlockSeg=false&doWordSeg=false&jobImpl=CITlabAdvancedLaJob"
$login = Invoke-RestMethod -Uri https://transkribus.eu/TrpServer/rest/auth/login -Body "user=$user&pw=$pass" -Method Post -SessionVariable session

$allIssues | % {
    $docId = $_.docId
    
    $pagesReq = "https://transkribus.eu/TrpServer/rest/collections/$collectionID/$docId/fulldoc"
    #$pagesReq = "https://transkribus.eu/TrpServer/rest/collections/5454/$docId/fulldoc"
    $pa = Invoke-RestMethod -Uri $pagesReq -Method Get -WebSession $session
    $numPages = $pa.pageList.pages.Count
    
    $ps = $pa.pageList.pages | % {
        $pageId = $_.pageId
        $ts = $_.tsList.transcripts | ? { $_.toolName -eq 'Abbyy Finereader 11' }
        $tsId = $ts.tsId
        
        "<pages><pageId>$pageId</pageId><tsId>$tsId</tsId></pages>"
    }
    $d = "<documentSelectionDescriptors><documentSelectionDescriptor><docId>$docId</docId><pageList>$ps</pageList></documentSelectionDescriptor></documentSelectionDescriptors>"

    try {
        $rOcr = Invoke-RestMethod -Uri $LARequest -Method Post -WebSession $session -Body $d -ContentType application/xml
        "Starting CitLab Advanced Layout Analysis for $docId - success"
        
        $_ | Add-Member -NotePropertyName laJobId -NotePropertyValue $rOcr.trpJobStatuses.trpJobStatus.jobId -Force
        #$_ | Add-Member -NotePropertyName laRequest -NotePropertyValue $request -Force
    } catch {
        "Starting CitLab Advanced Layout Analysis for $docId - Failed request: $LARequest"
        $d
        $_.Exception.Response.StatusCode.value__
        
        $_ | Add-Member -NotePropertyName laErr -NotePropertyValue $_.Exception.Response.StatusCode.value__
    }
}
$allIssues | ConvertTo-Json | Out-File -FilePath '00-current/09-la-jobs.json'

# Initially, we assume 2 parallel jobs and 5 minutes per job; after that, we poll every 2 minutes
## TODO update time estimate – c. 4 pages per minute, 4–5 parallel jobs
$wait = $allIssues.Count * 20 
Get-Date -Format HH:mm:ss
"Waiting for LA jobs to finish until"
$ts = New-TimeSpan -Seconds $wait
(Get-Date) + $ts
Start-Sleep -Seconds $wait

# Poll regularly to get the state of all jobs
do {
   $open = 0
    $allIssues | % {
        $id = $_.laJobId
        $jobReq = "https://transkribus.eu/TrpServer/rest/jobs/$id"
      try {
        $md = Invoke-RestMethod -Uri $jobReq -Method Get -WebSession $session
      } catch {
        $login = Invoke-RestMethod -Uri https://transkribus.eu/TrpServer/rest/auth/login -Body "user=$user&pw=$pass" -Method Post -SessionVariable session
        $md = Invoke-RestMethod -Uri $jobReq -Method Get -WebSession $session
      }
        $state = $md.state
        $_ | Add-Member -NotePropertyName laState -NotePropertyValue $state -Force
        if ($state -eq 'CREATED' -or $state -eq 'RUNNING') { $open++ }
    }

    "LA jobs Open: $open"
    if ($open -gt 0) {
      $wait = $open * 20
      "Waiting for LA jobs to finish until"
      $ts = New-TimeSpan -Seconds $wait
      (Get-Date) + $ts
      Start-Sleep -Seconds $wait
    }
} while ($open -gt 0)
$allIssues | ConvertTo-Json | Out-File -FilePath '00-current/09a-post-la-status.json'

# Get info about failed LA
$failedLA = @{}
$allIssues | Where-Object { $_.laState -eq 'FAILED' } | % {
    $docId = $_.docId
    $jobId = $_.htrJobId
    $mdReq = "https://transkribus.eu/TrpServer/rest/jobs/$jobId"
    $md = Invoke-RestMethod -Uri $mdReq -Method Get -WebSession $session
    $failedLA.Add($docId.toString(), $md.description) }
$failedLA | ConvertTo-Json | Out-File -FilePath '00-current/09b-la-failed.json'

# $allIssues = Get-Content .\09-la-jobs.json | ConvertFrom-Json

#######
# HTR #
#######
$login = Invoke-RestMethod -Uri https://transkribus.eu/TrpServer/rest/auth/login -Body "user=$user&pw=$pass" -Method Post -SessionVariable session
$numAllPages = 0
$allIssues | % {
    $docId = $_.docId
    "Starting HTR for $docId"
    
    $pagesReq = "https://transkribus.eu/TrpServer/rest/collections/$collectionID/$docId/fulldoc"
    #$pagesReq = "https://transkribus.eu/TrpServer/rest/collections/5454/$docId/fulldoc"
    $pa = Invoke-RestMethod -Uri $pagesReq -Method Get -WebSession $session
    $numPages = $pa.pageList.pages.Count
    $numAllPages += $numPages
    
    $ps = $pa.pageList.pages | % {
        $pageId = $_.pageId
        $ts = $_.tsList.transcripts | ? { $_.toolName -eq 'CITlab_Advanced_LA 0.1' }
        $tsId = $ts.tsId
        
        "<pages><pageId>$pageId</pageId><tsId>$tsId</tsId></pages>"
    }
    $d = "<documentSelectionDescriptor><docId>$docId</docId><pageList>$ps</pageList></documentSelectionDescriptor>"

    ## !! ggf. Modell aktualisieren
    ##$model = If ($_.depth -eq 'Gray') {2840} Else {2818}
    $model = $modelID

    $htrRequest = "https://transkribus.eu/TrpServer/rest/recognition/$collectionID/$model/htrCITlab?id=$docId&pages=1-$numPages&dict=Wiener_Diarium_M5.dict"
    #$htrRequest = "https://transkribus.eu/TrpServer/rest/recognition/5454/133/htrCITlab?id=$docId&pages=1-$numPages" # For debugging purposes

    try {
        $rOcr = Invoke-RestMethod -Uri $htrRequest -Method Post -WebSession $session -Body $d -ContentType application/xml
        
        $_ | Add-Member -NotePropertyName htrJobId -NotePropertyValue $rOcr -Force
        $_ | Add-Member -NotePropertyName htrRequest -NotePropertyValue $htrRequest -Force
    } catch {
        $_ | Add-Member -NotePropertyName htrErr -NotePropertyValue $_.Exception.Response.StatusCode.value__
    }
}
$allIssues | ConvertTo-Json | Out-File -FilePath '00-current/10-htr-jobs.json'

# Initially, we assume 4 parallel jobs and 10 minutes per job; after that, we poll every 5 minutes
# Schätzung: ca. 130 Sekunden je Seite, 4 parallele Jobs –> Seiten * 33
$wait = $numAllPages * 33
Get-Date -Format HH:mm:ss
"Waiting for HTR jobs to finish until"
$ts = New-TimeSpan -Seconds $wait
(Get-Date) + $ts
Start-Sleep -Seconds $wait

# Poll regularly to get the state of all jobs
do {
    $open = 0
    $allIssues | % {
        $id = $_.htrJobId
        $jobReq = "https://transkribus.eu/TrpServer/rest/jobs/$id"
      try {
        $md = Invoke-RestMethod -Uri $jobReq -Method Get -WebSession $session
      } catch {
        $login = Invoke-RestMethod -Uri https://transkribus.eu/TrpServer/rest/auth/login -Body "user=$user&pw=$pass" -Method Post -SessionVariable session
        $md = Invoke-RestMethod -Uri $jobReq -Method Get -WebSession $session
      }
        $state = $md.state
        $_ | Add-Member -NotePropertyName htrState -NotePropertyValue $state -Force
        if ($state -eq 'CREATED' -or $state -eq 'RUNNING') { $open++ }
    }
    
    if ($open -gt 0) {
      $wait = $open * 75
      "$open jobs still open; waiting for HTR jobs to finish until"
      $ts = New-TimeSpan -Seconds $wait
      (Get-Date) + $ts
      Start-Sleep -Seconds $wait
    }
} while ($open -gt 0)
$allIssues | ConvertTo-Json | Out-File -FilePath '00-current/11-post-htr-status.json'

# If HTR has failed on a page, it resumes on the others, so no need to retry here
# Get info about failed HTR
$login = Invoke-RestMethod -Uri https://transkribus.eu/TrpServer/rest/auth/login -Body "user=$user&pw=$pass" -Method Post -SessionVariable session
$failedHtr = @{}
$allIssues | Where-Object { $_.htrState -eq 'FAILED' } | % {
    $docId = $_.docId
    $jobId = $_.htrJobId
    $mdReq = "https://transkribus.eu/TrpServer/rest/jobs/$jobId"
    $md = Invoke-RestMethod -Uri $mdReq -Method Get -WebSession $session
    $failedHtr.Add($docId.toString(), $md.description) }
$failedHtr | ConvertTo-Json | Out-File -FilePath '00-current/12-htr-failed.json'

###########

# $allIssues = Get-Content .\10-htr-jobs.json | ConvertFrom-Json
Get-Date -Format HH:mm:ss
"Updating redmine"

#########################
# Create redmine issues #
#########################
$key = 'bf1d31917b5d1c2a2a225f7e68efbc971cd6ba49'
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add('X-Redmine-API-Key', $key)
$headers.add('charset', 'utf-8')
$headers.add('Content-Type', 'application/json')

# Get status of jobs
$allIssues | % {
    $jobId = $_.htrJobId
    $reqR = "https://transkribus.eu/TrpServer/rest/jobs/$jobId"
    $r = Invoke-RestMethod -Uri $reqR -WebSession $session -Method Get
    $_ | Add-Member -NotePropertyName htrResult -NotePropertyValue $r.state
}

# 1: open issue per tranche
$focr = $failed | ConvertTo-Json
$fhtr = $failedHtr | ConvertTo-Json
$desc = "OCR failed:
$focr

HTR failed:
$fhtr"

$issue = @{
    issue=@{
        project_id=91
        tracker_id=3
        status_id=1
        priority_id=3
        subject="Tranche vom $start"
        description=$desc
        assigned_to_id=256
        parent_issue_id=9324
    }
} | ConvertTo-Json
"Redmine issue: " + $issue
$tIssue = Invoke-RestMethod -Uri https://redmine.acdh.oeaw.ac.at/projects/91/issues.json -Headers $headers -Method Post -Body $issue
$issueId = $tIssue.issue.id
$issueId | Out-File -FilePath "00-current/13-redmine.txt"

# 2: Create an issue for every issue and provide the status information

$allIssues | % {    
    $desc = ($_ | Format-List| Out-String)
    $ti= $_.name
    $y = $ti.Substring(2,4)
    $m = $ti.Substring(6,2)
    $d = $ti.Substring(8,2)
    $issue = @{
        issue=@{
            project_id=91
            tracker_id=19
            status_id=1
            priority_id=2
            subject=$ti
            description=$desc
            assigned_to_id=256
            parent_issue_id=$issueId
            custom_fields=@(
                @{
                    value="$y-$m-$d"
                    name="Datum"
                    id="12"
                },
                @{
                    value=$_.docId
                    name="Inventory number"
                    id="32"
                }
            )
        }
    } | ConvertTo-Json -Depth 3
    
    $res = Invoke-RestMethod -Uri https://redmine.acdh.oeaw.ac.at/projects/91/issues.json -Headers $headers -Method Post -Body $issue
}


# Redmine-Issue-Nr. speichern! Einfacher für Runterladen

##############################
##### CLEANUP OPERATIONS #####
##############################
cd ~/diarium-processing 

"
Performing Cleanup operations"
"  Creating directory for processed images: '01-images/$y'"

New-Item -Path "./01-images/" -Name $y -ItemType "directory"
$yearDirectory = "./01-images/$y"

"  Copying images..."
$items = Get-ChildItem -Path "./00-current/" -Directory
$i = 0
$len = $items.Length

ForEach ($item in $items) {
    # Fancy Progress bar
    $i++
    $perc = (($i - 0.5) / $len) * 100
    Write-Progress -Activity "    copying images to '01-images/$y'" -status "directory $i of $len" -PercentComplete $perc
   
    New-Item -Path $yearDirectory -Name $item.name -ItemType "directory"
  
    $destination = $yearDirectory + "/" + $item.name
    Copy-Item -Path "$item/*" -Exclude "*.ppm" -Destination $destination
}

"
  Creating directory for status files: '05-status/$y'"
New-Item -Path "./05-status" -Name $y -ItemType "directory"
$yearDirectory = "./05-status/$y"

"  Copying status files"
Copy-Item -Path "./00-current/*" -Include "*.json" -Destination $yearDirectory

"  Removing files from '00-current'"
Remove-Item -Recurse -Force "./00-current/*"
"Done cleaning up"

################
##### DONE #####
################
Get-Date
"
Done processing $y, this took"
$elapsedTime = $(get-date) - $startTime
"{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
