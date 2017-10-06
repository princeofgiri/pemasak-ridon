echo "What devices that you wanna build?"
read devicecode
while true; do
  echo "Build "$devicecode "for first time? (y/n)"
  read INPUT
  if [ "$INPUT" = "y" ]; then
    echo "yes"
  elif [ "$INPUT" = "n" ]; then
    echo "Please enter last BUILD NUMBER!"
    read lastBUILD_NUMBER
    export lastBUILD_NUMBER=$lastBUILD_NUMBER
  else
    echo "Input not understood"
    continue
  fi
  break
done

echo "Input build number (2 digit number)"
read buildno
timestamp=`date +%Y%m%d`
buildnumber=$timestamp$buildno
echo $devicecode: $buildnumber
export DEVICE=$devicecode

source build/envsetup.sh
echo breakfast $devicecode user
export RELEASE_TYPE=RELEASE
export BUILD_TYPE=nightly
breakfast $devicecode user
echo croot
croot

sed -i 's/BUILD_KEYS := dev-keys/BUILD_KEYS := release-keys/' build/core/Makefile

mka BUILD_NUMBER=$buildnumber target-files-package dist
export MODVERSION=`grep -r ro.modversion $OUT/system/build.prop | cut -f2 -d=`
export BUILD_NUMBER=$buildnumber
./sign.tcl
./build/tools/releasetools/ota_from_target_files -k ~/.ridon-certs/otakey --block --backup=true signed-target_files-$BUILD_NUMBER.zip $OUT/ridon-$MODVERSION-signed-$BUILD_NUMBER.zip

if [ "$INPUT" = "y" ]; then
    echo "Creating directory for "$devicecode
    mkdir -p ~/ridon/ROM/$devicecode/
    echo "Copying ROM to download's directory"
    cp $OUT/ridon-$MODVERSION-signed-$BUILD_NUMBER.zip ~/ridon/ROM/$devicecode/
  else
    echo "Creating update's directore for "$devicecode
    mkdir -p ~/ridon/ROM/$devicecode/updates
    echo "Copying ROM to update's directory"
    cp $OUT/ridon-$MODVERSION-signed-$BUILD_NUMBER.zip ~/ridon/ROM/$devicecode/updates/

    echo "Creating API directory for device"
    mkdir -p ~/ridon/ROM/api/v1/$CM_BUILD/$BUILD_TYPE/$lastBUILD_NUMBER

    echo "Creating json"
    datetime = cat out/build_date.txt
    
    echo "Creating ID"
    ID32=`uuid|tr -d "-"`
    ID=${ID32:0:24}

    echo '
    {
    "response": [
        {
        "datetime": $datetime,
        "filename": "ridon-"$MODVERSION"-signed-"$BUILD_NUMBER".zip",
        "id": $ID,
        "romtype": $BUILD_TYPE,
        "url": "http://download.ridon.id/"$CM_BUILD"/updates/ridon-"$MODVERSION"-signed-"$BUILD_NUMBER".zip",
        "version": "7.0"
        }
    ]
    }' >> ~/ridon/ROM/api/v1/$CM_BUILD/$BUILD_TYPE/$lastBUILD_NUMBER/update.json


fi

echo "Finish Build!!!"
