## Project Bitscout
Home page: https://bitscout-forensics.info

Bitscout is a customizable live OS constructor tool written entirely in Bash. It's main purpose is to help you quickly create your own remote forensics bootable disk image.

This project was created by security researchers to be able to do remote system triage, malware threat hunting, digital forensics, incident response, and more. Do not expect a common user graphical interface, and if you are not familiar with the Linux command line, it's a wise idea to learn that first. This constructor can be customized to include your tools, however one of the core ideas was to remotely assist Law Enforcement investigations as well as incident responders, which is why Bitscout by default includes a number of forensic and malware analysis tools and is focused on protecting the disk drives from accidental or intentional modifications.

We recommend exploring the project home page first. However, if you are ready to start on your own, below is a little guidance to help you.

### Basic usage:

1. Build new ISO file:
   ```
   $ ./automake.sh
   ```
After running this command, you may need to answer some questions such as location of your VPN server, type of build, etc.

Hint: if you are not running Linux and still want to try Bitscout, you can start Ubuntu from LiveCD and build an image there. It's better to attach an external storage in this case to make sure you don't run out of memory. But previously, we managed you to build Bitscout even with 2GB of RAM. To download Ubuntu LiveCD, please go here:
https://www.ubuntu.com/download/desktop
Alternatively, you may try one of our pre-built images (only for demo, not production):
https://bitscout-forensics.info/quick-try/prebuilt-images

Bitscout build demo, as well as setup of other components, can be seen here:
https://bitscout-forensics.info/docs/basic-usage
Alternatively, here is some older video on Youtube that shows building Bitscout right from an Ubuntu LiveCD:
https://www.youtube.com/watch?v=knA0NS9tWsY

Note: the automake.sh script runs some commands as root, such as mounting local cache directories and creating new root filesystem permissions. However, all changes shall affect only current directory and subdirectories, unless your system is missing some essential packages to build the ISO (in this case they will be installed).

2. Test new ISO file:  
	```
	$ ./autotest.sh
	```
This command shall run tests against the freshly built ISO file. It verifies components' presence on the ISO and attempts to boot the ISO file using qemu to verify that all essential services are running.

To better understand what Bitscout is, we suggest you read further description of users' roles in the process and the FAQ below.

### User roles:
Bitscout relies on at least three components in the process of remote forensics:
1. **The owner**  
The owner is a user who has physical access to the target system and owns it. The owner's role is to download, verify and burn the ISO image file to a removable storage (CD-Rom or USB). After that the target system must be started from this bootable media. In case of LAN DHCP network configuration everything shall work automatically. In case of other setup, the owner has to configure network access using a simple management interface that is brought up on the physical console once Bitscout is loaded.

2. **The expert**  
The expert is a remote user who connects to the target system over SSH using VPN link via the expert's server. Bitscout attempts to find existing VPN configuration and SSH keys in ./config directory. If it doesn't exist it will get the default config and generate new VPN certificates and SSH keys during the build.

Hint: let Bitscout generate new keys for you and populate ./config directory, which you can customize later and rebuild the ISO by running [automake.sh](https://github.com/KasperskyLab/bitscout/blob/master/automake.sh) again.

3. **Expert's server**  
The expert's server shall be accessible from the network of the target system. It shall run an instance of VPN software (i.e. OpenVPN or Wireguard), possibly a Syslog server for remote command logging, and IRC chat server for communication. Suggested server configuration files can be found in the ./exports directory after a successful build of ISO file.

### Bitscout Features:
1. Transparency  
  a. You build your own live disk instead of using someone else's. The build process is rather straightforward and detailed. One of the core principles of Bitscout is to not use proprietary binary executables during the build process.  
  b. You may choose what packages you put on Bitscout ISO. This lets you decide which binaries you trust.  
  c. The owner can monitor what is going on in an expert's container live or via a recorded session, which can be replayed. This is useful for training or understanding of the forensic process in the court.  

2. Forensics  
  a. Bitscout is designed to not modify hard drive data or other storage media attached to the system. This is essential for forensic analysis.  
  b. Bitscout contains most popular tools to acquire and analyze storage drives.  
  c. The owner of the system controls which disk devices are accessible to the expert in read-only (or read-write) mode.  
  d. Even running as root the expert cannot modify or reset access to the provided storage devices, which prevents potential data loss from the source disk. This is achieved via layers of virtualization.  

3. Customization  
  a. The set of tools available on Bitscout can be customized by editing respective scripts before running the build. You can add standard packages or your own tools. Make it available to experts, system owners or both.  
  b. Both system owner and expert can install additional software packages on an already running (booted) system. All changes will be done independently (experts cannot change the owner's environment). All installed software exists only in RAM and will be gone when the system is restarted. This doesn't apply to Bitscout with persistence feature.  
  c. If certain operations require more memory or a large disk which is not available on the system, the owner may attach a writable external storage device (such as fast USB flash memory) to be used for storage or swap by the expert.  

4. Compact  
  a. Bitscout project is designed to be a minimal yet universal tool to access remote systems. It contains a minimal set of packages, libraries and tools to start the system and provide most common forensic tools to the expert  immediately. Certain optimizations are yet to be added to reduce size even further. If you have a nice idea to reduce the size, please share it via the Github issues section.  
  b. The system uses no graphical interface on purpose. This reduces disk image size and RAM consumption.  
  c. The expert's runs inside an unprivileged Linux container, which saves from overhead of full virtualization. The container relies on the same kernel as the host system, but doesn't allow kernel module manipulation.  
  d. The container root filesystems are overlaid from the live CD rootfs. This enables us to reuse the system binaries and configuration and avoid data duplication. Yet, mapped with copy-on-write access it provides almost unlimited modification of the whole OS. The real limit is just the size of available memory and swap. As a matter of fact, fully running OS with a child OS inside the container used less than 200Mb of RAM in some of our tests in the past.  

### F.A.Q:

**Q: Why was the system created?**  
**A:** There are a lot of commercial and rather expensive forensic software suites out there. We tried several of the most popular of them and always bumped into functionality limitations and lack of transparency. While some suites provide scriptability, they lack remote analysis features that do not modify the evidence disk. Most forensic tools are not designed for remote analysis, lack flexibility and cost a fortune.  We found that there was a niche for a new tool which is  
  1. trusted, transparent and open source (you build your own OS!)  
  2. customizable (you put your own tools!)  
  3. stable and reliable  
  4. rich in features and compact  
  5. fast and optimized for lower RAM usage  
  6. free of charge  
  7. runs on merely any hardware  

**Q: How was the project developed?**  
**A:** The project was initially developed as a hobby project. The first variant relied on full trust to the remote user, who was provided with root access to the live system. Soon we realized that the remote system owner is willing to track the progress, communicate with the expert and be able to approve access to storage media. To increase trust level between the system's owner and the remote expert we decided to isolate the expert within a virtualized container. This assured the owner of the system that the source disk information will never be tampered (unless it is permitted by the owner in case of system remediation request).

**Q: Does the author provide a VPN server with this project?**  
**A:** No, you have to use your own server. All you need is an OpenVPN or a Wireguard instance. Both are free and open-source, and run on all platforms. For more information, see https://openvpn.net and https://www.wireguard.com.

**Q: Will the product be supported?**  
**A:** It will be supported as long as there is a need for such a tool. We will migrate to newer LTS versions of Ubuntu as it is released. This is important to upgrade forensic tools. However, you can always update an already running live system from a newer repository and install more recent versions of certain packages. In case you have a rare case of a 32-bit CPU, look into Bitscout versions, because Canonical stopped supporting 32-bit only builds some time ago.

**Q: Do I need to re-run `./automake.sh` every time I change anything, i.e. put my
own VPN certificate or SSH key?**  
**A:** No. automake.sh script is just an easy do-everything script to build a new ISO file from scratch in one run. Feel free to copy and modify it. Comment out stages that you don't want to pass again from top to bottom and run it. Make sure you run the last stage image_build.sh to rebuild the ISO file. If you didn't modify the rootfs in the chroot directory, you can also use scripts/image_build-nosquashfs-rebuild.sh to save even more time.

**Q: Is this the best forensic product to save the world?**  
**A:** It is not and was never meant to be so. It serves its task though and did help us in the past in some complicated circumstances and under time pressure. If it works for you we will be happy to hear your story. If not, perhaps you could suggest a clever patch?

**Q: Is this project used for business?**
**A:** This project was created independently of my employer's product line and outside of scope of the company's business operation. The developed tool is not limited to particular users and might be useful to researchers, high-tech crime units of Law Enforcement, and educational institutions.

Credits:  
  Kaspersky  
  INTERPOL Digital Forensics Lab  
  Individual contributors to Bitscout project  

Thanks to
  Linux kernel developers  
  Canonical Ltd  
  All those incredible authors of Linux forensics tools  

For more information, please visit our website at https://bitscout-forensics.info


