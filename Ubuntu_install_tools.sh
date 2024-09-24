#!/bin/bash
# Ubuntu 24.02
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Get the current logged-in user
USER=$(whoami)
# Add the user to the sudo group
echo "Adding user $USER to the sudo group..."
sudo usermod -aG sudo $USER

# Check if the user was added to the sudo group
if groups $USER | grep &>/dev/null '\bsudo\b'; then
    echo "$USER is now a member of the sudo group."
else
    echo "Failed to add $USER to the sudo group."
    exit 1
fi

# Verify sudo privileges
echo "Verifying sudo privileges..."
if sudo -l -U $USER | grep -q "(ALL : ALL) ALL"; then
    echo "$USER has sudo privileges."
else
    echo "$USER does not have sudo privileges."
    exit 1
fi
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Trun Off the firewall
sudo systemctl stop ufw
sudo systemctl disable ufw
sudo swapoff -a
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
# Update the package list
sudo apt-get update -y

# Install required dependencies for adding repositories
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Verify Docker installation
docker --version
if [ $? -eq 0 ]; then
  echo "Docker installed successfully."
  echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
else
  echo "Docker installation failed."
  echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  exit 1
fi

# Install Podman
echo "Installing Podman..."
. /etc/os-release
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_$VERSION_ID/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
curl -fsSL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_$VERSION_ID/Release.key | gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg
sudo apt-get update -y
sudo apt-get install -y podman

# Verify Podman installation
podman --version
if [ $? -eq 0 ]; then
  echo "Podman installed successfully."
else
  echo "Podman installation failed."
  exit 1
fi

# Install Kubectl
echo "Installing Kubectl..."
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify Kubectl installation
kubectl version --client --output=yaml
if [ $? -eq 0 ]; then
  echo "Kubectl installed successfully."
else
  echo "Kubectl installation failed."
  exit 1
fi

# Clean up
sudo rm -f kubectl

echo "All tools installed and verified."
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
USER=$(whoami)
chown $USER:$USER /var/run/docker.sock
sudo ls -al /var/run/docker.sock
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Permission on /var/run/docker.sock has been updated"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
docker --version
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
podman --version
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
kubectl version
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"