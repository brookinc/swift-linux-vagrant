# swift-linux-vagrant
A Vagrant configuration that downloads and installs Swift for Linux in one easy step (\*) .

<sup><sub>(\* or three easy steps, if you include installing Vagrant and VirtualBox. 😁)</sub></sup>

## What Is It?
It's an easy (albeit no-frills) way to compile and run [Swift](https://swift.org/documentation/) code on any Mac, Windows, or Linux machine, by creating a Linux virtual machine on your computer, and then installing Swift for Linux on that virtual machine.

(In a similar vein, I also recommend checking out the [IBM Swift Sandbox](https://swift.sandbox.bluemix.net/), which lets you type and run Swift code straight from your web browser. 💻😎)

## What Do I Need To Use It?
It should work on most modern Mac, Windows, and Linux machines.

A good network connection is necessary during initial setup, as the installation can involve a gigabyte or two of downloading. Once the installation is complete, however, no internet connection is required for further usage.

You'll also need around 4GB of free hard drive space.

If you encounter any problems installing or running, feel free to submit an issue or (even better) a pull request. 😉

## How Do I Use It?
- [Vagrant](https://www.vagrantup.com/downloads.html) and [VirtualBox](https://www.virtualbox.org/wiki/Downloads) enable you to create and run virtual machines on your computer. If you haven't used them before, you'll need to download and install those two programs first. (Like Swift itself, both are free and open-source.)
- Once that's done, sync this repository to your machine, then navigate to the corresponding local directory in the terminal.
- Run `vagrant up` and wait a few minutes for the setup process to complete.
- Use `vagrant ssh` to log in to your newly-provisioned virtual machine.
- Within the virtual machine, your repo directory is accessible as `/vagrant`, so change to that directory by entering `cd /vagrant`.
- Enter `swift test.swift` to run the included test file. Hooray! You're running Swift code on Linux! 🎉

## Playing Around
- As noted above, you can use `swift` plus the name of a Swift file to run that file and display any output. (Why not start off by creating a new `test2.swift` file in your repo directory, then seeing if you can run it the same way you ran `test.swift` above?)
- You can also use `swift` by itself (from any directory) to enter the [Swift REPL environment](https://swift.org/getting-started/#using-the-repl), where you can type Swift code and see the results immediately.
- Lastly, you can use Swift's [package manager system](https://swift.org/getting-started/#using-the-package-manager) to actually compile your Swift code into a command-line executable.

## Exiting
- You can quit the Swift REPL with `:quit`.
- After that, you can log out of your virtual machine with `exit`.
- To shut down your virtual machine, you can use `vagrant suspend` (which saves the contents of the VM's memory to disk first) or `vagrant halt` (which simply shuts the VM down). Either is typically fine.
- To get rid of your virtual machine altogether (ie. to free up hard drive space) see the *"Uninstalling"* section below.

## Customizing
- As-is, these files will install the latest release of Swift on Ubuntu 16.04, but you can easily change to a [different supported](https://swift.org/download/) Swift or Ubuntu version:
  * If you want to install a different version of Swift, change the `SWIFT_VERSION` variable in `Vagrantboot.sh`.
  * If you want to use a different version of Ubuntu, change the `config.vm.box` entry in `Vagrantfile`.

## Uninstalling
- To get rid of your virtual machine, you can run `vagrant destroy` from the repo directory.
  * This will delete the virtual machine that was created (under `"~/VirtualBox VMs/"`), however the files in your repo directory will remain untouched.
  * To free up additional space, you can delete the `swift` subdirectory that was created inside your repo directory. It contains the Swift binaries that were downloaded by the script. (They'll be re-downloaded the next time you run `vagrant up`.)
- Vagrant also keeps copies of the operating system image files it downloads in `~/.vagrant.d/boxes/` -- you can wipe this directory whenever needed; the newest image file will simply be re-downloaded the next time it's required.
- Vagrant and VirtualBox can be completely uninstalled by following their respective uninstall instructions:
  * [Uninstalling Vagrant](https://www.vagrantup.com/docs/installation/uninstallation.html)
  * [Uninstalling VirtualBox](https://www.virtualbox.org/manual/ch02.html)

## Further Reading
- [The Swift Programming Language](https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/index.html) ([epub version](https://swift.org/documentation/TheSwiftProgrammingLanguage%28Swift4%29.epub))
- [Swift Standard Library documentation](https://developer.apple.com/documentation/swift)
- Apple's [Swift Playgrounds](https://itunes.apple.com/ca/app/swift-playgrounds/id908519492?mt=8) iPad app
- Apple's [Swift tutorials and resources](https://developer.apple.com/swift/resources/)
- [Swift REPL guide](https://swift.org/getting-started/#using-the-repl) and [Debugging with LLDB](https://swift.org/getting-started/#using-the-lldb-debugger)
- [IBM Swift Sandbox](https://swift.sandbox.bluemix.net/)
- [Swift Algorithm Club](https://github.com/raywenderlich/swift-algorithm-club/blob/master/README.markdown) and [Design Patterns In Swift](https://github.com/ochococo/Design-Patterns-In-Swift)
- The [awesome-swift](https://github.com/matteocrippa/awesome-swift) resource guide
- [Vagrant documentation](https://www.vagrantup.com/docs/)
- [VirtualBox documentation](https://www.virtualbox.org/wiki/Documentation)
- [Ubuntu documentation](https://help.ubuntu.com)
