#!/bin/bash

# Display header
echo -e "Pass MDM"
echo ""

# Prompt user for choice
PS3='Please enter your choice: '
options=("Bypass MDM from Recovery" "Reboot & Exit")
select opt in "${options[@]}"; do
	case $opt in
		"Bypass MDM from Recovery")
			# Bypass MDM from Recovery
			echo -e "Bypass MDM from Recovery"
			if [ -d "/Volumes/Macintosh HD - Data" ]; then
				diskutil rename "Macintosh HD - Data" "Data"
			fi

			# Create Temporary User
			echo -e "Create a Temporary User"
			read -p "Enter Temporary Fullname (Default is 'Apple'): " realName
			realName="${realName:=Apple}"
			read -p "Enter Temporary Username (Default is 'Apple'): " username
			username="${username:=Apple}"
			read -p "Enter Temporary Password (Default is '1234'): " passw
			passw="${passw:=1234}"

			# Create User
			dscl_path='/Volumes/Data/private/var/db/dslocal/nodes/Default'
			echo -e "Creating Temporary User"
			dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username"
			dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UserShell "/bin/zsh"
			dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" RealName "$realName"
			dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UniqueID "501"
			dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" PrimaryGroupID "20"
			mkdir "/Volumes/Data/Users/$username"
			dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" NFSHomeDirectory "/Users/$username"
			dscl -f "$dscl_path" localhost -passwd "/Local/Default/Users/$username" "$passw"
			dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership $username

			# Block MDM domains
			echo "0.0.0.0 deviceenrollment.apple.com" >>/Volumes/Macintosh\ HD/etc/hosts
			echo "0.0.0.0 mdmenrollment.apple.com" >>/Volumes/Macintosh\ HD/etc/hosts
			echo "0.0.0.0 iprofiles.apple.com" >>/Volumes/Macintosh\ HD/etc/hosts
			echo -e "Successfully blocked MDM & Profile Domains"

			# Remove configuration profiles
			touch /Volumes/Data/private/var/db/.AppleSetupDone
			rm -rf /Volumes/Macintosh\ HD/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord
			rm -rf /Volumes/Macintosh\ HD/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound
			touch /Volumes/Macintosh\ HD/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled
			touch /Volumes/Macintosh\ HD/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound

			echo -e "MDM enrollment has been bypassed!"
			echo -e "Exit terminal and reboot your Mac"
			break
			;;
		"Reboot & Exit")
			# Reboot & Exit
			echo "Rebooting"
			reboot
			break
			;;
		*) echo "Invalid option $REPLY" ;;
	esac
done