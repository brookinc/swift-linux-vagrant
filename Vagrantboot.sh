#!/usr/bin/env bash

# update this variable to reflect the desired Swift version to install
# (for details and latest binaries, see https://swift.org/download/)
SWIFT_VERSION='4.1'  # examples: '4.0', '3.1.1', '2.2.1'

# determine the current operating system version
OS_VERSION_PATTERN="Release:[^0-9]([0-9][0-9])\.([0-9][0-9])"
OS_VERSION_SOURCE=$(lsb_release -a)
if [[ $OS_VERSION_SOURCE =~ $OS_VERSION_PATTERN ]] ; then
  OS_VERSION_MAJOR="${BASH_REMATCH[1]}"
  OS_VERSION_MINOR="${BASH_REMATCH[2]}"
  echo "OS version detected: Ubuntu $OS_VERSION_MAJOR.$OS_VERSION_MINOR..."
else
  echo "ERROR: Couldn't determine operating system version; exiting installation."
  exit 1
fi

# set up file names and paths based on the above
SWIFT_PLATFORM_PATH="ubuntu$OS_VERSION_MAJOR$OS_VERSION_MINOR"
SWIFT_PLATFORM="ubuntu$OS_VERSION_MAJOR.$OS_VERSION_MINOR"
SWIFT_RELEASE="swift-$SWIFT_VERSION-RELEASE-$SWIFT_PLATFORM"
SWIFT_ARCHIVE="$SWIFT_RELEASE.tar.gz"
SWIFT_URL="https://swift.org/builds/swift-$SWIFT_VERSION-release/$SWIFT_PLATFORM_PATH/swift-$SWIFT_VERSION-RELEASE/$SWIFT_ARCHIVE"

if (( $OS_VERSION_MAJOR >= 16 )) ; then
  APT=apt
else
  APT=apt-get
fi
echo "Using $APT for package installation..."

# Update and upgrade any existing packages
UPDATE_PACKAGES=true
if [ "$UPDATE_PACKAGES" = true ] ; then
  echo "Updating packages..."
  sudo $APT -y update
  if (($OS_VERSION_MAJOR >= 16)) ; then
    sudo apt -y full-upgrade
  else
    sudo apt-get -y dist-upgrade
  fi
  sudo $APT -y autoremove
  sudo $APT -y clean
else
  echo "Skipping package updates..."
fi

INSTALL_SWIFT=true
if [ "$INSTALL_SWIFT" = true ] ; then
  echo "Installing Swift dependencies..."

  # You can use `apt search MYKEYWORD` to search for available packages,
  # and `apt policy MYPACKAGENAME` to see available versions.
  sudo $APT install -y clang
  sudo $APT install -y libicu-dev
  # we also need python2.7 for now -- see: https://bugs.swift.org/browse/SR-2743
  sudo $APT install -y libpython2.7-dev

  echo "Installing Swift..."

  # download the archive and signature files
  if [ ! -d /vagrant/swift ] ; then
    mkdir /vagrant/swift
  fi
  curl --fail --silent --show-error $SWIFT_URL > "/vagrant/swift/$SWIFT_ARCHIVE"
  CURL_ERROR=$?
  curl --fail --silent --show-error "$SWIFT_URL.sig" > "/vagrant/swift/$SWIFT_ARCHIVE.sig"
  CURL_ERROR=$(($CURL_ERROR+$?))
  if [ $CURL_ERROR -eq 0 ] ; then
    echo "Swift archive downloaded..."
  else
    echo "ERROR: Swift archive $SWIFT_ARCHIVE couldn't be downloaded. Double-check that this platform version + Swift version are listed here: https://swift.org/download/"
    rm -f "/vagrant/swift/$SWIFT_ARCHIVE" "/vagrant/swift/$SWIFT_ARCHIVE.sig"
    exit 1
  fi

  # import the Swift PGP keys (see: https://swift.org/download/#using-downloads)
  wget -q -O - https://swift.org/keys/all-keys.asc | gpg --import -
  # ...and verify the archive:
  gpg --keyserver hkp://pool.sks-keyservers.net --refresh-keys Swift
  gpg --verify "/vagrant/swift/$SWIFT_ARCHIVE.sig"
  if [ $? = 0 ] ; then
    echo "Swift archive integrity verified..."
  else
    echo "ERROR: Swift archive integrity check failed; exiting installation."
    exit 1
  fi

  # extract the archive (creates a "swift/[this-swift-version]/usr" subdir under /vagrant)
  cd /vagrant/swift
  tar xzf $SWIFT_ARCHIVE

  # add our swift dir to $PATH for the current session:
  export PATH=/vagrant/swift/$SWIFT_RELEASE/usr/bin:"${PATH}"
  # ...and for all future sessions, by adding an entry to ~ubuntu/.profile
  # (we have to specify the default username, 'ubuntu', here -- we can't use just use
  # ~/.profile, because we're running as root, so ~/.profile evaluates to /root/.profile)
  echo "PATH=\"/vagrant/swift/$SWIFT_RELEASE/usr/bin:\$PATH\"" >> ~ubuntu/.profile
  # also add our path to ~vagrant/.profile, for the cases when that's the default user:
  if [ -e ~vagrant/.profile ] ; then
    echo "PATH=\"/vagrant/swift/$SWIFT_RELEASE/usr/bin:\$PATH\"" >> ~vagrant/.profile
  fi

  # test our swift install
  swift /vagrant/test.swift
  if [ $? -eq 0 ] ; then
    echo "Swift test script executed successfully!"
  else
    echo "ERROR: couldn't execute Swift test script."
    exit 1
  fi

  # delete the archive and signature files
  rm -f "/vagrant/swift/$SWIFT_ARCHIVE" "/vagrant/swift/$SWIFT_ARCHIVE.sig"
else
  echo "Skipping Swift install..."
fi

# Clean up again now that we're done installing
sudo $APT -y autoremove
sudo $APT -y clean
echo "Setup complete."
