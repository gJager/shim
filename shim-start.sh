#!/usr/bin/bash
echo "Starting shim container"

echo "Setting env vars"
if [ -z "$REMOTE_SHELL" ]; then
    echo "REMOTE_SHELL=bash" >> /etc/environment
else
    echo "REMOTE_SHELL=$REMOTE_SHELL" >> /etc/environment
fi

echo "SSHUSER=$SSHUSER" >> /etc/environment
echo "SSHHOST=$SSHHOST" >> /etc/environment

echo "MOUNT_ROOT=$MOUNT_ROOT" >> /etc/environment

# Try to adjust uid/gid
echo "Getting uid/gid"
REMOTE_ID=`ssh -i /shim/sshorig/id_rsa -q -o "StrictHostKeyChecking no" $SSHUSER@$SSHHOST id -u`
REMOTE_GID=`ssh -i /shim/sshorig/id_rsa -q -o "StrictHostKeyChecking no" $SSHUSER@$SSHHOST id -g`

echo "Adjusting uid/gid"
if [[ "$REMOTE_ID" != 1000 ]]; then
    echo "Changing uid from 1000 to $REMOTE_ID"
    usermod -u $REMOTE_ID vim; 
    if [ $? -ne 0 ]; then
        echo "User id is not available in the container. I gotta quit."
        exit 1
    fi
fi
if [[ "$REMOTE_GID" != 1000 ]]; then
    echo "Changing gid from 1000 to $REMOTE_GID"
    groupmod -g $REMOTE_GID vim
    if [ $? -ne 0 ]; then
        echo "Group id is already being used in the container. I'll add the group to the user, and hopefully you dont notice"
        usermod -a -G $REMOTE_GID vim
    fi
fi

# Root can use the mounted ssh keys, but incase the uid is different for the user, we should make a copy
echo "Copying ssh info"
cp -r /shim/sshorig /shim/sshuser
chown -R vim:vim /shim/sshuser


# Mount the host's dir in the container. We try to use MOUNT_ROOT because having different 
# root paths can cause issues for things like clangd
echo "Trying to mount share"
mkdir -p $MOUNT_ROOT
chown vim:vim $MOUNT_ROOT
su -c "sshfs $SSHUSER@$SSHHOST:$MOUNT_ROOT $MOUNT_ROOT -o IdentityFile=/shim/sshuser/id_rsa,StrictHostKeyChecking=no" vim
#echo "HOME=/home/vim/mount" >> /etc/environment


# Start ssh in container
echo "AuthorizedKeysFile /shim/sshuser/authorized_keys" >> /etc/ssh/sshd_config
/usr/sbin/sshd
REMOTE_ID_PUB=`ssh -i /shim/sshorig/id_rsa -q -o "StrictHostKeyChecking no" $SSHUSER@$SSHHOST cat '$HOME/.ssh/id_rsa.pub'`
echo $REMOTE_ID_PUB >> /shim/sshuser/authorized_keys

# Create pipe to this container
# TODO make each session have a port/session in tmp
ssh -fNT -R 6678:localhost:22 -i /shim/sshuser/id_rsa -o "StrictHostKeyChecking no" $SSHUSER@$SSHHOST
ssh -i /shim/sshuser/id_rsa -o "StrictHostKeyChecking no" $SSHUSER@$SSHHOST mkdir -p /tmp/shim/session
scp -i /shim/sshuser/id_rsa -o "StrictHostKeyChecking no" /shim/shim-open.sh $SSHUSER@$SSHHOST:/tmp/shim/session/vim
scp -i /shim/sshuser/id_rsa -o "StrictHostKeyChecking no" /shim/shim-open.sh $SSHUSER@$SSHHOST:/tmp/shim/session/shim
scp -i /shim/sshuser/id_rsa -o "StrictHostKeyChecking no" /shim/shim-open.sh $SSHUSER@$SSHHOST:/tmp/shim/session/nvr
scp -i /shim/sshuser/id_rsa -o "StrictHostKeyChecking no" /shim/shim-open.sh $SSHUSER@$SSHHOST:/tmp/shim/session/nvim

#
#ssh -i /shim/sshuser/id_rsa -o "StrictHostKeyChecking no" $SSHUSER@$SSHHOST mkdir -p /tmp/shim/session
#ssh -i /shim/sshuser/id_rsa -o "StrictHostKeyChecking no" $SSHUSER@$SSHHOST "echo 'ssh -p 6678 vim@localhost \`realpath \$1\`' > /tmp/shim/session/shim"
#ssh -i /shim/sshuser/id_rsa -o "StrictHostKeyChecking no" $SSHUSER@$SSHHOST chmod +x /tmp/shim/session/shim
#ssh -i /shim/sshuser/id_rsa -o "StrictHostKeyChecking no" $SSHUSER@$SSHHOST "echo 'export PATH=$PATH:/tmp/shim/session' > /tmp/shim/session/sourceme"


# start vim command
vim_cmd=$vim_cmd"SHELL=/shim/ssh-bash" # Make :term open a shell on host via script
vim_cmd=$vim_cmd" nvim"
vim_cmd=$vim_cmd" --cmd 'cd $MOUNT_ROOT'" # Start vim without ui
vim_cmd=$vim_cmd" --headless" # Start vim without ui
vim_cmd=$vim_cmd" --listen /tmp/nvimsocket" # Setup socket for us to tell vim to open files
vim_cmd=$vim_cmd" -u /shim/nvim-config/lua/init.lua" # Setup socket for us to tell vim to open files

# Start vim as user vim
if [ -z $NOVIM ]; then
    echo "Starting neovim"
    su -P -s /usr/bin/bash -c "$vim_cmd" vim
else
    echo "not starting vim"
    bash
fi


