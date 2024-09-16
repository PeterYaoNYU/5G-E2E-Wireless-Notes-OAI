wget https://github.com/L4STeam/linux/releases/download/testing-build/l4s-testing.zip
sudo apt install unzip
unzip l4s-testing.zip

sudo dpkg --install debian_build/*
sudo update-grub
sudo reboot

hostname; uname -as