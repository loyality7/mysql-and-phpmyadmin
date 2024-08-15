#!/bin/bash

set -e

# Update system packages
echo "Updating system packages..."
sudo apt-get update

# Install MySQL Server
echo "Installing MySQL Server..."
sudo apt-get install -y mysql-server

# Configure MySQL to listen on all IP addresses
echo "Configuring MySQL to listen on all IP addresses..."
sudo sed -i "s/^bind-address\s*=.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Restart MySQL to apply changes
echo "Restarting MySQL to apply changes..."
sudo systemctl restart mysql

# Secure MySQL installation (non-interactive)
echo "Securing MySQL installation..."
sudo mysql_secure_installation <<EOF

y
n
y
y
y
EOF

# Generate a random password for the new MySQL user
USER="newuser"
PASSWORD=$(openssl rand -base64 12)

echo "Creating MySQL user and granting all privileges..."
# Create MySQL user with a random password
sudo mysql -e "CREATE USER '${USER}'@'%' IDENTIFIED BY '${PASSWORD}';"

# Grant all privileges on all databases
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '${USER}'@'%' WITH GRANT OPTION;"

# Flush privileges to ensure the changes take effect
sudo mysql -e "FLUSH PRIVILEGES;"

# Print the username and password
echo "MySQL User: ${USER}"
echo "MySQL Password: ${PASSWORD}"

# Install phpMyAdmin
echo "Installing phpMyAdmin and required PHP extensions..."
sudo apt-get install -y phpmyadmin php-mbstring php-zip libapache2-mod-php php-gd php-json php-curl

# Enable PHP extensions
echo "Enabling PHP extensions..."
sudo phpenmod mbstring

# Configure phpMyAdmin with Apache
echo "Configuring phpMyAdmin with Apache..."
if [ -f /etc/phpmyadmin/apache.conf ]; then
    sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-enabled/phpmyadmin.conf
else
    echo "phpMyAdmin Apache configuration file not found. Please check your installation."
    exit 1
fi

# Restart Apache
echo "Restarting Apache..."
sudo systemctl restart apache2

# Configure firewall to allow access (if UFW is used)
echo "Configuring firewall..."
if sudo ufw status | grep -q 'Status: active'; then
    sudo ufw allow 3306/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
else
    echo "UFW is not active. Please check your firewall settings."
fi

# Final message
echo "phpMyAdmin installed. Access it via http://IP/phpmyadmin"

echo "MySQL User: ${USER}"
echo "MySQL Password: ${PASSWORD}"
