#!/bin/bash

echo -e "\n\t\t\t-------- install.sh started --------\n\t\t\t"

# install dev environments
echo -e "\tinstalling dev environments ..."
  dependencies=(gcc g++ python3-dev libffi-dev openssl-dev)
  for dev in ${dependencies[@]}
  do
  	apk add $dev 
  done
echo -e "\tdev environments installed"

# install packages
echo -e "\tinstalling packages ..."
  cat ./requirements.txt | while read line || [ -n "$line" ]
  do
   	echo -e "\tinstalling" $line " ..."
   	pip install $line -i http://pypi.douban.com/simple --trusted-host pypi.douban.com
   	echo -e "\t----------" $line "installed. ----------" 
  done
echo -e "\n\t\t\t-------- final check --------\n\t\t\t"

# uninstall dev environments
echo -e "\tuninstalling dev environments ..."
  dependencies=(gcc g++ python3-dev libffi-dev openssl-dev)
  for dev in ${dependencies[@]}
  do
  	apk del $dev 
  done
echo -e "\tdev environments uninstalled"

# finnally check

requirements=()
while read line
do
  line=${line/%>=*/""}
  line=${line/%==*/""}
  line=`echo $line | tr "[A-Z]" "[a-z]"`
  requirements+=($line)
done << EOT
`cat ./requirements.txt`
EOT
#echo -e requirements "\n\t" ${requirements[@]}

installed=()
while read line
do
  #echo $line
  line=${line/%\(*\)/""}
  line=`echo $line | tr "[A-Z]" "[a-z]"`
  installed+=($line)
done << EOT
`pip list --format=legacy`
EOT
#echo -e installed "\n\t" ${installed[@]}

all_installed=1
for r in ${requirements[@]}
do
  #echo $r
  if ! [[ "${installed[@]}" =~ $r ]]; then 
    echo $r is not installed
    # echo -e "\t" installing ...
    # pip install $r
    # echo -e "\t" $r is installed
    all_installed=0
  fi
done
if [ $all_installed -eq 1 ]; then
  echo all packages installed.
fi

echo -e "\n\t\t\t-------- install.sh finished --------\n\t\t\t"
