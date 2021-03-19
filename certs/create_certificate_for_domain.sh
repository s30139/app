#!/usr/bin/env bash
DIR="$(pwd)"
echo ${DIR}
device_key="device.key"
echo ${device_key}
device_csr="device.csr"
device_crt="device.crt"
echo $device_csr $device_crt
v3_tmp="v3.tmp"
#exit


if [ -z "$1" ]
then
  echo "Please supply a subdomain to create a certificate for";
  echo "e.g. www.mysite.com"
  exit;
fi

if [ ! -f ../rootCA.pem ]; then
  echo 'Please run "create_root_cert_and_key.sh" first, and try again!'
  exit;
fi
if [ ! -f ../v3.ext ]; then
  echo 'Please download the "v3.ext" file and try again!'
  exit;
fi

# Create a new private key if one doesnt exist, or use the xeisting one if it does
if [ -f $device_key ]; then
  KEY_OPT="-key"
else
  KEY_OPT="-keyout"
fi

DOMAIN=$1
COMMON_NAME=${2:-$1}
SUBJECT="/C=CA/ST=None/L=NB/O=None/CN=$COMMON_NAME"
NUM_OF_DAYS=9876
openssl req -new -newkey rsa:2048 -sha256 -nodes $KEY_OPT $device_key -subj "$SUBJECT" -out $device_csr
cat ../v3.ext | sed s/%%DOMAIN%%/"$COMMON_NAME"/g > $v3_tmp #/tmp/__v3.ext
openssl x509 -req -in $device_csr -CA ../rootCA.pem -CAkey ../rootCA.key -CAcreateserial -out $device_crt -days $NUM_OF_DAYS -sha256 -extfile $v3_tmp

# move output files to final filenames
chmod 444 $device_key;
mv $device_key "$DIR/$DOMAIN.key";

mv $device_csr "$DIR/$DOMAIN.csr";
mv $device_crt "$DIR/$DOMAIN.crt";

# remove temp file
rm -f $v3_tmp

echo 
echo "###########################################################################"
echo Done! 
echo "###########################################################################"
echo "To use these files on your server, simply copy both $DOMAIN.csr and"
echo "device.key to your webserver, and use like so (if Apache, for example)"
echo 
echo "    SSLCertificateFile    /path_to_your_files/$DOMAIN.crt"
echo "    SSLCertificateKeyFile /path_to_your_files/device.key"