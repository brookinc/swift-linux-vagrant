#!/usr/bin/env bash

# add any environment variables needed to configure vagrant (see: https://www.vagrantup.com/docs/other/environmental-variables.html)
export VAGRANT_PREFER_SYSTEM_BIN=0  # (see: https://github.com/brookinc/swift-linux-vagrant/issues/1 and https://github.com/hashicorp/vagrant/pull/9503)

# also save said environment variables into our .profile for all future sessions
echo "VAGRANT_PREFER_SYSTEM_BIN=0" >> ~ubuntu/.profile
if [ -e ~vagrant/.profile ] ; then
  echo "VAGRANT_PREFER_SYSTEM_BIN=0" >> ~vagrant/.profile
fi

# update this variable to reflect the desired Swift version to install
# (for details and latest binaries, see https://swift.org/download/)
# (this field may also be left blank when a dev snapshot version of
# the trunk / master branch is specified below)
SWIFT_VERSION='4.1.2'  # examples: '4.0', '3.1.1', '2.2.1'

# fill in this variable if you want to download a specific development snapshot rather than a final release
# (for details and latest binaries, see https://swift.org/download/)
SWIFT_DEV_SNAPSHOT=''  # example: '2018-06-29-a'

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
SWIFT_RELEASE="swift-$SWIFT_VERSION-RELEASE"
SWIFT_ARCHIVE="$SWIFT_RELEASE-$SWIFT_PLATFORM.tar.gz"
SWIFT_URL="https://swift.org/builds/swift-$SWIFT_VERSION-release/$SWIFT_PLATFORM_PATH/$SWIFT_RELEASE/$SWIFT_ARCHIVE"

if [ -n "$SWIFT_DEV_SNAPSHOT" ] ; then
  if [ -n "$SWIFT_VERSION" ] ; then
    # setup specified version snapshot links
    SWIFT_RELEASE="swift-$SWIFT_VERSION-DEVELOPMENT-SNAPSHOT-$SWIFT_DEV_SNAPSHOT"
    SWIFT_ARCHIVE="$SWIFT_RELEASE-$SWIFT_PLATFORM.tar.gz"
    SWIFT_URL="https://swift.org/builds/swift-$SWIFT_VERSION-branch/$SWIFT_PLATFORM_PATH/$SWIFT_RELEASE/$SWIFT_ARCHIVE"
  else
    # setup trunk / master dev snapshot links
    SWIFT_RELEASE="swift-DEVELOPMENT-SNAPSHOT-$SWIFT_DEV_SNAPSHOT"
    SWIFT_ARCHIVE="$SWIFT_RELEASE-$SWIFT_PLATFORM.tar.gz"
    SWIFT_URL="https://swift.org/builds/development/$SWIFT_PLATFORM_PATH/$SWIFT_RELEASE/$SWIFT_ARCHIVE"
  fi
  echo "Using development snapshot $SWIFT_RELEASE-$SWIFT_PLATFORM..."
else
  echo "Using release $SWIFT_RELEASE-$SWIFT_PLATFORM..."
fi

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
  # we also need libcurl3 for now -- see: https://bugs.swift.org/browse/SR-2744
  sudo $APT install -y libcurl3

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
  export PATH=/vagrant/swift/$SWIFT_RELEASE-$SWIFT_PLATFORM/usr/bin:"${PATH}"
  # ...and for all future sessions, by adding an entry to ~ubuntu/.profile
  # (we have to specify the default username, 'ubuntu', here -- we can't use just use
  # ~/.profile, because we're running as root, so ~/.profile evaluates to /root/.profile)
  echo "PATH=\"/vagrant/swift/$SWIFT_RELEASE-$SWIFT_PLATFORM/usr/bin:\$PATH\"" >> ~ubuntu/.profile
  # also add our path to ~vagrant/.profile, for the cases when that's the default user:
  if [ -e ~vagrant/.profile ] ; then
    echo "PATH=\"/vagrant/swift/$SWIFT_RELEASE-$SWIFT_PLATFORM/usr/bin:\$PATH\"" >> ~vagrant/.profile
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

INSTALL_SWIFTLINT=false
if [ "$INSTALL_SWIFTLINT" = true ] ; then
  echo "Installing SwiftLint..."
  # for details, see: https://github.com/realm/SwiftLint/issues/732#issuecomment-339502688
  sudo $APT install -y clang
  sudo $APT install -y libblocksruntime0
  sudo $APT install -y libcurl4-openssl-dev

  export LINUX_SOURCEKIT_LIB_PATH="/vagrant/swift/$SWIFT_RELEASE-$SWIFT_PLATFORM/usr/lib"
  echo "LINUX_SOURCEKIT_LIB_PATH=\"/vagrant/swift/$SWIFT_RELEASE-$SWIFT_PLATFORM/usr/lib\"" >> ~ubuntu/.profile
  if [ -e ~vagrant/.profile ] ; then
    echo "LINUX_SOURCEKIT_LIB_PATH=\"/vagrant/swift/$SWIFT_RELEASE-$SWIFT_PLATFORM/usr/lib\"" >> ~vagrant/.profile
  fi

  git clone https://github.com/realm/SwiftLint.git /vagrant/swift/swiftlintbuild
  pushd /vagrant/swift/swiftlintbuild
  swift build -c release --static-swift-stdlib
  if [ ! -d /vagrant/swift/swiftlint ] ; then
    mkdir /vagrant/swift/swiftlint
  fi
  mv .build/x86_64-unknown-linux/release/swiftlint /vagrant/swift/swiftlint
  popd
  rm -rf /vagrant/swift/swiftlintbuild

  export PATH=/vagrant/swift/swiftlint:"${PATH}"
  echo "PATH=\"/vagrant/swift/swiftlint:\$PATH\"" >> ~ubuntu/.profile
  # also add our path to ~vagrant/.profile, for the cases when that's the default user:
  if [ -e ~vagrant/.profile ] ; then
    echo "PATH=\"/vagrant/swift/swiftlint:\$PATH\"" >> ~vagrant/.profile
  fi

  # write out a blank swiftlint configuration file
  if [ ! -e /vagrant/.swiftlint.yml ] ; then
    echo "Creating .swiftlint.yml..."
    pushd /vagrant
    echo "# For an overview of .swiftlint.yml files, see:" >> .swiftlint.yml
    echo "# https://github.com/realm/SwiftLint#configuration" >> .swiftlint.yml
    echo "# For a sample .swiftlint.yml file, see:" >> .swiftlint.yml
    echo "# https://github.com/realm/SwiftLint/blob/master/.swiftlint.yml" >> .swiftlint.yml
    echo "# For a full list of supported rules, see:" >> .swiftlint.yml
    echo "# https://github.com/realm/SwiftLint/blob/master/Rules.md" >> .swiftlint.yml
    echo "included:" >> .swiftlint.yml
    echo "# (default -- all files)" >> .swiftlint.yml
    echo "excluded:" >> .swiftlint.yml
    echo "# (default -- no exclusions)" >> .swiftlint.yml
    echo "disabled_rules:" >> .swiftlint.yml
    echo "# (use default rule set)" >> .swiftlint.yml
    echo "opt_in_rules:" >> .swiftlint.yml
    echo "# (use default rule set)" >> .swiftlint.yml
    popd
  fi
else
  echo "Skipping SwiftLint install..."
fi

# Clean up again now that we're done installing
sudo $APT -y autoremove
sudo $APT -y clean
echo "Setup complete."
