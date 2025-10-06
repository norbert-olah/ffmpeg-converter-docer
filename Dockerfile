# Use Alpine Linux as the minimal base
FROM alpine:latest

# Set environment variables with defaults (can be overridden at runtime)
ENV SSH_USER=converter
ENV SSH_PASSWORD=changeme
ENV PUID=1000
ENV PGID=1000

# Install required packages
RUN apk add --no-cache \
    ffmpeg \
    openssh \
    samba \
    samba-common-tools \
    bash \
    shadow \
    && rm -rf /var/cache/apk/*

# Create shared folders
RUN mkdir -p /shares/ConverterInput /shares/ConverterOutput

# Configure SSH
RUN ssh-keygen -A && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config && \
    echo "ChallengeResponseAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "KbdInteractiveAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config

# Configure Samba
RUN echo "[global]" > /etc/samba/smb.conf && \
    echo "   workgroup = WORKGROUP" >> /etc/samba/smb.conf && \
    echo "   server string = FFmpeg Converter" >> /etc/samba/smb.conf && \
    echo "   security = user" >> /etc/samba/smb.conf && \
    echo "   map to guest = Bad User" >> /etc/samba/smb.conf && \
    echo "   dns proxy = no" >> /etc/samba/smb.conf && \
    echo "   load printers = no" >> /etc/samba/smb.conf && \
    echo "   printing = bsd" >> /etc/samba/smb.conf && \
    echo "   printcap name = /dev/null" >> /etc/samba/smb.conf && \
    echo "   disable spoolss = yes" >> /etc/samba/smb.conf && \
    echo "" >> /etc/samba/smb.conf && \
    echo "[ConverterInput]" >> /etc/samba/smb.conf && \
    echo "   path = /shares/ConverterInput" >> /etc/samba/smb.conf && \
    echo "   browseable = yes" >> /etc/samba/smb.conf && \
    echo "   writable = yes" >> /etc/samba/smb.conf && \
    echo "   guest ok = no" >> /etc/samba/smb.conf && \
    echo "   valid users = @users" >> /etc/samba/smb.conf && \
    echo "   force user = $SSH_USER" >> /etc/samba/smb.conf && \
    echo "   create mask = 0664" >> /etc/samba/smb.conf && \
    echo "   directory mask = 0775" >> /etc/samba/smb.conf && \
    echo "" >> /etc/samba/smb.conf && \
    echo "[ConverterOutput]" >> /etc/samba/smb.conf && \
    echo "   path = /shares/ConverterOutput" >> /etc/samba/smb.conf && \
    echo "   browseable = yes" >> /etc/samba/smb.conf && \
    echo "   writable = yes" >> /etc/samba/smb.conf && \
    echo "   guest ok = no" >> /etc/samba/smb.conf && \
    echo "   valid users = @users" >> /etc/samba/smb.conf && \
    echo "   force user = $SSH_USER" >> /etc/samba/smb.conf && \
    echo "   create mask = 0664" >> /etc/samba/smb.conf && \
    echo "   directory mask = 0775" >> /etc/samba/smb.conf

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports
EXPOSE 22 139 445

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]
