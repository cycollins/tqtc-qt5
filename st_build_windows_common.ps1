$BUILD_DIRECTORY = $(get-location)
echo "Build directory: $BUILD_DIRECTORY"

$SOURCE_DIRECTORY = $(split-path $script:MyInvocation.MyCommand.Path)
echo "Source directory: $SOURCE_DIRECTORY"

$bits = $args[0]
$osname = "win$bits"
echo "OS: $osname"

# Get the HEAD changeset which will be used to name the install folder
(set-location $SOURCE_DIRECTORY)
$git_path = "$env:TEAMCITY_GIT_PATH"
if (!($git_path)) {
  $git_path = "git"
}
$version = $(& "$git_path" rev-parse HEAD)
(set-location $BUILD_DIRECTORY)
if (!($version)) {
  echo "Error: could not get the revision."
  exit 1
}
echo "Revision: $version"

# Get sw-dev directory.
$sw_dev = "$BUILD_DIRECTORY\sw-dev"
if (-not (test-path "$sw_dev" -pathtype container)) {
  $sw_dev = "$env:QT_BUILD_SWDEV"
  if (-not "$sw_dev") {
    echo "Please set QT_BUILD_SWDEV to a valid sw-dev directory path."
    exit 1;
  }
  if (-not (test-path "$sw_dev" -pathtype container)) {
    echo "Please set QT_BUILD_SWDEV to a valid sw-dev directory path; `"$sw_dev`" does not exist."
    exit 1;
  }
}
echo "SW-DEV: $sw_dev"

$openssl_version = (Get-Content "$SOURCE_DIRECTORY\st_openssl_version.txt")
echo "OpenSSL version: '$openssl_version'"
new-item -path "$BUILD_DIRECTORY\qtbase" -type directory -force
copy-item "$SOURCE_DIRECTORY\st_openssl_version.txt" "$BUILD_DIRECTORY\qtbase\" -force
if ($osname -eq "win32") {
  cmake -D WIN32=1 -D X86=1 -D SW_DEV="$sw_dev" -D OPENSSL_VERSION="$openssl_version" -P "$SOURCE_DIRECTORY\st_third_party.cmake"
} else {
  cmake -D WIN32=1 -D SW_DEV="$sw_dev" -D OPENSSL_VERSION="$openssl_version" -P "$SOURCE_DIRECTORY\st_third_party.cmake"
}
if ($LastExitCode -ne 0) { exit $LastExitCode }
$openssl_dir = "$env:APPDATA\bacon\thirdparty\openssl\$openssl_version-$osname"
echo "Downloaded OpenSSL to `"$openssl_dir`"."

& "$SOURCE_DIRECTORY\configure.bat" -prefix "$BUILD_DIRECTORY\$version" -debug-and-release -force-debug-info -opensource -confirm-license -shared -platform win32-msvc2015 -no-feature-bearermanagement -I "$openssl_dir\include" -L "$openssl_dir\lib" -openssl-linked -nomake examples -nomake tests -no-compile-examples -no-icu -mp -opengl dynamic OPENSSL_LIBS="-llibeay$bits -lssleay$bits"
if ($LastExitCode -ne 0) { exit $LastExitCode }
echo "Configuration complete."

jom
if ($LastExitCode -ne 0) { exit $LastExitCode }
echo "Make complete."

python "$SOURCE_DIRECTORY\st_gen_and_upload_symbols.py" --os $osname --swdev "$sw_dev"
if ($LastExitCode -ne 0) { exit $LastExitCode }
echo "Symbol upload complete."

jom install
if ($LastExitCode -ne 0) { exit $LastExitCode }
copy-item -verbose "$openssl_dir\bin\*.dll" ".\$version\bin"
if ($LastExitCode -ne 0) { exit $LastExitCode }
copy-item "$BUILD_DIRECTORY\qtbase\st_openssl_version.txt" "$BUILD_DIRECTORY\$version\"
if ($LastExitCode -ne 0) { exit $LastExitCode }
echo "Installation to staging directory complete."

# Remove the pdb files from the build since the
# symbols have already been converted and uploaded to the server
get-childitem .\$version -include *.pdb -recurse | foreach ($_) {remove-item $_.fullname}
if ($LastExitCode -ne 0) { exit $LastExitCode }
echo "PDB file removal from staging directory complete."

cmake -E tar cvzf "qt-$version-$osname.tar.gz" ".\$version"
if ($LastExitCode -ne 0) { exit $LastExitCode }
echo "Tarball generation complete."

# Delete the version folder, since the way teamcity cleans things having a folder that's
# also a revision is bad
remove-item -force -recurse .\$version
echo "Staging directory deletion complete."
