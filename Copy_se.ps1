
function IsNull($objectToCheck) {
    if ($objectToCheck -eq $null) {
        return $true
    }

    if ($objectToCheck -is [String] -and $objectToCheck -eq [String]::Empty) {
        return $true
    }

    if ($objectToCheck -is [DBNull] -or $objectToCheck -is [System.Management.Automation.Language.NullString]) {
        return $true
    }

    return $false
}

#pull off inout file as 1st arg
$param1=$args[0]
if (!(Test-Path $param1)) {
    Write-Host "no file!"
    $inFile = null;
} else {
    $inFile = $param1
}

#pull off dir to store data in as 2nd arg
$param2=$args[1]
if (!(IsNull($param2))) {
    if (!(Test-Path $param2)) {
        $outDir = $param2
    }
    else {
        $outDir = 'tmp'
        Write-Host "file exists, using tmp"
    }
} else {
    Write-Host "no file specified! using tmp"
    $outDir = 'tmp'
}

#Pull in each filename, construct S3 path, copy file to local
$dataFiles = Import-Csv -Path $inFile -Header 'tmp'
$counter = 0
ForEach ($scene in $dataFiles)
{
    $counter = $counter +1
    $yr =  $scene.tmp.Substring(11,4)
    $mo = $scene.tmp.Substring(15,2).trimstart('0')
    $day = $scene.tmp.Substring(17,2).trimstart('0')

   $fn = "s3://sentinel-s2-l1c/products/" + $yr + "/" + $mo + "/" + $day + "/" + $scene.tmp
   $fd = "s3://derekja/"+$inFile+".results/"+$scene.tmp

    Write-Host $counter
    Write-Host $fn
    $fp =  "pwsh.exe"
    $fa = "/c aws s3 cp " + $fn + " " + $fd + " --recursive --request-payer 'requester'"
    #
    Write-host $fp
    Write-Host $fa
    if (($counter % 10) -eq 0) {
        Start-Process -FilePath $fp -ArgumentList $fa -WindowStyle Minimized -Wait
    } else {
        Start-Process -FilePath $fp -ArgumentList $fa -WindowStyle Minimized
    }
}

