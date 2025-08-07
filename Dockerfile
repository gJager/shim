FROM ubuntu:latest

# Install neovim
RUN apt-get update
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:neovim-ppa/unstable
RUN apt-get update
RUN apt-get install -y neovim

# Install ssh
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /run/sshd

# Install pip
RUN apt-get install -y python3-pip
RUN pip3 install py-posh neovim-remote --break-system-packages

# Create user in container
RUN userdel ubuntu
RUN useradd -s /usr/bin/bash -m vim

# Install sshfs
RUN apt-get update && apt-get install -y sshfs git

# Add resources
ADD shim-start.sh /shim/shim-start.sh
ADD ssh-bash /shim/ssh-bash
RUN chmod +x /shim/ssh-bash
ADD open_files.py /shim/open_files.py
ADD shim-open.sh /shim/shim-open.sh

# VIM setup
RUN git clone --recurse-submodule https://github.com/gJager/nvim.git /shim/nvim-config
RUN chown -R vim:vim /shim/nvim-config
RUN pip3 install basedpyright --break-system-packages
RUN apt-get install ripgrep fzf

CMD /usr/bin/bash /shim/shim-start.sh

