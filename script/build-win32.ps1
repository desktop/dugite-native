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
$git_version="2.13.1"
$mingit_version="v2.13.1.windows.2"

Push-Location
Set-Location -Path (New-TemporaryDirectory).FullName

Invoke-WebRequest -Uri "http://freakcode.s3.amazonaws.com/7za-x64.exe" -OutFile 7za.exe
Invoke-WebRequest -Uri "https://github.com/git-for-windows/build-extra/releases/download/$git_sdk_tag/git-sdk-installer-1.0.3-64.7z.exe" -OutFile git-sdk-installer.7z.exe

& .\7za.exe x -oC:\git-sdk-64 git-sdk-installer.7z.exe

Set-Location -Path c:\git-sdk-64
# Setting this will prevent the setup-git-sdk script from actually cloning and building
# the source. We'll do that ourselves as we need to do some patching.
$env:JENKINS_URL="http://127.0.0.1"

& .\setup-git-sdk.bat

# set MSYSTEM so that MSYS2 starts up in the correct mode
$env:MSYSTEM = "MINGW64"

$bash = ".\usr\bin\bash.exe"

Write-Output "Copying patches to accessible location"
Copy-Item $patchDirectory ".\tmp" -Verbose -Recurse

& $bash --login -c "mkdir -p /usr/src"
& $bash --login -c "git clone -b master -c core.autocrlf=false https://github.com/git-for-windows/build-extra /usr/src/build-extra"
& $bash --login -c "git clone -b $mingit_version -c core.autocrlf=false https://github.com/git-for-windows/git /usr/src/git"
& $bash --login -c "(cd /usr/src/git && git apply /c/git-sdk-64/tmp/patches/*) 2>&1"
& $bash --login -c "cd /usr/src/git && make all strip install NO_PERL=1 NO_TCLTK=1 NO_GETTEXT=1 NO_INSTALL_HARDLINKS=1"
& $bash --login -c "/usr/src/build-extra/installer/release.sh $git_version"
& $bash --login -c "/usr/src/build-extra/mingit/release.sh --output=/c/git-sdk-64/tmp $mingit_version"

$mingitPackagePath = (Join-Path (Get-Location) "tmp\MinGit-$mingit_version-64-bit.zip")

Pop-Location
Move-Item $mingitPackagePath "git-for-windows.zip"
