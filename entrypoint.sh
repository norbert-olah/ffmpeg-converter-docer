#!/bin/bash

# Create user group if it doesn't exist
if ! getent group users > /dev/null 2>&1; then
    addgroup -g ${PGID} users
fi

# Create user if it doesn't exist
if ! id -u ${SSH_USER} > /dev/null 2>&1; then
    adduser -D -u ${PUID} -G users -s /bin/bash ${SSH_USER}
fi

# Set user password
echo "${SSH_USER}:${SSH_PASSWORD}" | chpasswd

# Set Samba password
(echo "${SSH_PASSWORD}"; echo "${SSH_PASSWORD}") | smbpasswd -a -s ${SSH_USER}
smbpasswd -e ${SSH_USER}

# Set ownership of shared folders
chown -R ${SSH_USER}:users /shares/ConverterInput
chown -R ${SSH_USER}:users /shares/ConverterOutput
chmod -R 775 /shares/ConverterInput
chmod -R 775 /shares/ConverterOutput

# Update Samba config with actual username
sed -i "s/force user = \$SSH_USER/force user = ${SSH_USER}/" /etc/samba/smb.conf

# Start Samba services
smbd --foreground --no-process-group &
nmbd --foreground --no-process-group &

# Start SSH service in foreground
echo "Starting SSH server..."
echo "SSH User: ${SSH_USER}"
echo "SSH Port: 22"
echo "SMB Shares: \\\\container\\ConverterInput, \\\\container\\ConverterOutput"
echo "Input folder: /shares/ConverterInput"
echo "Output folder: /shares/ConverterOutput"

/usr/sbin/sshd -D
