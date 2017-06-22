$patchDirectory = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\patches'))

# https://stackoverflow.com/a/34559554
function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    [string] $path = (Join-Path $parent $name)
    New-Item -ItemType Directory -Path $path
}

$git_sdk_version="1.0.3"
$git_sdk_tag="git-sdk-$git_sdk_version"
$git_version="v2.13.1.windows.2"
$mingit_version="2.13.1.2"

#$patchesLocation = (Join-Path (Get-Location) "..\"

Push-Location
Set-Location -Path (New-TemporaryDirectory).FullName

Invoke-WebRequest -Uri "http://freakcode.s3.amazonaws.com/7za-x64.exe" -OutFile 7za.exe
Invoke-WebRequest -Uri "https://github.com/git-for-windows/build-extra/releases/download/$git_sdk_tag/git-sdk-installer-1.0.3-64.7z.exe" -OutFile git-sdk-installer.7z.exe

& .\7za.exe x -oC:\git-sdk-64 git-sdk-installer.7z.exe

Set-Location -Path c:\git-sdk-64
Copy-Item $patchDirectory tmp

# Setting this will prevent the setup-git-sdk script from actually cloning and building
# the source. We'll do that ourselves as we need to do some patching.
$env:JENKINS_URL="http://127.0.0.1"

& .\setup-git-sdk.bat

# set MSYSTEM so that MSYS2 starts up in the correct mode
$env:MSYSTEM = "MINGW64"

$bash = ".\usr\bin\bash.exe"

& $bash --login -c "mkdir -p /usr/src && cd /usr/src && for project in MINGW-packages MSYS2-packages build-extra git; do test ! -d `$project && (git clone -b master -c core.autocrlf=false https://github.com/git-for-windows/`$project); done" 2> $null
& $bash --login -c "cd /usr/src/git && git am /tmp/patches/*" 2> $null
& $bash --login -c "cd /usr/src/git && make && make strip && make install" 2> $null
& $bash --login -c "/usr/src/build-extra/mingit/release.sh --output=/tmp $mingit_version" 2> $null

$mingitPackagePath = (Join-Path (Get-Location) "tmp\MinGit-$mingit_version-64-bit.zip")

Pop-Location
Move-Item $mingitPackagePath "git-for-windows.zip"
