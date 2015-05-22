#!/bin/bash

major_version=
os=
host=

get_hostname ()
{
  echo "Getting the hostname of this machine..."

  host=`hostname -f 2>/dev/null`
  if [ "$host" = "" ]; then
    host=`hostname 2>/dev/null`
    if [ "$host" = "" ]; then
      host=$HOSTNAME
    fi
  fi

  if [ "$host" = "" ]; then
    echo "Unable to determine the hostname of your system!"
    echo
    echo "Please consult the documentation for your system. The files you need "
    echo "to modify to do this vary between Linux distribution and version."
    echo
    exit 1
  fi

  echo "Found hostname: ${host}"
}

curl_check ()
{
  echo "Checking for curl..."
  if command -v curl > /dev/null; then
    echo "Detected curl..."
  else
    echo "Installing curl..."
    yum install -d0 -e0 -y curl
  fi
}

unknown_os ()
{
  echo "Unfortunately, your operating system distribution and version are not supported by this script."
  echo "Please email support@packagecloud.io and we will be happy to help."
  exit 1
}

if [ -e /etc/os-release ]; then
  . /etc/os-release
  major_version=`echo ${VERSION_ID} | awk -F '.' '{ print $1 }'`
  os=${ID}

elif [ `which lsb_release 2>/dev/null` ]; then
  # get major version (e.g. '5' or '6')
  major_version=`lsb_release -r | cut -f2 | awk -F '.' '{ print $1 }'`

  # get os (e.g. 'centos', 'redhatenterpriseserver', etc)
  os=`lsb_release -i | cut -f2 | awk '{ print tolower($1) }'`

elif [ -e /etc/oracle-release ]; then
  major_version=`cut -f5 --delimiter=' ' /etc/oracle-release | awk -F '.' '{ print $1 }'`
  os='ol'

elif [ -e /etc/fedora-release ]; then
  major_version=`cut -f3 --delimiter=' ' /etc/fedora-release`
  os='fedora'

elif [ -e /etc/redhat-release ]; then
  os_hint=`cat /etc/redhat-release  | awk '{ print tolower($1) }'`
  if [ "${os_hint}" = "centos" ]; then
    major_version=`cat /etc/redhat-release | awk '{ print $3 }' | awk -F '.' '{ print $1 }'`
    os='centos'
  elif [ "${os_hint}" = "scientific" ]; then
    major_version=`cat /etc/redhat-release | awk '{ print $4 }' | awk -F '.' '{ print $1 }'`
    os='scientific'
  else
    major_version=`cat /etc/redhat-release  | awk '{ print tolower($7) }' | cut -f1 --delimiter='.'`
    os='redhatenterpriseserver'
  fi

else
  aws=`grep Amazon /etc/issue 2>&1 >/dev/null`
  if [ "$?" = "0" ]; then
    major_version='6'
    os='aws'
  else
    unknown_os
  fi
fi

if [[ ( -z "${os}" ) || ( -z "${major_version}" ) || ( "${os}" = "opensuse" ) ]]; then
  unknown_os
fi

echo "Detected ${os} version ${major_version}... "

curl_check

get_hostname

echo "Downloading repository file: https://${PACKAGECLOUD_TOKEN}:@packagecloud.io/install/repositories/Docker/cs/config_file.repo?os=${os}&dist=${major_version}&name=${host}"
yum_repo_path=/etc/yum.repos.d/Docker_cs.repo
curl -f "https://${PACKAGECLOUD_TOKEN}:@packagecloud.io/install/repositories/Docker/cs/config_file.repo?os=${os}&dist=${major_version}&name=${host}" > $yum_repo_path
curl_exit_code=$?

if [ "$curl_exit_code" = "22" ]; then
  echo
  echo -n "Unable to download repo config from: "
  echo "https://${PACKAGECLOUD_TOKEN}:@packagecloud.io/install/repositories/Docker/cs/config_file.repo?os=${os}&dist=${dist}&name=${host}"
  echo
  echo "Please contact support@packagecloud.io and report this."
  [ -e $yum_repo_path ] && rm $yum_repo_path
  exit 1
elif [ "$curl_exit_code" = "35" ]; then
  echo
  echo "curl is unable to connect to packagecloud.io over TLS when running: "
  echo "    curl https://${PACKAGECLOUD_TOKEN}:@packagecloud.io/install/repositories/Docker/cs/config_file.repo?os=${os}&dist=${major_version}&name=${host}"
  echo
  echo "This is usually due to one of two things:"
  echo
  echo " 1.) Missing CA root certificates (make sure the ca-certificates package is installed)"
  echo " 2.) An old version of libssl. Try upgrading libssl on your system to a more recent version"
  echo
  echo "Contact support@packagecloud.io with information about your system for help."
  [ -e $yum_repo_path ] && rm $yum_repo_path
  exit 1
elif [ "$curl_exit_code" -gt "0" ]; then
  echo
  echo "Unable to run: "
  echo " curl https://${PACKAGECLOUD_TOKEN}:@packagecloud.io/install/repositories/Docker/cs/config_file.repo?os=${os}&dist=${major_version}&name=${host}"
  echo
  echo "Double check your curl installation and try again."
  [ -e $yum_repo_path ] && rm $yum_repo_path
  exit 1
else
  echo "done."
fi

echo "Installing pygpgme to verify GPG signatures..."
yum install -y pygpgme --disablerepo='Docker_cs'
pypgpme_check=`rpm -qa | grep -qw pygpgme`
if [ "$?" != "0" ]; then
  echo
  echo "WARNING: "
  echo "The pygpgme package could not be installed. This means GPG verification is not possible for any RPM installed on your system. "
  echo "To fix this, add a repository with pygpgme. Usualy, the EPEL repository for your system will have this. "
  echo "More information: https://fedoraproject.org/wiki/EPEL#How_can_I_use_these_extra_packages.3F"
  echo

  # set the repo_gpgcheck option to 0
  sed -i'' 's/repo_gpgcheck=1/repo_gpgcheck=0/' /etc/yum.repos.d/Docker_cs.repo
fi

echo "Installing yum-utils..."
yum install -y yum-utils --disablerepo='Docker_cs'
yum_utils_check=`rpm -qa | grep -qw yum-utils`
if [ "$?" != "0" ]; then
  echo
  echo "WARNING: "
  echo "The yum-utils package could not be installed. This means you may not be able to install source RPMs or use other yum features."
  echo
fi

echo "Generating yum cache for Docker_cs..."
yum -q makecache -y --disablerepo='*' --enablerepo='Docker_cs'

