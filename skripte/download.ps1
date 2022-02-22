param (
  [String] $targetDir,
  [int] $collectionId,
  [int] $from,
  [int] $to
)

# login to Diarium server; adjust as needed
#$server = "http://localhost:8080"
$server = "https://diarium-exist.acdh-dev.oeaw.ac.at"

$login = "$server/exist/apps/edoc/login"
"Log in to Diarium"
$res = Invoke-RestMethod -Uri $Login -Method Post -SessionVariable diasession -Body "user=kampkaspar&password=21Ec2020"

$trpserver = "ftp://transkribus.eu"
$user = "Dario.Kampkaspar@oeaw.ac.at"
$pass = "21ec2020"

"Log in to Transkribus"
# log in to Transkribus REST service
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $login = Invoke-RestMethod -Uri https://transkribus.eu/TrpServer/rest/auth/login -Body "user=dario.kampkaspar@oeaw.ac.at&pw=21ec2020" -Method Post -SessionVariable trpsession

$pullRequest = "https://transkribus.eu/TrpServer/rest/collections/$collectionId"
$getdocs = $pullRequest + "/list"

"Processing docIDs $from to $to (including)"

$allDocs = Invoke-RestMethod -Uri $getDocs -Method Get -WebSession $trpsession
$docs = $allDocs | Where-Object { $_.docId -ge $from -and $_.docId -le $to }

$num = $docs.length
$i = 0
foreach ($doc in $docs) {
$docId = $doc.docId
$i++
"[$i/$num] $docId"
"  - Processing in Transkribus..."
  
  $Path = "./temp/" + $docId
  
  $pagesReq = "$pullRequest/$docId/fulldoc"
  $pa = Invoke-RestMethod -Uri $pagesReq -Method Get -WebSession $trpsession
  $numPages = $pa.pageList.pages.Count
  
  $modifiedServer = ($pa.pageList.pages.tagsStored | Measure-Object -Maximum).Maximum
  
  if ((Test-Path $path) -eq $False -or (Get-ChildItem $Path -Filter "*.xml" | Test-Path -OlderThan $modifiedServer)) {
    $req = $pullRequest + "/" + $docId + "/export"
    $exportParams = @{
      "commonPars"= @{
        "pages"= "1-$numPages"
        "doExportDocMetadata"= "false"
        "doWriteMets"= "true"
        "doWriteImages"= "false"
        "doExportPageXml"= "true"
        "doExportAltoXml"= "false"
        "doWritePdf"= "false"
        "doWriteTei"= "true"
        "doWriteDocx"= "false"
        "doWriteTxt"= "false"
        "doWriteTagsXlsx"= "false"
        "doWriteTagsIob"= "false"
        "doWriteTablesXlsx"= "false"
        "doCreateTitle"= "false"
        "useVersionStatus"= "Latest version"
        "writeTextOnWordLevel"= "false"
        "doBlackening"= "false"
        "selectedTags"= @(
          "add",
          "date",
          "Address",
          "Antiqua",
          "supplied",
          "work",
          "unclear",
          "sic",
          "div",
          "regionType",
          "speech",
          "person",
          "gap",
          "organization",
          "comment",
          "abbrev",
          "place"
        )
        "font"= "FreeSerif"
        "splitIntoWordsInAltoXml"= "false"
        "pageDirName"= "page"
        "fileNamePattern"= "${filename}"
        "useHttps"= "true"
        "remoteImgQuality"= "orig"
        "doOverwrite"= "true"
        "useOcrMasterDir"= "true"
        "exportTranscriptMetadata"= "true"
      }
    } | ConvertTo-Json -Depth 3
    
    try {
      $pa = Invoke-RestMethod -Uri $req -Method Post -WebSession $trpsession -Body $exportParams -ContentType application/json
      
      $jobreq = "https://transkribus.eu/TrpServer/rest/jobs/$pa"
      $jo = Invoke-RestMethod -Uri $jobreq -Method Get -WebSession $trpsession -Headers @{"Accept"="application/json"}
      
      while ($jo.state -ne "FINISHED") {
        "    waiting for export to finish..."
        Start-Sleep -Seconds 20 
        $jo = Invoke-RestMethod -Uri $jobreq -Method Get -WebSession $trpsession -Headers @{"Accept"="application/json"}
      }
    
      # TODO NOTE parameters will be different under Windows (-OutFile)
      $link = $jo.result
      "  - downloading and expanding"
      "    - getting $link"
      wget $link -nv -O "temp/temp.zip"
      
      # Force to overwrite log.txt...
      Expand-Archive "temp/temp.zip" -DestinationPath temp -Force
      
      $name = (Get-ChildItem -Path $Path -Filter "*.xml").Name
      $xml = $Path + '/' + $name
      $xml
      
      # Check whether TEI file is > 0 Bytes; if = 0 Bytes, transform from PAGE
      If ((Get-Item $xml).length -eq 0kb) {
        $mets = $Path + "/" + $name.Substring(0, 10) + "/mets.xml"
        java -jar Saxon-HE-9.9.1-2.jar -xsl:page2tei-0.xsl -s:$mets -o:$xml
      }
    } catch {
      "    Error downloading – not our document?)"
      $_.Exception
			$_.InvocationInfo
    }
  } Else {
    "  - already up-to-date (last modified on server: $modifiedServer)"
  }
  
  # upload
  $name = (Get-ChildItem -Path $Path -Filter "*.xml").Name
  $xml = $Path + '/' + $name
  
  "  - upload to Diarium"
  try {
    $upReq = Invoke-WebRequest -Uri "$server/exist/apps/edoc/upload.xql" -Method Post -WebSession $diasession -ContentType application/xml -InFile $xml
    $y = $name.Substring(2, 4)
  
  "  - creating/retrieving PID"
    $pidReq = Invoke-WebRequest -Uri "$server/exist/apps/edoc/data/resources/pids.xql?y=$y" -WebSession $diasession
  
  "  - getting file and wdbmeta.xml from Digitarium"
    $dir = "~/git/wienerdiarium/data/" + $y.Substring(0, 3) + "x/" + $y + "/" + $name.Substring(6, 2)
    If (!(Test-Path $dir)) {
      $n = New-Item -ItemType Directory -Force -Path $dir
    }
    $id = "edoc_wd_" + $y + "-" + $name.Substring(6, 2) + "-" + $name.Substring(8, 2)
    $file = $dir + "/" + $id.Substring(8) + ".xml"
    $get = Invoke-WebRequest -Uri "$server/exist/restxq/edoc/resource/$id" -OutFile $file
    $mid = "jg" + $y
    $mfile = "~/git/wienerdiarium/data/" + $y.Substring(0, 3) + "x/" + $y + "/wdbmeta.xml"
    $wdb = Invoke-WebRequest -Uri "$server/exist/restxq/edoc/resource/$mid" -OutFile $mfile
    
    "  - pushing to github..."
    cd ~/git/wienerdiarium
    $p1 = git pull
    $a1 = git add $file.Substring(20)
    $a2 = git add $mfile.Substring(20)
    $c0 = git commit -m"$id via download.ps1"
    $p2 = git push
    cd ~/diarium-processing
  } catch {
    "Error Uploading to Digitarium"
    $_
  }
}
