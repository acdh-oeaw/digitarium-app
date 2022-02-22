param (
  [string] $year,
  [string] $user,
  [string] $pass
)

Get-Date
"Uploading $year to Digitarium..."
$server = "https://diarium-exist.acdh-dev.oeaw.ac.at"

$cred = "$($user):$($pass)"
$encCred = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($cred))
$headers = @{ Authorization = "Basic $encCred" }

$targetDir = $year.substring(0, 3) + "x/" + $year
"  - cd'ing to ~/git/wienerdiarium/data/$targetDir"
cd "~/git/wienerdiarium/data/$targetDir"
"  - checking git"
git pull

# upload
$collectionID = "jg" + $year
"  - checking files"
$files = Get-ChildItem . -Recurse -File -Exclude "wdbmeta.xml"
$i = 0
$len = $files.Length
"  - processing files"
ForEach ($file in $files) {
  $i++
"    - [$i/$len]"

  $id = "edoc_wd_" + $file.Name.Substring(0, 10)
  
"      - creating PID if necessary"
  $pidurl = $server + "/exist/apps/edoc/data/resources/pids.xql?y=" + $year
  $pidRes = Invoke-WebRequest -Uri $pidurl -WebSession $diasession -Headers $headers

"      - getting file from Digitarium"
  $dir = "~/git/wienerdiarium/data/" + $year.Substring(0, 3) + "x/" + $year + "/" + $file.name.Substring(5, 2)
  If (!(Test-Path $dir)) {
    $n = New-Item -ItemType Directory -Force -Path $dir
  }
  $filename = $dir + "/" + $id.substring(10) + ".xml"
  $get = Invoke-WebRequest -Uri "$server/exist/restxq/edoc/resource/$id" -OutFile $file
  git add $file
}

$mfile = "~/git/wienerdiarium/data/" + $year.Substring(0, 3) + "x/" + $year + "/wdbmeta.xml"
$wdb = Invoke-WebRequest -Uri "$server/exist/restxq/edoc/resource/$collectionID" -OutFile $mfile

git add wdbmeta.xml
git commit -m"upload.ps1 processed $year"
cd "~/git/wienerdiarium"
