param ($collId,
	$fileID)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$login = Invoke-RestMethod -Uri https://transkribus.eu/TrpServer/rest/auth/login -Body "user=dario.kampkaspar@oeaw.ac.at&pw=21ec2020" -Method Post -SessionVariable session

#$response = Invoke-RestMethod -Uri "https://transkribus.eu/TrpServer/rest/collections/$collId/list" -Method Get -WebSession $session
#$tr1 = $response | Where-Object { $_.docId -ge $from -and $_.docId -le $to}

#$all = [System.Collections.ArrayList]@()

#$tr1 | % {
#	$fileID = $_.docId
	
	$req = "https://transkribus.eu/TrpServer/rest/collections/$collId/$fileID/fulldoc"
	$res = Invoke-RestMethod -Uri $req -Method Get -WebSession $session
	$res | % {
		$_.pageList.pages | % {
			$tss = $_.tsList.transcripts | Sort-Object -Property tsId -Descending
			$page = $_.pageNr
			$tss[0] | Where-Object { $_.status -eq "NEW" -or $_.status -eq "IN_PROGRESS" } | % {
				$transcriptId = $_.tsId
				$change = "https://transkribus.eu/TrpServer/rest/collections/$collId/$fileId/$page/$transcriptId/status?status=DONE&note=changed%20after%20auto%20download"
				#$_
				"Setting $collId/$fileId/$page/$transcriptId → DONE"
				$chgReq = Invoke-RestMethod -Uri $change -Method Post -Websession $session
			}
		}
	}
#}