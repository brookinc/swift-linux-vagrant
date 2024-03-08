#!/usr/bin/env bash

# helper function for setting simple environment variables (no expansion, ie. excluding $PATH)
set_env_variable () {
  # export it for the current session
  export "$1=$2"
  # save it to our .profile for all future sessions
  # (we have to specify the ~vagrant home directory here, since we're logged in as root when this script runs)
  echo "$1=$2" >> ~vagrant/.profile
}

# helper function for adding to $PATH
add_path () {
  # export it for the current session
  export "PATH=$1:$PATH"
  # save it to our .profile for all future sessions
  # (we have to specify the ~vagrant home directory here, since we're logged in as root when this script runs)
  echo "PATH=$1:\$PATH" >> ~vagrant/.profile  # we use \$ since we want expansion to occur when the file is read, not right now
}

# helper function for installing homebrew
install_homebrew () {
    # (see: https://docs.brew.sh/Homebrew-on-Linux)
    runuser -u vagrant -- /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/vagrant/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    sudo $APT install build-essential
    # TODO: the `-q` flag (here and in other `brew install` calls below) suppresses some output, but it's still very verbose -- is there any way to make it quieter?
    runuser -u vagrant -- brew install -q gcc
}

# add any environment variables needed to configure vagrant (see: https://www.vagrantup.com/docs/other/environmental-variables.html)
set_env_variable VAGRANT_PREFER_SYSTEM_BIN 0  # (see: https://github.com/brookinc/swift-linux-vagrant/issues/1 and https://github.com/hashicorp/vagrant/pull/9503)

# update this variable to reflect the desired Swift version to install
# (for details and latest binaries, see https://swift.org/download/)
# (this field may also be left blank when a dev snapshot version of
# the trunk / master branch is specified below)
SWIFT_VERSION='5.10'  # examples: '4.0', '3.1.1', '2.2.1'

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
SWIFT_URL="https://download.swift.org/swift-$SWIFT_VERSION-release/$SWIFT_PLATFORM_PATH/$SWIFT_RELEASE/$SWIFT_ARCHIVE"

if [ -n "$SWIFT_DEV_SNAPSHOT" ] ; then
  if [ -n "$SWIFT_VERSION" ] ; then
    # setup specified version snapshot links
    SWIFT_RELEASE="swift-$SWIFT_VERSION-DEVELOPMENT-SNAPSHOT-$SWIFT_DEV_SNAPSHOT"
    SWIFT_ARCHIVE="$SWIFT_RELEASE-$SWIFT_PLATFORM.tar.gz"
    SWIFT_URL="https://download.swift.org/swift-$SWIFT_VERSION-branch/$SWIFT_PLATFORM_PATH/$SWIFT_RELEASE/$SWIFT_ARCHIVE"
  else
    # setup trunk / master dev snapshot links
    SWIFT_RELEASE="swift-DEVELOPMENT-SNAPSHOT-$SWIFT_DEV_SNAPSHOT"
    SWIFT_ARCHIVE="$SWIFT_RELEASE-$SWIFT_PLATFORM.tar.gz"
    SWIFT_URL="https://download.swift.org/development/$SWIFT_PLATFORM_PATH/$SWIFT_RELEASE/$SWIFT_ARCHIVE"
  fi
  echo "Using development snapshot $SWIFT_RELEASE-$SWIFT_PLATFORM..."
else
  echo "Using release $SWIFT_RELEASE-$SWIFT_PLATFORM..."
fi

if (( $OS_VERSION_MAJOR >= 16 )) ; then
  APT="apt-get -qq -o=Dpkg::Use-Pty=0"
  # if desired, on Ubuntu 16+ you can use `apt` instead of `apt-get`:
  #APT="apt -qq"
else
  APT="apt-get -qq -o=Dpkg::Use-Pty=0"
fi
echo "Using $APT for package installation..."

# Update and upgrade any existing packages
UPDATE_PACKAGES=true
if [ "$UPDATE_PACKAGES" = true ] ; then
  echo "Updating packages..."
  sudo $APT update
  if [ "$APT" = apt ] ; then
    sudo $APT full-upgrade
  else
    sudo $APT dist-upgrade
  fi
  sudo $APT autoremove
  sudo $APT clean
else
  echo "Skipping package updates..."
fi

INSTALL_SWIFT=true
if [ "$INSTALL_SWIFT" = true ] ; then
  HOMEBREW_SWIFT=false
  if [ "$HOMEBREW_SWIFT" = true ] ; then  # (optionally, we can use homebrew to install the latest Swift)
    echo "Installing Swift..."
    install_homebrew
    # Note: homebrew does support targeting a specific version (ie. `brew search node` returns `node@18`, `node@20`, etc.),
    # but it appears the Swift homebrew package only publishes latest (`brew search swift` doesn't return any versioned packages),
    # so it doesn't look like we can target our given SWIFT_VERSION (or SWIFT_DEV_SNAPSHOT) here; we can only install latest.
    runuser -u vagrant -- brew install -q swift
    SWIFT_LIB_DIR=/home/linuxbrew/.linuxbrew/opt/swift/libexec/lib
  else  # (otherwise, we download the given Swift binary and install it manually)
    echo "Installing Swift dependencies..."

    # install dependencies per: https://www.swift.org/install/linux/#installation-via-tarball
    # (you can use `apt search MYKEYWORD` to search for available packages, and `apt policy MYPACKAGENAME` to see available versions, as needed)
    echo "Installing Swift dependencies..."
    if (($OS_VERSION_MAJOR <= 16)) ; then
      # not sure if this first group is still needed?
      sudo $APT install clang  libicu-dev  #libpython2.7-dev
      
      sudo $APT install binutils  git  libc6-dev  libcurl3  libedit2  libgcc-5-dev  libpython2.7  libsqlite3-0  libstdc++-5-dev  libxml2  pkg-config  tzdata  zlib1g-dev
    elif (($OS_VERSION_MAJOR == 18)) ; then
      sudo $APT install binutils  git  libc6-dev  libcurl4  libedit2  libgcc-5-dev  libpython2.7  libsqlite3-0  libstdc++-5-dev  libxml2  pkg-config  tzdata  zlib1g-dev
    elif (($OS_VERSION_MAJOR == 20)) ; then
      sudo $APT install binutils  git  gnupg2  libc6-dev  libcurl4  libedit2  libgcc-9-dev  libpython2.7  libsqlite3-0  libstdc++-9-dev  libxml2  libz3-dev  pkg-config  tzdata  uuid-dev  zlib1g-dev
    elif (($OS_VERSION_MAJOR >= 22)) ; then
      sudo $APT install binutils  git  gnupg2  libc6-dev  libcurl4-openssl-dev  libedit2  libgcc-9-dev  libpython3.8  libsqlite3-0  libstdc++-9-dev  libxml2-dev  libz3-dev  pkg-config  tzdata  unzip  zlib1g-dev
    fi

    echo "Installing Swift..."
    if [ ! -d /vagrant/swift ] ; then
      mkdir /vagrant/swift
    fi
    if [ -d /vagrant/swift/$SWIFT_RELEASE-$SWIFT_PLATFORM ] ; then
      echo "Swift installation found at /vagrant/swift/$SWIFT_RELEASE-$SWIFT_PLATFORM; skipping download..."
    else
     # download the archive and signature files
     echo "Downloading $SWIFT_URL..."
      curl --fail --silent --show-error -L $SWIFT_URL > "/vagrant/swift/$SWIFT_ARCHIVE"
      CURL_ERROR=$?
      curl --fail --silent --show-error -L "$SWIFT_URL.sig" > "/vagrant/swift/$SWIFT_ARCHIVE.sig"
      CURL_ERROR=$(($CURL_ERROR+$?))
      if [ $CURL_ERROR -eq 0 ] ; then
        echo "Swift archive downloaded..."
      else
        echo "ERROR: Swift archive $SWIFT_ARCHIVE couldn't be downloaded from:"
        echo "$SWIFT_URL"
        echo "Double-check that this platform version + Swift version are listed here: https://swift.org/download/"
        rm -f "/vagrant/swift/$SWIFT_ARCHIVE" "/vagrant/swift/$SWIFT_ARCHIVE.sig"
        exit 1
      fi

      # import the Swift PGP keys (see: https://www.swift.org/install/linux/#installation-via-tarball)
      wget -q -O - https://swift.org/keys/all-keys.asc | gpg --import -

      # ...and verify the archive:
      gpg --keyserver hkp://keyserver.ubuntu.com --refresh-keys Swift
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
    fi

    # add our swift dir to $PATH
    add_path /vagrant/swift/$SWIFT_RELEASE-$SWIFT_PLATFORM/usr/bin
    SWIFT_LIB_DIR=/vagrant/swift/$SWIFT_RELEASE-$SWIFT_PLATFORM/usr/lib
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

INSTALL_SWIFTLINT=true
if [ "$INSTALL_SWIFTLINT" = true ] ; then
  echo "Installing SwiftLint..."

  # TODO: SwiftLint builds are failing currently; using homebrew for now: https://github.com/brookinc/swift-linux-vagrant/issues/4
  HOMEBREW_SWIFTLINT=true
  if [ "$HOMEBREW_SWIFTLINT" = true ] ; then
    install_homebrew
    runuser -u vagrant -- brew install -q swiftlint

    # manually copy library dependencies to expected destinations
    # (see: https://github.com/jpsim/SourceKitten/issues/792#issuecomment-1747421935
    # and https://github.com/realm/SwiftLint/blob/main/Dockerfile)
    cp $SWIFT_LIB_DIR/libsourcekitdInProc.so /usr/lib
    cp $SWIFT_LIB_DIR/swift/host/libSwift*.so /usr/lib
    cp $SWIFT_LIB_DIR/swift/linux/libBlocksRuntime.so /usr/lib
    cp $SWIFT_LIB_DIR/swift/linux/libdispatch.so /usr/lib
    cp $SWIFT_LIB_DIR/swift/linux/libswift*.so /usr/lib
  else
    # otherwise, build swiftlint from source
    # for dependency details, see: https://github.com/realm/SwiftLint/issues/732#issuecomment-339502688
    sudo $APT install clang
    sudo $APT install libblocksruntime0
    sudo $APT install libcurl4-openssl-dev

    set_env_variable LINUX_SOURCEKIT_LIB_PATH "/vagrant/swift/$SWIFT_RELEASE-$SWIFT_PLATFORM/usr/lib"

    if [ -e /vagrant/swift/swiftlint/swiftlint ] ; then
      echo "Swiftlint installation found at /vagrant/swift/swiftlint/swiftlint; skipping download..."
    else
      git clone https://github.com/realm/SwiftLint.git ~vagrant/swiftlinttemp
      pushd ~vagrant/swiftlinttemp
      echo "Buidling SwiftLint..."
      swift build -c release --static-swift-stdlib
      if [ $? -eq 0 ] ; then
        echo "SwiftLint built successfully!"
        if [ ! -d /vagrant/swift/swiftlint ] ; then
          mkdir /vagrant/swift/swiftlint
        fi
        mv .build/x86_64-unknown-linux/release/swiftlint /vagrant/swift/swiftlint
        popd
        rm -rf ~vagrant/swiftlinttemp
      else
        echo "ERROR: SwiftLint build failed."
      fi
    fi

    # add swiftlint dir to $PATH
    add_path /vagrant/swift/swiftlint
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
    echo "# https://realm.github.io/SwiftLint/rule-directory.html" >> .swiftlint.yml
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

  # finally, do a test run
  swiftlint version && swiftlint /vagrant/test.swift
else
  echo "Skipping SwiftLint install..."
fi

# Clean up again now that we're done installing
sudo $APT autoremove
sudo $APT clean
echo "Setup complete."
