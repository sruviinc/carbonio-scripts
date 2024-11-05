#!/bin/bash
FILE=/etc/apt/sources.list.d/zextras.list

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ -f "$FILE" ]; then
    echo "$FILE already exists, do you want to update it? "
    read answer
    if [ "$answer" != "${answer#[Yy]}" ] ;then 
    echo "$FILE will be updated"
else
    echo "$FILE has not been changed" 
    exit
fi
else
    echo "$FILE does not exist, it will be added to the list of repositories."
fi

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/zextras.gpg] https://repo.zextras.io/release/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/zextras.list

wget -O- "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x5dc7680bc4378c471a7fa80f52fd40243e584a21" | gpg --dearmor | sudo tee /usr/share/keyrings/zextras.gpg > /dev/null
chmod 644 /usr/share/keyrings/zextras.gpg

apt update -yq

if [ -f "$FILE" ]; then
echo "Carbonio Repositories has been successufilly installed"
else
echo "failed"
exit
fi
