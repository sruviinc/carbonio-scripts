#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "================================================================================"
echo "| Important Notification for Users                                              |"
echo "|------------------------------------------------------------------------------|"
echo "| As part of the installation process for Carbonio CE, steps 13 to 19 focus on |"
echo "| setting up Workstream Collaboration components. If Workstream Collaboration  |"
echo "| is not a required component for your deployment, you have the option to      |"
echo "| skip these steps (13 to 19) during the installation process.                 |"
echo "|                                                                              |"
echo "| After completing the installation process and rebooting your system, it's    |"
echo "| crucial to ensure that all services are running optimally. For users who     |"
echo "| choose to skip Workstream Collaboration components, the only additional      |"
echo "| action required is to restart the 'carbonio-tasks' service by executing:     |"
echo "|                                                                              |"
echo "|     su - zextras -c "zmcontrol restart"                                      |"
echo "|     systemctl restart carbonio-tasks                                         |"
echo "|                                                                              |"
echo "| This step ensures that all task-related functionalities are fully operational|"
echo "| and align with your system's current configuration.                          |"
echo "|                                                                              |"
echo "| Thank you for choosing Carbonio CE. For any questions or further assistance, |"
echo "| please do not hesitate to reach out to our forum.                            |"
echo "================================================================================"

sleep 5

# Your script's content goes here


# Define ANSI color codes for colored output
RED='\033[0;31m'      # Failed - Red
GREEN='\033[0;32m'    # Done - Green
YELLOW='\033[0;33m'   # Pending - Yellow
LIGHT_GRAY='\033[0;37m'  # Next - Light Gray (off-white)
NC='\033[0m'          # No Color - Reset


# Define a list of activities
activities=("Set hostname" "Configure /etc/hosts" "Set Timezone" "Add Zextras Repository" "Manage APT Repositories" "Install PostgreSQL DB" "Add PostgreSQL Role and Database" "Install Carbonio CE Packages" "Configure Carbonio CE Bootstrap" "Configure Service Discovery" "Configure Pending Setups" "Bootstrap Files and Tasks DB" "Install Carbonio Message Dispatcher DB" "Install Carbonio Message Dispatcher" "Install Carbonio Message Broker" "Install Carbonio WS Collaboration DB" "Install Carbonio WS Collaboration CE" "Install Carbonio Video Server CE" "Install Carbonio WS Collaboration UI" "Change Admin User Password" "Interactive Create Test Users" "Modify MTA for Trusted Network" "Restart Carbonio Services" "Check Carbonio CE Service Status" "Check Consul Status" "Check Carbonio CE System Unit Status" "Check Consul Service Status via HTTP API" "Reboot System Now" "Quit")

status=("Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending" "Pending")

# List of predefined hostnames
hostnames=("mail.zextras.xyz" "mail.latestserver.xyz" "mail.sampleserver.xyz" "mail.oldserver.xyz" "mail.sampleservers.xyz" "mail.corporatemailbox.xyz" "mail.enterprisemailpro.xyz" "Enter custom hostname")


display_menu() {
    echo "Available Tasks:"
    printf "%-3s | %-50s | %-10s\n" "No" "Task" "Status"
    echo "-----------------------------------------------------------------"
    local next_task_set=false
    for i in "${!activities[@]}"; do
        case "${status[$i]}" in
            "Done")
                color=$GREEN
                ;;
            "Failed")
                color=$RED
                ;;
            "Pending")
                if [ "$next_task_set" = false ]; then
                    color=$LIGHT_GRAY
                    status[$i]="Next"
                    next_task_set=true
                    # Display the "Next" task in a box
                    echo "-----------------------------------------------------------------"
                    printf "| %-3d | %-50s | ${color}%-10s${NC} |\n" $((i+1)) "${activities[$i]}" "Next"
                    echo "-----------------------------------------------------------------"
                    continue # Skip the regular print for this task
                else
                    color=$YELLOW
                fi
                ;;
            *)
                color=$NC
                ;;
        esac
        printf "%-3d | %-50s | ${color}%-10s${NC}\n" $((i+1)) "${activities[$i]}" "${status[$i]}"
    done
    echo # Add an empty line for better readability
}


# Function to set the hostname
set_hostname() {
    echo "Select a hostname from the list or enter a custom one:"
    for i in "${!hostnames[@]}"; do
        printf "%d. %s\n" $((i+1)) "${hostnames[$i]}"
    done
    
    local choice
    local new_hostname
    while true; do
        read -p "Enter your choice (1-${#hostnames[@]}): " choice
        if [[ $choice -ge 1 && $choice -le ${#hostnames[@]} ]]; then
            if [ "$choice" -eq "${#hostnames[@]}" ]; then
                echo "Enter custom hostname: "
                read new_hostname
                if [[ -n "$new_hostname" ]]; then
                    break
                else
                    echo "Invalid hostname. Please try again."
                fi
            else
                new_hostname=${hostnames[$((choice-1))]}
                break
            fi
        else
            echo "Invalid selection. Please try again."
        fi
    done
    
    if sudo hostnamectl set-hostname "$new_hostname"; then
        echo "Hostname was successfully changed to $new_hostname."
        status[0]="Done"
    else
        echo "Failed to change the hostname."
        status[0]="Failed"
    fi
}

# Function to configure /etc/hosts
set_hostname() {
    echo "Select a hostname from the list or enter a custom one:"
    for i in "${!hostnames[@]}"; do
        printf "%d. %s\n" $((i+1)) "${hostnames[$i]}"
    done
    
    local choice
    local new_hostname
    while true; do
        read -p "Enter your choice (1-${#hostnames[@]}): " choice
        if [[ $choice -ge 1 && $choice -le ${#hostnames[@]} ]]; then
            if [ "$choice" -eq "${#hostnames[@]}" ]; then
                echo "Enter custom hostname: "
                read new_hostname
                if [[ -n "$new_hostname" ]]; then
                    break
                else
                    echo "Invalid hostname. Please try again."
                fi
            else
                new_hostname=${hostnames[$((choice-1))]}
                break
            fi
        else
            echo "Invalid selection. Please try again."
        fi
    done
    
    if sudo hostnamectl set-hostname "$new_hostname"; then
        echo "Hostname was successfully changed to $new_hostname."
        status[0]="Done"
    else
        echo "Failed to change the hostname."
        status[0]="Failed"
    fi
}

# Function to configure /etc/hosts
configure_hosts() {
    echo "Configuring /etc/hosts..."

    # Check and add localhost if not present
	> /etc/hosts
	echo "127.0.0.1 localhost" >> /etc/hosts

    # Determine if the interface IP is public or private
    echo "Determining if the interface IP is public or private..."
    interface_ip=$(ip addr show | awk '/inet / && $2 !~ /^127\./ {print $2}' | cut -d '/' -f 1)
    if [[ $interface_ip =~ ^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\.|^192\.168\. ]]; then
        echo -en '\n'
        sleep 2
        echo ip_type="Private"
        echo -en '\n'
    else
        echo -en '\n'
        sleep 2
        echo ip_type="Public"
        echo -en '\n'
    fi
	
	# Prompt for user choice
	echo "Choose an option:"
	echo "1. Add Interface IP"
	echo "2. Add Public IP Resolved by DNS"
	read -p "Enter your choice: " choice

	case $choice in
		1)
			echo "$interface_ip $(hostname -f) $(hostname -s)" >> /etc/hosts
			echo "Interface IP added to /etc/hosts. IP type: $ip_type"
			;;
		2)
			read -p "Enter the public hostname: " public_hostname
			echo "$(hostname -i) $(hostname -f) $(hostname -s)" >> /etc/hosts
			echo "Public hostname added to /etc/hosts."
			;;
		*)
			echo "Invalid choice. Exiting."
			return 1
			;;
	esac

    echo "/etc/hosts has been updated as follows:"
	echo -en '\n'
	cat /etc/hosts
	echo -en '\n'
    status[1]="Done"
}

# Function to set the timezone
set_timezone() {
    # Retrieve and display available timezones
    echo "Available Timezones:"
    timedatectl list-timezones
    
    # Prompt the user for their preferred timezone
    echo "Enter your preferred timezone (e.g., Asia/Dhaka):"
    while read user_timezone; do
        # Check if the entered timezone is valid by looking for it in the list of timezones
        if timedatectl list-timezones | grep -qx "$user_timezone"; then
            # If valid, set the timezone
            echo "Setting timezone to $user_timezone..."
            if sudo timedatectl set-timezone "$user_timezone"; then
                echo "Timezone has been set to $user_timezone."
                status[2]="Done"
                break
            else
                echo "Failed to set the timezone to $user_timezone."
                status[2]="Failed"
                break
            fi
        else
            # If the entered timezone is not valid, prompt the user again
            echo "Invalid timezone: $user_timezone. Please enter a valid timezone:"
        fi
    done
}

# Function to add Zextras repository
add_zextras_repo() {
    # Check and remove the zextras.list file if it exists
    if [ -f "/etc/apt/sources.list.d/zextras.list" ]; then
        echo "Existing Zextras repository configuration found. Removing..."
        sudo rm "/etc/apt/sources.list.d/zextras.list"
    fi

    echo "Select the type of Zextras repository to add:"
    echo "1. Public"
    read repo_choice
    
    # Detect OS Version
    . /etc/os-release
    OS_VERSION=$VERSION_CODENAME

    case $repo_choice in
        1)
            echo "Adding Public Zextras repository..."
            if [[ "$OS_VERSION" == "focal" ]]; then
                wget -c  https://repo.zextras.io/inst_repo_ubuntu.sh && bash inst_repo_ubuntu.sh
                echo "Public Zextras repository added for Ubuntu 20.04LTS (Focal)."
            elif [[ "$OS_VERSION" == "jammy" ]]; then
                wget -c  https://repo.zextras.io/inst_repo_ubuntu.sh && bash inst_repo_ubuntu.sh
                echo "Public Zextras repository added for Ubuntu 22.04LTS (Jemmy)."
            else
                echo "Warning: Unsupported Ubuntu version ($OS_VERSION) for the Public repository."
            fi
            ;;
       
    esac
    status[3]="Done"
}

# Function to clean, update, and upgrade APT repositories
manage_apt_repos() {
    echo "Cleaning APT repositories..."
    if sudo apt clean all; then
        echo "APT repositories cleaned successfully."
    else
        echo "Failed to clean APT repositories."
        status[4]="Failed"
        return
    fi

    echo "Updating APT repositories..."
    if sudo apt update; then
        echo "APT repositories updated successfully."
    else
        echo "Failed to update APT repositories."
        status[4]="Failed"
        return
    fi

    echo "Upgrading APT packages..."
    if sudo apt upgrade -y; then
        echo "APT packages upgraded successfully."
        status[4]="Done"
    else
        echo "Failed to upgrade APT packages."
        status[4]="Failed"
        return
    fi

    echo "APT repositories have been managed."
}

# Function to install PostgreSQL DB
install_postgresql_db() {
    echo "Select the PostgreSQL version to install:"
    echo "12. postgresql-12"
    echo "16. postgreSQL-16"
    read pgsql_version_choice

    case $pgsql_version_choice in
        12|16)
            local pgsql_version="postgresql-${pgsql_version_choice}"
            echo "Installing ${pgsql_version}..."
            sudo sh -c "echo 'deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
            if wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -; then
                echo "PostgreSQL repository key added successfully."
            else
                echo "Failed to add PostgreSQL repository key."
                status[5]="Failed"
                return
            fi

            if sudo apt update; then
                echo "Package lists updated successfully."
            else
                echo "Failed to update package lists."
                status[5]="Failed"
                return
            fi

            if sudo apt -y install "${pgsql_version}"; then
                echo "${pgsql_version} installed successfully."
                if [[ "$pgsql_version_choice" -eq 16 ]]; then
                    sudo sed -i 's/scram-sha-256/md5/' "/etc/postgresql/${pgsql_version_choice}/main/pg_hba.conf"
                    echo "Authentication method changed to MD5 for PostgreSQL ${pgsql_version_choice}."
                fi
                status[5]="Done"
            else
                echo "Failed to install ${pgsql_version}."
                status[5]="Failed"
                return
            fi
            ;;
        *)
            echo "Invalid selection. Returning to main menu."
            status[5]="Failed"
            ;;
    esac
}

# Function to add or update PostgreSQL role and database
add_postgresql_role_and_db() {
    echo "Adding PostgreSQL role and database..."
    read -s -p "Password for carbonio_adm role: " DB_ADM_PWD
    echo # Move to a new line for cleaner output

    # Creating the PostgreSQL role
    if sudo su - postgres -c "psql --command=\"CREATE ROLE carbonio_adm WITH LOGIN SUPERUSER ENCRYPTED PASSWORD '${DB_ADM_PWD}';\""; then
        echo "PostgreSQL role 'carbonio_adm' created successfully."
    else
        echo "Failed to create PostgreSQL role 'carbonio_adm'."
        status[6]="Failed"
        return
    fi

    # Creating the PostgreSQL database
    if sudo su - postgres -c "psql --command=\"CREATE DATABASE carbonio_adm OWNER carbonio_adm;\""; then
        echo "PostgreSQL database 'carbonio_adm' created successfully."
    else
        echo "Failed to create PostgreSQL database 'carbonio_adm'."
        status[6]="Failed"
        return
    fi

    # Restarting the PostgreSQL service
    if sudo systemctl restart postgresql; then
        echo "PostgreSQL service restarted successfully."
        status[6]="Done"
    else
        echo "Failed to restart PostgreSQL service."
        status[6]="Failed"
        return
    fi

    echo "PostgreSQL role and database added and service restarted."
}

# Function to install Carbonio CE packages
install_carbonio_ce_packages() {
    echo "Installing Carbonio CE packages..."
    
    # Define all packages in an array for easier management
    packages=(
        service-discover-server
        carbonio-directory-server
        carbonio-files-db
        carbonio-mailbox-db
        carbonio-docs-connector-db
        carbonio-tasks-db
        carbonio-proxy
        carbonio-webui
        carbonio-files-ui
        carbonio-tasks-ui
        carbonio-files-public-folder-ui
        carbonio-user-management
        carbonio-mta
        carbonio-appserver
        carbonio-storages-ce
        carbonio-files-ce
        carbonio-preview-ce
        carbonio-docs-connector-ce
        carbonio-tasks-ce
        carbonio-docs-editor
        carbonio-prometheus
    )

    # Attempt to install each package individually
    for pkg in "${packages[@]}"; do
        if ! sudo apt install "$pkg" -y; then
            echo "Failed to install $pkg. Halting installation process."
            status[7]="Failed"
            return
        fi
    done
    
    echo "All Carbonio CE packages installed successfully."

    echo "Listing installed Carbonio CE packages and their versions:"
    for pkg in "${packages[@]}"; do
        dpkg-query -W -f='${binary:Package} ${Version}\n' "$pkg"
    done | sort

    status[7]="Done"
}

# Function to configure Carbonio CE Bootstrap
configure_carbonio_ce_bootstrap() {
    echo "Configuring Carbonio CE Bootstrap..."
    if sudo carbonio-bootstrap; then
        echo "Carbonio CE Bootstrap configuration completed."
        status[8]="Done"
    else
        echo "Failed to configure Carbonio CE Bootstrap."
        status[8]="Failed"
    fi
}

# Function to configure Service Discovery
configure_service_discovery() {
    echo "About to configure Service Discovery. Do you want to proceed? (yes/no)"
    read -p "Enter your choice: " user_choice

    case $user_choice in
        [Yy]* ) 
            echo "Configuring Service Discovery..."
            if sudo service-discover setup-wizard; then
                echo "Service Discovery configuration completed."
                status[9]="Done"
            else
                echo "Failed to configure Service Discovery."
                status[9]="Failed"
            fi
            ;;
        [Nn]* )
            echo "Service Discovery configuration aborted by the user."
            status[9]="Aborted"
            ;;
        * ) 
            echo "Invalid input. Please answer yes or no."
            ;;
    esac
}

# Function to configure Pending Setups
configure_pending_setups() {
    echo "Configuring pending setups..."
    if sudo pending-setups -a; then
        echo "Pending setups configuration completed."
        status[10]="Done"
    else
        echo "Failed to configure pending setups."
        status[10]="Failed"
    fi
}

# Function to bootstrap files and tasks DB
bootstrap_files_and_tasks_db() {
    if [ -z "$DB_ADM_PWD" ]; then
        read -s -p "Enter password for carbonio_adm PostgreSQL role: " DB_ADM_PWD
        echo # Move to a new line for cleaner output
    fi

    echo "Bootstrapping Files database..."
    if PGPASSWORD=$DB_ADM_PWD carbonio-files-db-bootstrap carbonio_adm 127.0.0.1; then
        echo "Files database bootstrapped successfully."
    else
        echo "Failed to bootstrap Files database."
        status[11]="Failed"
        return
    fi

    echo "Bootstrapping Tasks database..."
    if PGPASSWORD=$DB_ADM_PWD carbonio-tasks-db-bootstrap carbonio_adm 127.0.0.1; then
        echo "Tasks database bootstrapped successfully."
        status[11]="Done"
    else
        echo "Failed to bootstrap Tasks database."
        status[11]="Failed"
        return
    fi
}

# Function to ask about skipping Workstream Collaboration components
ask_skip_ws_collaboration() {
    echo -en '\n'
    sleep 2
    echo "Do you want to skip Workstream Collaboration setup? (yes/no):"
    read skip_ws_collaboration
    if [[ "$skip_ws_collaboration" =~ ^[Yy][Ee][Ss]$ ]]; then
        for i in {12..18}; do
            status[$i]="Skipped"
        done
        echo "Workstream Collaboration setup will be skipped."
    else
        echo "Proceeding with Workstream Collaboration setup."
    fi
}


# Function to configure Pending Setups
install_carbonio_message_dispatcher_db() {


    if [ -z "$DB_ADM_PWD" ]; then
        read -s -p "Enter password for carbonio_adm PostgreSQL role: " DB_ADM_PWD
        echo # Move to a new line for better readability
    fi

    echo "Installing Carbonio Message Dispatcher DB..."
    if ! sudo apt install carbonio-message-dispatcher-db -y; then
        echo "Failed to install Carbonio Message Dispatcher DB."
        status[12]="Failed"
        return
    fi
    
    echo "Running pending setups..."
    if ! sudo pending-setups -a; then
        echo "Failed to run pending setups."
        status[12]="Failed"
        return
    fi

    # Restarting PostgreSQL service
    echo "Restarting PostgreSQL service..."
    if ! sudo systemctl restart postgresql@16-main.service; then
        echo "Failed to restart PostgreSQL service."
        status[12]="Failed"
        return
    fi
    echo "PostgreSQL service restarted successfully."

    if [ -z "$DB_ADM_PWD" ]; then
        read -s -p "Enter password for carbonio_adm PostgreSQL role: " DB_ADM_PWD
        echo # Move to a new line for cleaner output
    fi

    echo "Bootstrapping Carbonio Message Dispatcher DB..."
    if ! PGPASSWORD=$DB_ADM_PWD carbonio-message-dispatcher-db-bootstrap carbonio_adm 127.0.0.1; then
        echo "Failed to bootstrap Carbonio Message Dispatcher DB."
        status[12]="Failed"
        return
    fi

    echo "Installed Carbonio Message Dispatcher DB package version:"
    dpkg-query -W -f='${binary:Package} ${Version}\n' carbonio-message-dispatcher-db | sort

    status[12]="Done"
}


# Function to Install Carbonio Message Dispatcher with Enhanced Migration Retry
install_carbonio_message_dispatcher() {


    echo "Installing Carbonio Message Dispatcher..."
    if ! apt install carbonio-message-dispatcher -y; then
        echo "Failed to install Carbonio Message Dispatcher."
        status[13]="Failed"
        return
    fi

    if ! pending-setups -a; then
        echo "Failed to complete pending setups after installing Carbonio Message Dispatcher."
        status[13]="Failed"
        return
    fi

    if [ -z "$DB_ADM_PWD" ]; then
        read -s -p "Enter password for carbonio_adm PostgreSQL role: " DB_ADM_PWD
        echo # Move to a new line for cleaner output
    fi

    # Restart service-discover and postgresql initially
    systemctl restart service-discover
    sleep 5
    systemctl restart postgresql@16-main.service
    sleep 5
    systemctl restart carbonio-message-dispatcher-db-sidecar.service
    sleep 5

    # Enhanced migration attempt with recovery step
    migration_success=false
    while ! $migration_success; do
        if PGPASSWORD=$DB_ADM_PWD carbonio-message-dispatcher-migration carbonio_adm 127.78.0.10 20000; then
            echo "Migration of Carbonio Message Dispatcher succeeded."
            migration_success=true
            status[13]="Done"
        else
            echo "Failed to run Carbonio Message Dispatcher migration. Restarting PostgreSQL and retrying..."
            # Restart PostgreSQL as a recovery step before retrying
            systemctl restart postgresql@16-main.service
            systemctl restart carbonio-message-dispatcher-db-sidecar.service
            sleep 5 # Adjust sleep time as needed for the service to fully restart
        fi
    done

    echo "Installed Carbonio Message Dispatcher package and its version:"
    dpkg-query -W -f='${binary:Package} ${Version}\n' carbonio-message-dispatcher | sort
}



# Function to Install Carbonio Message Broker
install_carbonio_message_broker() {

    echo "Installing Carbonio Message Broker..."
    if ! apt install carbonio-message-broker -y; then
        echo "Failed to install Carbonio Message Broker."
        status[14]="Failed"
        return
    fi

    if ! pending-setups -a; then
        echo "Failed to complete pending setups after installing Carbonio Message Broker."
        status[14]="Failed"
        return
    fi

    echo "Installed Carbonio Message Broker package and its version:"
    dpkg-query -W -f='${binary:Package} ${Version}\n' carbonio-message-broker | sort
    status[14]="Done"
}

# Function to Install Carbonio WS Collaboration DB
install_carbonio_ws_collaboration_db() {

    echo "Installing Carbonio WS Collaboration DB..."
    if ! apt install carbonio-ws-collaboration-db -y; then
        echo "Failed to install Carbonio WS Collaboration DB."
        status[15]="Failed"
        return
    fi

    if ! pending-setups -a; then
        echo "Failed to complete pending setups after installing Carbonio WS Collaboration DB."
        status[15]="Failed"
        return
    fi

    if ! PGPASSWORD=$DB_ADM_PWD carbonio-ws-collaboration-db-bootstrap carbonio_adm 127.0.0.1; then
        echo "Failed to bootstrap Carbonio WS Collaboration DB."
        status[15]="Failed"
        return
    fi

    echo "Installed Carbonio WS Collaboration DB package and its version:"
    dpkg-query -W -f='${binary:Package} ${Version}\n' carbonio-ws-collaboration-db | sort
    status[15]="Done"
}

# Function to Install Carbonio WS Collaboration CE
install_carbonio_ws_collaboration_ce() {

    echo "Installing Carbonio WS Collaboration CE..."
    if ! apt install carbonio-ws-collaboration-ce -y; then
        echo "Failed to install Carbonio WS Collaboration CE."
        status[16]="Failed"
        return
    fi

    if ! pending-setups -a; then
        echo "Failed to complete pending setups after installing Carbonio WS Collaboration CE."
        status[16]="Failed"
        return
    fi

    echo "Installed Carbonio WS Collaboration CE package and its version:"
    dpkg-query -W -f='${binary:Package} ${Version}\n' carbonio-ws-collaboration-ce | sort
    status[16]="Done"
}

# Function to Install Carbonio Video Server CE
install_carbonio_video_server_ce() {

    echo "Installing Carbonio Video Server CE..."
    if ! apt install carbonio-videoserver-ce -y; then
        echo "Failed to install Carbonio Video Server CE."
        status[17]="Failed"
        return
    fi

    if ! sudo pending-setups -a; then
        echo "Failed to complete pending setups after installing Carbonio Video Server CE."
        status[17]="Failed"
        return
    fi

    echo "Installed Carbonio Video Server CE package and its version:"
    dpkg-query -W -f='${binary:Package} ${Version}\n' carbonio-videoserver-ce | sort
    status[17]="Done"
}

# Function to Install Carbonio WS Collaboration UI
install_carbonio_ws_collaboration_ui() {

    echo "Installing Carbonio WS Collaboration UI..."
    if ! apt install carbonio-ws-collaboration-ui -y; then
        echo "Failed to install Carbonio WS Collaboration UI."
        status[18]="Failed"
        return
    fi
    
    echo "Enabling Carbonio WS Collaboration features..."
    if ! su - zextras -c "carbonio prov mc default carbonioFeatureChatsEnabled TRUE"; then
        echo "Failed to enable Carbonio WS Collaboration features."
        status[18]="Failed"
        return
    fi

    echo "Installed Carbonio WS Collaboration UI package and its version:"
    dpkg-query -W -f='${binary:Package} ${Version}\n' carbonio-ws-collaboration-ui | sort
    status[18]="Done"
}

# Function to Change Admin User Password
change_admin_user_password() {
    echo "Changing admin user (zextras@$(hostname -d)) password..."
    read -s -p "Enter new admin password: " ADMIN_PWD
    echo # Move to a new line for clean output
    if su - zextras -c "carbonio prov sp zextras@$(hostname -d) $ADMIN_PWD"; then
        echo "Admin user password changed successfully."
        status[19]="Done"
    else
        echo "Failed to change admin user password."
        status[19]="Failed"
    fi
}

# Function to Interactively Create Test Users with Skip Option
interactive_create_test_users() {
    echo "Would you like to create test users? (yes/no): "
    read proceed
    if [[ "$proceed" != "yes" ]]; then
        echo "Skipping user creation."
        status[20]="Skipped"
        return
    fi

    echo "Enter the number of users you want to create: "
    read num_users
    # Ensure input is a number and greater than 0
    if ! [[ "$num_users" =~ ^[0-9]+$ ]] || [ "$num_users" -le 0 ]; then
        echo "Invalid number of users. Exiting..."
        status[20]="Failed"
        return
    fi

    for ((i=1; i<=num_users; i++)); do
        echo "Enter username for user $i: "
        read username
        # Simple check for non-empty username
        if [[ -z "$username" ]]; then
            echo "Username cannot be empty. Exiting..."
            status[20]="Failed"
            return
        fi

        echo "Enter password for $username: "
        read -s password
        # Simple check for non-empty password
        if [[ -z "$password" ]]; then
            echo "Password cannot be empty. Exiting..."
            status[20]="Failed"
            return
        fi

        if su - zextras -c "carbonio prov ca $username@$(hostname -d) $password displayName \"$username\""; then
            echo "User $username created successfully."
        else
            echo "Failed to create user $username."
            status[20]="Failed"
            # Decide whether to exit or continue in case of failure
            echo "Continue creating next user? (yes/no):"
            read continueCreating
            if [[ "$continueCreating" != "yes" ]]; then
                return
            fi
        fi
    done
    status[20]="Done"
}


# Function to Modify MTA for Trusted Network
modify_mta_for_trusted_network() {
    echo "Modifying MTA for Trusted Network..."
    if su - zextras -c "carbonio prov ms $(hostname -f) zimbraMtaMyNetworks '127.0.0.0/8 $(hostname -i)/32'" && su - zextras -c "zmmtactl restart"; then
        echo "MTA configuration updated and service restarted successfully."
        status[21]="Done"
    else
        echo "Failed to update MTA configuration or restart the service."
        status[21]="Failed"
    fi
}

# Function to Restart Carbonio Services
restart_carbonio_services() {
    echo "Restarting Carbonio Services..."
    if su - zextras -c "zmcontrol restart"; then
        echo "Carbonio services restarted successfully."
        status[22]="Done"
    else
        echo "Failed to restart Carbonio services."
        status[22]="Failed"
    fi
}

# Function to Check Carbonio CE Service Status
check_carbonio_ce_service_status() {
    echo "Checking Carbonio CE Service Version..."
    if ! su - zextras -c "zmcontrol -v"; then
        echo "Failed to check Carbonio CE service version."
        status[23]="Failed"
        return
    fi
    
    echo "Checking Carbonio CE Service Status..."
    if su - zextras -c "zmcontrol status"; then
        echo "Carbonio CE service status check completed successfully."
        status[23]="Done"
    else
        echo "Failed to check Carbonio CE service status."
        status[23]="Failed"
    fi
}

# Function to Check Consul Status
check_consul_status() {
    echo "Checking Consul Status..."
    if consul members; then
        echo "Consul status check completed successfully."
        status[24]="Done"
    else
        echo "Failed to check Consul status."
        status[24]="Failed"
    fi
}

# Function to Check Carbonio CE System Unit Status
check_carbonio_ce_system_unit_status() {
    echo "Checking Carbonio CE System Unit Status..."
    if systemctl list-units carbonio*; then
        echo "Carbonio CE system unit status check completed successfully."
        status[25]="Done"
    else
        echo "Failed to check Carbonio CE system unit status."
        status[25]="Failed"
    fi
}

# Function to Check Consul Service Status via HTTP API
check_consul_service_status_http_api() {
    echo "Checking Consul Service Status via HTTP API..."
    if curl_output=$(curl -s -v http://127.78.0.4:10000/health); then
        echo "$curl_output" | jq
        echo "Consul service status check via HTTP API completed."
        status[26]="Done"
    else
        echo "Failed to retrieve Consul service status via HTTP API."
        status[26]="Failed"
    fi
}

# System Reboot and advisory
reboot_system_now() {
    echo "Advisory for System Administrators:"
    echo "After rebooting the system, consider restarting the following Carbonio services to apply any recent changes:"
echo -en "
su - zextras -c 'zmcontrol restart'
systemctl restart carbonio-tasks
systemctl restart carbonio-message-broker
systemctl restart carbonio-message-dispatcher
systemctl restart carbonio-ws-collaboration
systemctl restart carbonio-videoserver

if any attempt of initiating video call fails then clear the video call with 
PGPASSWORD=<postgresql_password> carbonio-ws-collaboration-meeting-cleanup carbonio_adm 127.0.0.1 5432
#PGPASSWORD=q carbonio-ws-collaboration-meeting-cleanup carbonio_adm 127.0.0.1 5432
also reboot
systemctl restart carbonio-videoserver
systemctl restart carbonio-ws-collaboration
"
    sudo reboot now
}

# Main loop
while true; do
    display_menu
    echo "Select an activity by number (or type 'Quit' to exit):"
    read choice
    case $choice in
	
         1)
             set_hostname
             ;;
         2)
             configure_hosts
             ;;
         3)
             set_timezone
             ;;
         4)
             add_zextras_repo
             ;;
         5)
             manage_apt_repos
			 ;;
		 6)
             install_postgresql_db
             ;;
         7)
             add_postgresql_role_and_db
             ;;
         8)
             install_carbonio_ce_packages
             ;;
         9)
             configure_carbonio_ce_bootstrap
             ;;
         10)
             configure_service_discovery
             ;;
         11)
             configure_pending_setups
             ;;
         12)
             bootstrap_files_and_tasks_db
             ask_skip_ws_collaboration
             ;;
         13)
             install_carbonio_message_dispatcher_db
             ;;
         14)
             install_carbonio_message_dispatcher
             ;;
         15)
             install_carbonio_message_broker
             ;;
         16)
             install_carbonio_ws_collaboration_db
             ;;
         17)
             install_carbonio_ws_collaboration_ce
             ;;
         18)
             install_carbonio_video_server_ce
             ;;
         19)
             install_carbonio_ws_collaboration_ui
             ;;
         20)
             change_admin_user_password
             ;;
		 21)
             interactive_create_test_users
             ;;
         22)
             modify_mta_for_trusted_network
             ;;
         23)
             restart_carbonio_services
             ;;
         24)
             check_carbonio_ce_service_status
             ;;
         25)
             check_consul_status
             ;;
         26)
             check_carbonio_ce_system_unit_status
             ;;
         27)
             check_consul_service_status_http_api
             ;;
         28)
             reboot_system_now
             ;;
         29|"Quit")
             echo "Exiting..."
             break
             ;;
         *)
             echo "Invalid option. Please enter a number from the list."
             ;;
    esac
done
