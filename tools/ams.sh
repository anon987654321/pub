#!/bin/zsh

# Enable error handling and logging
LOGFILE="/path/to/install_obsd_amsterdam.log"
exec > >(tee -i $LOGFILE) 2>&1

set -e
set -x

# Ensure elevated privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please connect to your OpenBSD.Amsterdam box using the follwing command:"
  echo "sudo zsh ams.sh"
  exit 1
fi

# Step 1: Install Xcode Command Line Tools (if not installed)
xcode-select --install || echo "Command Line Tools already installed."

# Step 2: Ensure necessary permissions for /usr/local
sudo chown -R root:admin /usr/local || echo "Permission adjustment failed, continuing."

# Step 3: Remove outdated OpenSSL if it exists
if [ -d "/usr/local/ssl" ]; then
  echo "Removing outdated OpenSSL..."
  sudo rm -rf /usr/local/ssl
  sudo rm /usr/bin/openssl
fi

# Step 4: Download and install OpenSSL manually (targeting x86_64 for macOS Yosemite)
if openssl version | grep -q "1.0.2u"; then
  echo "OpenSSL 1.0.2u is already installed."
else
  echo "Downloading and installing OpenSSL 1.0.2u..."
  curl -O https://openssl.org/source/openssl-1.0.2u.tar.gz || { echo "Failed to download OpenSSL"; exit 1; }
  tar -xzf openssl-1.0.2u.tar.gz
  cd openssl-1.0.2u

  # Configure, compile, and install OpenSSL (target x86_64 only to avoid fat binaries)
  ./Configure darwin64-x86_64-cc --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib || { echo "Failed to configure OpenSSL"; exit 1; }
  make clean
  make || { echo "Failed to build OpenSSL"; exit 1; }
  sudo make install || { echo "Failed to install OpenSSL"; exit 1; }

  # Symlink the new OpenSSL to /usr/bin
  sudo ln -sf /usr/local/ssl/bin/openssl /usr/bin/openssl

  # Verify OpenSSL installation
  openssl version || { echo "OpenSSL installation failed."; exit 1; }
  cd ..
fi

# Step 5: Download and install OpenSSH without Homebrew
if ssh -V | grep -q "OpenSSH_8.9p1"; then
  echo "OpenSSH 8.9p1 is already installed."
else
  echo "Downloading OpenSSH..."

  # Try HTTP instead of HTTPS to bypass SSL certificate issues
  curl -O http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.9p1.tar.gz || {
    echo "Failed to download OpenSSH from main mirror, trying insecure download via curl."
    curl -k -O https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.9p1.tar.gz || {
      echo "Failed to download OpenSSH after all attempts."
      exit 1
    }
  }

  tar -xzf openssh-8.9p1.tar.gz
  cd openssh-8.9p1 || { echo "Failed to extract OpenSSH"; exit 1; }

  # Configure, compile, and install OpenSSH
  echo "Configuring and installing OpenSSH..."
  ./configure --prefix=/usr/local --with-ssl-dir=/usr/local/ssl || { echo "Failed to configure OpenSSH"; exit 1; }
  make clean
  make || { echo "Failed to build OpenSSH"; exit 1; }
  sudo make install || { echo "Failed to install OpenSSH"; exit 1; }

  # Symlink OpenSSH binaries
  ln -sf /usr/local/bin/ssh /usr/bin/ssh
  ln -sf /usr/local/sbin/sshd /usr/sbin/sshd

  # Verify OpenSSH installation
  ssh -V || echo "OpenSSH installation failed."
  cd ..
fi

# Step 6: SSHFS manual installation recommended due to package issues on macOS 10.10.5
echo "Please manually install SSHFS for macOS Yosemite by downloading macFUSE from https://osxfuse.github.io."

# Step 7: Add SSH prompt to .bash_profile (default for Bash on macOS Yosemite)
if ! grep -q "SSH to openbsd.amsterdam for this session?" ~/.bash_profile; then
  cat << 'EOF' >> ~/.bash_profile
ssh_openbsd_prompt() {
  echo "SSH to openbsd.amsterdam for this session? (y/n)"
  read answer
  if [[ "$answer" = "y" ]]; then
    ssh dev@46.23.95.45
  fi
}
ssh_openbsd_prompt
EOF
  echo "SSH prompt function added to ~/.bash_profile."
else
  echo "SSH prompt function already exists in ~/.bash_profile."
fi

# Cleanup: Remove downloaded files
rm -rf openssl-1.0.2u.tar.gz openssl-1.0.2u openssh-8.9p1.tar.gz openssh-8.9p1 SSHFS-2.5.0.pkg

echo "OpenSSH installation complete. Please manually install macFUSE for SSHFS support."
