$gen_hashes = $false  # set this to $true if you want to generate hashes instead of really installing

$ErrorActionPreference = 'Stop'; # stop on all errors
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$dotted_vers = $env:ChocolateyPackageVersion
$dashed_vers = $env:ChocolateyPackageVersion.replace('.', '-') + '00'

$urls = @{
    '64_main' = "http://dl.openafs.org/dl/openafs/{0}/winxp/openafs-en_US-64bit-{1}.msi" -f $dotted_vers, $dashed_vers
    '64_32tools' = "http://dl.openafs.org/dl/openafs/{0}/winxp/openafs-32bit-tools-en_US-{1}.msi" -f $dotted_vers, $dashed_vers
    '32' = "http://dl.openafs.org/dl/openafs/{0}/winxp/openafs-en_US-{1}.msi" -f $dotted_vers, $dashed_vers
}

if($gen_hashes) {
    $write_out = New-Object System.Collections.ArrayList
    foreach($url in $urls.keys) {
        '"{0}" is url: "{1}"' -f $url, $urls[$url]
        Invoke-WebRequest -Uri $urls[$url] -OutFile $url -UseBasicParsing
        $hash = Get-FileHash $url -Algorithm SHA256 | select -ExpandProperty Hash
        $hashline = '"{0}" = "{1}"' -f $url, $hash.ToLower()
        $hashline
        $write_out.Add($hashline)
        del $url
        }
    'OK done, copy & replace: '
    ''
    '$hashes = @{'
    foreach($line in $write_out) {
        '	' + $line
    }
    '}'
    exit 1
}

$hashes = @{
	'64_main' = "fb65c94baa7980bf12706d0e088a14f5675da4f0376afd50857a01303309d6c4"
    '32' = "f22d4bfc309b9b702f7cf2bce2cb77489f2055e092655c36f43a4ebe98f3a6d71"
	'64_32tools' = "9879d1d61c700957f1da106b70b2c85334aeba0b5174020099814c1d8b311c34"
}

$packageArgs = @{
    packageName = $env:ChocolateyPackageName
    url = $urls['32']
	checksum = $hashes['32']
	checksumType  = 'sha256'
    FileType = 'msi'
    url64 = $urls['64_main']
	checksum64 = $hashes['64_main']	
    silent = '/quiet /norestart' 
    validExitCodes= @(0, 3010)
}

$packageArgs_64only = @{
    packageName = $env:ChocolateyPackageName
    url = $urls['64_32tools']
	checksum = $hashes['64_32tools']
	checksumType  = 'sha256'	
    FileType = 'msi'
    silent = '/quiet /norestart' 
    validExitCodes= @(0, 3010)
}

Install-ChocolateyPackage @packageArgs
if($env:OS_IS64BIT) {
    Install-ChocolateyPackage @packageArgs_64only
}