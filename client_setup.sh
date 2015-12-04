#!/bin/bash

# Add GUI
apt-get update
apt-get install xfce4 golang -y

# Install Kubectl
wget https://storage.googleapis.com/kubernetes-release/release/v1.0.6/bin/linux/amd64/kubectl
mv kubectl /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

startxfce4 &
