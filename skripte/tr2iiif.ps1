# Convert Images to JP2 and upload to IIIF

# TODO make useful
# this only store the main scripts to be used

$dirs = Get-ChildItem -Directory
$numdir = $dirs.Count
$cdn = 0

$dirs | % {
	$cdn++
	$name = $_.Name
	
	cd $name
	"[$cdn of $numDir – $name]"
	
	if ( Test-Path "*.jpg" )
		{
			"    Converting *.jpg to .png"
			mogrify -format png *.jpg
		}
	
	$i = 0
	$png = Get-ChildItem -Filter *.png
	$len = $png.Count
	$png | % {
		$i++
		$perc = (($i - 0.5) / $len) * 100
		Write-Progress -Activity "    converting images to JPEG2000" -status "image $i of $len" -PercentComplete $perc
		
		$filename = $_.Name
		$outname = $filename.Substring(0, $filename.Length - 4) + ".jp2"
		opj_compress -i $filename -o $outname *>$null
	}
	
	$year = $name.Substring(0, 4)
	$decade = $year.substring(0, 3) + "0"
	$month = $name.Substring(4, 2)
	
	$dir = $decade + "/" + $year + "/" + $month + "/" + $name
	"    creating $dir if necessary"
	ssh diarium-images@diarium-images.minerva.arz.oeaw.ac.at mkdir -p data/data/$dir
	"    upload to IIIF"
	scp *.jp2 diarium-images@diarium-images.minerva.arz.oeaw.ac.at:data/data/$dir
	
	# do some cleanup: we keep png and the original PDF and discard the rest
	"    cleaning up"
	Remove-Item * -Exclude *.png,*.pdf
	cd ..
}

#mogrify -format png *.jpg # oder anderes Format - Dateien auslesen!
#opj-compress -ImgDir . -OutFor jp2
#scp *.jp2 diarium-images@diarium-images.minerva.arz.oeaw.ac.at/data