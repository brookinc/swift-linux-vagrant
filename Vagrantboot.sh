#!/usr/bin/env bash

# update this variable to reflect the desired Swift version to install
# (for details and latest binaries, see https://swift.org/download/)
SWIFT_VERSION='4.0.2'  # examples: '4.0', '3.1.1', '2.2.1'

# determine the current operating system version
OS_VERSION_PATTERN="Release:.([0-9][0-9])\.([0-9][0-9])"
OS_VERSION_SOURCE=$(lsb_release -a)
if [[ $OS_VERSION_SOURCE =~ $OS_VERSION_PATTERN ]] ; then
  OS_VERSION_MAJOR="${BASH_REMATCH[1]}"
  OS_VERSION_MINOR="${BASH_REMATCH[2]}"
  OS_VERSION="$OS_VERSION_MAJOR.$OS_VERSION_MINOR"
  echo "OS version detected: Ubuntu $OS_VERSION_MAJOR.$OS_VERSION_MINOR..."
else
  echo "ERROR: Couldn't determine operating system version; exiting installation."
  exit 1
fi

# (for now, this script has only been tested with Ubuntu 16.04)
if [ "$OS_VERSION" != "16.04" ] ; then
  echo "ERROR: Unknown operating system version; exiting installation."
  exit 1
fi

# set up file names and paths based on the above
SWIFT_PLATFORM_PATH="ubuntu$OS_VERSION_MAJOR$OS_VERSION_MINOR"
SWIFT_PLATFORM="ubuntu$OS_VERSION_MAJOR.$OS_VERSION_MINOR"
SWIFT_RELEASE="swift-$SWIFT_VERSION-RELEASE-$SWIFT_PLATFORM"
SWIFT_ARCHIVE="$SWIFT_RELEASE.tar.gz"
SWIFT_URL="https://swift.org/builds/swift-$SWIFT_VERSION-release/$SWIFT_PLATFORM_PATH/swift-$SWIFT_VERSION-RELEASE/$SWIFT_ARCHIVE"

# Update and upgrade any existing packages
UPDATE_PACKAGES=true
if [ "$UPDATE_PACKAGES" = true ] ; then
  echo "Updating packages..."
  sudo apt -y update
  sudo apt -y full-upgrade
  sudo apt -y autoremove
  sudo apt -y clean
else
  echo "Skipping package updates..."
fi

INSTALL_SWIFT=true
if [ "$INSTALL_SWIFT" = true ] ; then
  echo "Installing Swift dependencies..."

  # You can use `apt search MYKEYWORD` to search for available packages,
  # and `apt policy MYPACKAGENAME` to see available versions.
  sudo apt install -y clang
  sudo apt install -y libicu-dev
  # we also need python2.7 for now -- see: https://bugs.swift.org/browse/SR-2743
  sudo apt install -y libpython2.7-dev

  echo "Installing Swift..."

  # download the archive and signature files
  mkdir /vagrant/swift
  curl $SWIFT_URL > "/vagrant/swift/$SWIFT_ARCHIVE"
  curl "$SWIFT_URL.sig" > "/vagrant/swift/$SWIFT_ARCHIVE.sig"

  # import the Swift PGP keys (see: https://swift.org/download/#using-downloads)
  wget -q -O - https://swift.org/keys/all-keys.asc | gpg --import -
  # ...and verify the archive:
  gpg --keyserver hkp://pool.sks-keyservers.net --refresh-keys Swift
  gpg --verify "/vagrant/swift/$SWIFT_ARCHIVE.sig"
  if [ $? -eq 0 ] ; then
      echo "Archive integrity verified..."
  else
      echo "ERROR: Archive integrity check failed; exiting installation."
      exit 1
  fi

  # extract the archive (creates a "usr" subdir)
  cd /vagrant/swift
  tar xzf $SWIFT_ARCHIVE

  # add our swift dir to $PATH for the current session:
  export PATH=/vagrant/swift/$SWIFT_RELEASE/usr/bin:"${PATH}"
  # ...and for all future sessions, by adding an entry to ~ubuntu/.profile
  # (we have to specify the default username, 'ubuntu', here -- we can't use just use
  # ~/.profile, because we're running as root, so ~/.profile evaluates to /root/.profile)
  echo "PATH=\"/vagrant/swift/$SWIFT_RELEASE/usr/bin:\$PATH\"" >> ~ubuntu/.profile

  # test our swift install
  swift /vagrant/test.swift
  if [ $? -eq 0 ] ; then
      echo "Swift test script executed successfully!"
  else
      echo "ERROR: couldn't execute Swift test script."
      exit 1
  fi

  # delete the archive and signature files
  rm -f "/vagrant/swift/$SWIFT_ARCHIVE"
  rm -f "/vagrant/swift/$SWIFT_ARCHIVE.sig"
else
  echo "Skipping Swift install..."
fi

# Clean up again now that we're done installing
sudo apt -y autoremove
sudo apt -y clean
echo "Setup complete."
