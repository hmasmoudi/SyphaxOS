#!/bin/bash
###############################################################
### SyphaxOS Install Script
###
### Copyright (C) 2016  Hatem Masmoudi.
### 
### Created:
### By: Dylan Schacht (deadhead)
### Email: deadhead3492@gmail.com
### Webpage: http://SyphaxOS.org
###
### Modified for SyphaxOS:
### By Hatem Masmoudi
### Email: hatem.masmoudi@gmail.com
### Webpage: https://github.com/hmasmoudi/SyphaxOS
### License: GPL v2.0
###
### This program is free software; you can redistribute it and/or
### modify it under the terms of the GNU General Public License
### as published by the Free Software Foundation; either version 2
### of the License, or (at your option) any later version.
###
### This program is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
### GNU General Public License version 2 for more details.
################################################################

init() {

	trap '' 2
	source ./etc/SyphaxOS.conf
	op_title=" -| Language Select |- "
	ILANG=$(dialog --nocancel --menu "\nSyphaxOS Installer\n\n \Z2*\Zn Select your install language:" 20 60 10 \
		"English" "-" \
		"Frensh" "Français" 3>&1 1>&2 2>&3)

	case "$ILANG" in
		"English") export lang_file=./lang/SyphaxOS-english.conf ;;
		"Frensh") export lang_file=./lang/SyphaxOS-french.conf ;;
	esac

	source "$lang_file"
	export reload=true
	
	check_connection
}

check_connection() {
	
	op_title="$connection_op_msg"
	test_pkg=iproute2
	test_pkg_ver=4.7.0-1
	test_link="https://bintray.com/syphaxos/Cockatiel/download_file?file_path=${test_pkg}-${test_pkg_ver}-x86_64.pkg.tar.xz"
	wget --append-output=/tmp/wget.log -O /dev/null "${test_link}" &
	pid=$! pri=0.3 msg="\n$connection_load \n\n \Z1> \Z2${test_pkg}-${test_pkg_ver}-x86_64.pkg.tar.xz \Z1<\Zn" load
	
	sed -i 's/\,/\./' /tmp/wget.log
	connection_speed=$(tail /tmp/wget.log | grep '(' /tmp/wget.log | sed '1d' | awk '{print $3}' | sed 's/(//')
	connection_rate=$(tail /tmp/wget.log | grep '(' /tmp/wget.log | sed '1d' | awk '{print $4}' | sed 's/)//')
   cpu_mhz=$(lscpu | grep "CPU max MHz" | awk '{print $4}' | sed 's/\..*//')

	if [ "$?" -gt "0" ]; then
		cpu_mhz=$(lscpu | grep "CPU MHz" | awk '{print $3}' | sed 's/\..*//')
	fi
        
	case "$cpu_mhz" in
		[0-9][0-9][0-9]) 
			cpu_sleep=4.5
		;;
		[1][0-9][0-9][0-9])
			cpu_sleep=4
		;;
		[2][0-9][0-9][0-9])
			cpu_sleep=3.5
		;;
		*)
			cpu_sleep=2.5
		;;
	esac
        		
	export connection_speed connection_rate cpu_sleep
	rm /tmp/{ex_status.var,wget.log} &> /dev/null
	
	set_keys
}

set_keys() {
	
	op_title="$key_op_msg"
	keyboard=$(dialog --nocancel --ok-button "$ok" --menu "$keys_msg" 18 60 10 \
	"$default" "$default Keymap" \
	"fr" "French" \
	"uk" "United Kingdom" \
	"$other"       "$other-keymaps"		 3>&1 1>&2 2>&3)
	source "$lang_file"

	if [ "$keyboard" = "$other" ]; then
		keyboard=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$keys_msg" 19 60 10  $key_maps 3>&1 1>&2 2>&3)
		if [ "$?" -gt "0" ]; then
			set_keys
		fi
	fi
	
	export keyboard
	localectl set-keymap "$keyboard"
	set_locale
}

set_locale() {

	op_title="$locale_op_msg"
	LOCALE=$(dialog --nocancel --ok-button "$ok" --menu "$locale_msg" 18 60 11 \
	"fr_FR.UTF-8" "French" \
	"en_GB.UTF-8" "Great Britain" \
	"$other"       "$other-locale"		 3>&1 1>&2 2>&3)

	if [ "$LOCALE" = "$other" ]; then
		LOCALE=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$locale_msg" 18 60 11 $localelist 3>&1 1>&2 2>&3)

		if [ "$?" -gt "0" ]; then 
			set_locale
		fi
	fi

	set_zone
}

set_zone() {

	op_title="$zone_op_msg"
	ZONE=$(dialog --nocancel --ok-button "$ok" --menu "$zone_msg0" 18 60 11 $zonelist 3>&1 1>&2 2>&3)
	if (find /usr/share/zoneinfo -maxdepth 1 -type d | sed -n -e 's!^.*/!!p' | grep "$ZONE" &> /dev/null); then
		sublist=$(find /usr/share/zoneinfo/"$ZONE" -maxdepth 1 | sed -n -e 's!^.*/!!p' | sort | sed 's/$/ -/g' | grep -v "$ZONE")
		SUBZONE=$(dialog --ok-button "$ok" --cancel-button "$back" --menu "$zone_msg1" 18 60 11 $sublist 3>&1 1>&2 2>&3)
		if [ "$?" -gt "0" ]; then 
			set_zone 
		fi
		if (find /usr/share/zoneinfo/"$ZONE" -maxdepth 1 -type  d | sed -n -e 's!^.*/!!p' | grep "$SUBZONE" &> /dev/null); then
			sublist=$(find /usr/share/zoneinfo/"$ZONE"/"$SUBZONE" -maxdepth 1 | sed -n -e 's!^.*/!!p' | sort | sed 's/$/ -/g' | grep -v "$SUBZONE")
			SUB_SUBZONE=$(dialog --ok-button "$ok" --cancel-button "$back" --menu "$zone_msg1" 15 60 7 $sublist 3>&1 1>&2 2>&3)
			if [ "$?" -gt "0" ]; then 
				set_zone 
			fi
			ZONE="${ZONE}/${SUBZONE}/${SUB_SUBZONE}"
		else
			ZONE="${ZONE}/${SUBZONE}"
		fi
	fi

	prepare_core
	#prepare_drives
}

prepare_drives() {

	op_title="$part_op_msg"
	lsblk | grep "/mnt\|SWAP" &> /dev/null
	if [ "$?" -eq "0" ]; then
		umount -R "$ARCH" &> /dev/null &
		pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2umount -R $ARCH\Zn" load
		swapoff -a &> /dev/null &
	fi
	
	PART=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$part_msg" 14 64 4 \
	"$method2"  "-" \
	"$menu_msg" "-" 3>&1 1>&2 2>&3)

	if [ "$?" -gt "0" ] || [ "$PART" == "$menu_msg" ]; then
		main_menu
	fi
	
	case "$PART" in
		"$method2")	points=$(echo -e "$points_orig\n$custom $custom-mountpoint")
					part_menu
		;;
	esac

	if ! "$mounted" ; then
		dialog --ok-button "$ok" --msgbox "\n$part_err_msg" 10 60
		prepare_drives
	
	else
		prepare_core
	fi

}

part_menu() {

	op_title="$manual_op_msg"
	unset manual_part
	tmp_menu=/tmp/part.sh tmp_list=/tmp/part.list
	dev_menu="|  Device:  |  Size:  |  Used:  |  FS:  |  Mount:  |  Type:  |"
	count=$(lsblk | grep "sd." | grep -v "$USB\|loop\|1K" | wc -l)
	int=1

	until [ "$int" -gt "$count" ]
	  do
		device=$(lsblk | grep "sd." | grep -v "$USB\|loop\|1K" | awk "NR==$int {print \$1}")
		dev_size=$(lsblk | grep "sd." | grep -v "$USB\|loop\|1K" | awk "NR==$int {print \$4}" | sed 's/\,/\./')
		dev_type=$(lsblk | grep "sd." | grep -v "$USB\|loop\|1K" | awk "NR==$int {print \$6}")
		mnt_point=$(lsblk | grep "sd." | grep -v "$USB\|loop\|1K" | awk "NR==$int {print \$7}" | sed 's/\/mnt/\//;s/\/\//\//')

		if [ "$int" -eq "1" ]; then
			if "$screen_h" ; then
				echo "dialog --extra-button --extra-label \"$write\" --colors --backtitle \"$backtitle\" --title \"$op_title\" --ok-button \"$edit\" --cancel-button \"$cancel\" --menu \"$manual_part_msg \n\n $dev_menu\" 21 68 9 \\" > "$tmp_menu"
			else
				echo "dialog --extra-button --extra-label \"$write\" --colors --title \"$title\" --ok-button \"$edit\" --cancel-button \"$cancel\" --menu \"$manual_part_msg \n\n $dev_menu\" 20 68 8 \\" > "$tmp_menu"
			fi
			echo "\"$device   \" \"$dev_size $dev_type ------------->\" \\" > $tmp_list
		else
			if (<<<"$device" grep "sd.[0-9]" &> /dev/null) then
				if (<<<"$mnt_point" grep "/" &> /dev/null) then
					fs_type="$(df -T | grep "$(<<<"$device" sed 's/^..//')" | awk '{print $2}')"
					dev_used=$(df -T | grep "$(<<<"$device" sed 's/^..//')" | awk '{print $6}')
				else
					unset fs_type dev_used
				fi
				
				if (fdisk -l | grep "$(<<<"$device" sed 's/^..//')" | grep "*" &> /dev/null) then
					part_type=$(fdisk -l | grep "$(<<<"$device" sed 's/^..//')" | awk '{print $8,$9}')
				else
					if (fdisk -l | grep "Disklabel type: gpt" &>/dev/null) then
						part_type=$(fdisk -l | grep "$(<<<"$device" sed 's/^..//')" | awk '{print $6,$7}')
						if [ "$part_type" == "Linux filesystem" ]; then
							part_type="Linux"
						elif [ "$part_type" == "EFI System" ]; then
							part_type="EFI/ESP"
						fi
					else
						part_type=$(fdisk -l | grep "$(<<<"$device" sed 's/^..//')" | awk '{print $7,$8}')
					fi
				fi

				if [ "$part_type" == "Linux swap" ]; then
					part_type="Linux/SWAP"
				fi

				echo "\"$device\" \"$dev_size $dev_used $fs_type $mnt_point $part_type\" \\" >> "$tmp_list"
				unset part_type
			else
				echo "\"$device\" \"$dev_size $dev_type ------------->\" \\" >> "$tmp_list"
			fi
		fi

		int=$((int+1))
	done

	<"$tmp_list" column -t >> "$tmp_menu"
	echo "\"$done_msg\" \"$write\" 3>&1 1>&2 2>&3" >> "$tmp_menu"
	echo "if [ \"\$?\" -eq \"3\" ]; then clear ; echo \"$done_msg\" ; fi" >> "$tmp_menu"
	manual_part=$(bash "$tmp_menu" | sed 's/ //g')
	rm $tmp_menu $tmp_list
	if (<<<"$manual_part" grep "$done_msg") then manual_part="$done_msg" ; fi
	part_class

}
	
part_class() {

	op_title="$edit_op_msg"
	if [ -z "$manual_part" ]; then
		prepare_drives
	elif (<<<$manual_part grep "[0-9]" &> /dev/null); then
		part=$(<<<"$manual_part" sed 's/^..//')
		part_size=$(lsblk | grep "$part" | awk '{print $4}' | sed 's/\,/\./')
		part_mount=$(lsblk | grep "$part" | awk '{print $7}' | sed 's/\/mnt/\//;s/\/\//\//')
		source "$lang_file"  &> /dev/null

		if ! (lsblk | grep "part" | grep "$ARCH" &> /dev/null); then
			case "$part_size" in
				[4-9]G|[0-9][0-9]*G|[4-9].*G|T)
					if (dialog --yes-button "$yes" --no-button "$no" --defaultno --yesno "\n$root_var" 13 60) then
						f2fs=$(cat /sys/block/$(echo $part | sed 's/[0-9]//g')/queue/rotational)
						fs_select

						if [ "$?" -gt "0" ]; then
							part_menu
						fi

						source "$lang_file"

						if (dialog --yes-button "$write" --no-button "$cancel" --defaultno --yesno "\n$root_confirm_var" 14 50) then
							sgdisk --zap-all /dev/"$part"
							wipefs -a /dev/"$part" &> /dev/null &
							pid=$! pri=0.1 msg="\n$frmt_load \n\n \Z1> \Z2wipefs -a /dev/$part\Zn" load

							case "$FS" in
								jfs|reiserfs)
									echo -e "y" | mkfs."$FS" /dev/"$part" &> /dev/null &
								;;
								*)
									mkfs."$FS" /dev/"$part" &> /dev/null &
								;;
							esac
							pid=$! pri=1 msg="\n$load_var1 \n\n \Z1> \Z2mkfs.$FS /dev/$part\Zn" load

							(mount /dev/"$part" "$ARCH"
							echo "$?" > /tmp/ex_status.var) &> /dev/null &
							pid=$! pri=0.1 msg="\n$mnt_load \n\n \Z1> \Z2mount /dev/$part $ARCH\Zn" load

							if [ $(</tmp/ex_status.var) -eq "0" ]; then
								mounted=true
								ROOT="$part"
								DRIVE=$(<<<$part sed 's/[0-9]//')
							else
								dialog --ok-button "$ok" --msgbox "\n$part_err_msg1" 10 60
								prepare_drives
							fi
						fi
					else
						part_menu
					fi
				;;
				*)
					dialog --ok-button "$ok" --msgbox "\n$root_err_msg" 10 60
				;;
			esac
		elif [ -n "$part_mount" ]; then
			if (dialog --yes-button "$edit" --no-button "$back" --defaultno --yesno "\n$manual_part_var0" 13 60) then
				if [ "$part" == "$ROOT" ]; then
					if (dialog --yes-button "$yes" --no-button "$no" --defaultno --yesno "\n$manual_part_var2" 11 60) then
						mounted=false
						unset ROOT DRIVE
						umount -R "$ARCH" &> /dev/null &
						pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2umount -R $ARCH\Zn" load
					fi
				else
					if [ "$part_mount" == "[SWAP]" ]; then
						if (dialog --yes-button "$yes" --no-button "$no" --defaultno --yesno "\n$manual_swap_var" 10 60) then
							swapoff /dev/"$part" &> /dev/null &
							pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2swapoff /dev/$part\Zn" load
						fi
					elif (dialog --yes-button "$yes" --no-button "$no" --defaultno --yesno "\n$manual_part_var1" 10 60) then
						umount  "$ARCH"/"$part_mount" &> /dev/null &
						pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2umount ${ARCH}${part_mount}\Zn" load
						rm -r "$ARCH"/"$part_mount"
						points=$(echo -e "$part_mount   mountpoint>\n$points")
					fi
				fi
			fi
		elif (dialog --yes-button "$edit" --no-button "$back" --yesno "\n$manual_new_part_var" 12 60) then
			mnt=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$mnt_var0" 15 60 6 $points 3>&1 1>&2 2>&3)
			
			if [ "$?" -gt "0" ]; then
				part_menu
			fi

			if [ "$mnt" == "$custom" ]; then
				err=true

				until ! "$err"
				  do
					mnt=$(dialog --ok-button "$ok" --cancel-button "$cancel" --inputbox "$custom_msg" 10 50 "/" 3>&1 1>&2 2>&3)
					
					if [ "$?" -gt "0" ]; then
						err=false
						part_menu
					elif (<<<$mnt grep "[\[\$\!\'\"\`\\|%&#@()+=<>~;:?.,^{}]\|]" &> /dev/null); then
						dialog --ok-button "$ok" --msgbox "\n$custom_err_msg0" 10 60
					elif (<<<$mnt grep "^[/]$" &> /dev/null); then
						dialog --ok-button "$ok" --msgbox "\n$custom_err_msg1" 10 60
					else
						err=false
					fi
				done
			fi
			
			if [ "$mnt" != "SWAP" ]; then
				if (dialog --yes-button "$yes" --no-button "$no" --defaultno --yesno "\n$part_frmt_msg" 11 50) then
					f2fs=$(cat /sys/block/$(echo $part | sed 's/[0-9]//g')/queue/rotational)
					
					if [ "$mnt" == "/boot" ] || [ "$mnt" == "/boot/EFI" ] || [ "$mnt" == "/boot/efi" ]; then
						if (fdisk -l | grep "$part" | grep "EFI" &> /dev/null); then
							vfat=true
						fi
						f2fs=1
						btrfs=false
					fi
					
					fs_select

					if [ "$?" -gt "0" ]; then
						part_menu
					fi
					frmt=true
				else
					frmt=false
				fi
			else
				FS="SWAP"
			fi

			source "$lang_file"
		
			if [ "$mnt" == "SWAP" ]; then
				if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$swap_frmt_msg" 11 50) then
					(wipefs -a -q /dev/"$part"
					mkswap /dev/"$part"
					swapon /dev/"$part") &> /dev/null &
					pid=$! pri=0.1 msg="\n$swap_load \n\n \Z1> \Z2mkswap /dev/$part\Zn" load
				else
					swapon /dev/"$part" &> /dev/null
					if [ "$?" -gt "0" ]; then
						dialog --ok-button "$ok" --msgbox "$swap_err_msg2" 10 60
					fi
				fi
			else
				points=$(echo  "$points" | grep -v "$mnt")
			
				if "$frmt" ; then
					if (dialog --yes-button "$write" --no-button "$cancel" --defaultno --yesno "$part_confirm_var" 12 50) then
						sgdisk --zap-all /dev/"$part"
						wipefs -a /dev/"$part" &> /dev/null &
						pid=$! pri=0.1 msg="\n$frmt_load \n\n \Z1> \Z2wipefs -a /dev/$part\Zn" load
			
						case "$FS" in
							vfat)
								mkfs.vfat -F32 /dev/"$part" &> /dev/null &
							;;
							jfs|reiserfs)
								echo -e "y" | mkfs."$FS" /dev/"$part" &> /dev/null &
							;;
							*)
								mkfs."$FS" /dev/"$part" &> /dev/null &
							;;
						esac
						pid=$! pri=1 msg="\n$load_var1 \n\n \Z1> \Z2mkfs.FS /dev/$part\Zn" load
					else
						part_menu
					fi
				fi
					
				(mkdir -p "$ARCH"/"$mnt"
				mount /dev/"$part" "$ARCH"/"$mnt" ; echo "$?" > /tmp/ex_status.var ; sleep 0.5) &> /dev/null &
				pid=$! pri=0.1 msg="\n$mnt_load \n\n \Z1> \Z2mount /dev/$part ${ARCH}${mnt}\Zn" load

				if [ "$(</tmp/ex_status.var)" -gt "0" ]; then
					dialog --ok-button "$ok" --msgbox "\n$part_err_msg2" 10 60
				fi
			fi
		fi

		part_menu
	elif [ "$manual_part" == "$done_msg" ]; then
		if ! "$mounted" ; then
			dialog --ok-button "$ok" --msgbox "\n$root_err_msg1" 10 60
			part_menu
		else
			final_part=$(lsblk | grep "/\|[SWAP]" | grep "part" | grep -v "/run" | awk '{print " "$1" "$4" "$7 "\\n"}' | sed 's/\/mnt/\//;s/\/\//\//' | column -t)
			final_count=$(lsblk | grep "/\|[SWAP]" | grep "part" | grep -v "/run" | wc -l)

			if [ "$final_count" -lt "7" ]; then
				height=17
			elif [ "$final_count" -lt "13" ]; then
				height=23
			elif [ "$final_count" -lt "17" ]; then
				height=26
			else
				height=30
			fi
			
			part_menu="$partition: $size: $mountpoint:"
			
			if (dialog --yes-button "$write" --no-button "$cancel" --defaultno --yesno "\n$write_confirm_msg \n\n $part_menu \n\n$final_part \n\n $write_confirm" "$height" 50) then
				if (efivar -l &>/dev/null); then
					if (fdisk -l | grep "EFI" &>/dev/null); then
						if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$efi_man_msg" 11 60) then
							if [ "$(fdisk -l | grep "EFI" | wc -l)" -gt "1" ]; then
								efint=1
								while (true)
								  do
									if [ "$(fdisk -l | grep "EFI" | awk "NR==$efint {print \$1}")" == "" ]; then
										dialog --ok-button "$ok" --msgbox "$efi_err_msg1" 10 60
										part_menu
									fi
									esp_part=$(fdisk -l | grep "EFI" | awk "NR==$efint {print \$1}")
									esp_mnt=$(df -T | grep "$esp_part" | awk '{print $7}' | sed 's|/mnt||')
									if (df -T | grep "$esp_part" &> /dev/null); then
										break
									else
										efint=$((efint+1))
									fi
								done
							else
								esp_part=$(fdisk -l | grep "EFI" | awk '{print $1}')
								if ! (df -T | grep "$esp_part" &> /dev/null); then
									source "$lang_file"
									if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$efi_mnt_var" 11 60) then
										if ! (mountpoint "$ARCH"/boot &> /dev/null); then
											mkdir "$ARCH"/boot &> /dev/null
											mount "$esp_part" "$ARCH"/boot
										else
											dialog --ok-button "$ok" --msgbox "\n$efi_err_msg" 10 60
											part_menu
										fi
									else
										part_menu
									fi
								else
									esp_mnt=$(df -T | grep "$esp_part" | awk '{print $7}' | sed 's|/mnt||')
								fi
							fi
							source "$lang_file"
							if ! (df -T | grep "$esp_part" | grep "vfat" &>/dev/null) then
								if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$vfat_var" 11 60) then
										(umount -R "$esp_mnt"
										mkfs.vfat -F32 "$esp_part"
										mount "$esp_part" "$esp_mnt") &> /dev/null &
										pid=$! pri=0.2 msg="\n$efi_load1 \n\n \Z1> \Z2mkfs.vfat -F32 $esp_part\Zn" load
										UEFI=true
								else
									part_menu
								fi
							else
								UEFI=true
								export esp_part esp_mnt
							fi
						fi
					fi
				fi

				if "$enable_f2fs" ; then
					if ! (lsblk | grep "$ARCH/boot\|$ARCH/boot/efi" &> /dev/null) then
						FS="f2fs" source "$lang_file"
						dialog --ok-button "$ok" --msgbox "\n$fs_err_var" 10 60
						part_menu
					fi
				elif "$enable_btrfs" ; then
					if ! (lsblk | grep "$ARCH/boot\|$ARCH/boot/efi" &> /dev/null) then
						FS="btrfs" source "$lang_file"
						dialog --ok-button "$ok" --msgbox "\n$fs_err_var" 10 60
						part_menu
					fi
				fi
				
				sleep 1
				pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2Finalize...\Zn" load
				prepare_core
			else
				part_menu
			fi
		fi
	else
		part_size=$(lsblk | grep "$manual_part" | awk 'NR==1 {print $4}')
		source "$lang_file"

		if (lsblk | grep "$manual_part" | grep "$ARCH" &> /dev/null); then	
			if (dialog --yes-button "$edit" --no-button "$cancel" --defaultno --yesno "\n$mount_warn_var" 10 60) then
				points=$(echo -e "$points_orig\n$custom $custom-mountpoint")
				(umount -R "$ARCH"
				swapoff -a) &> /dev/null &
				pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2umount -R /mnt\Zn" load
				mounted=false
				unset DRIVE
				cfdisk /dev/"$manual_part"
				sleep 0.5
				clear
			fi
		elif (dialog --yes-button "$edit" --no-button "$cancel" --yesno "$manual_part_var3" 12 60) then
			cfdisk /dev/"$manual_part"
			sleep 0.5
			clear
		fi

		part_menu
	fi

}

fs_select() {

	if "$vfat" ; then
		FS=$(dialog --menu "$vfat_msg" 11 65 1 \
			"vfat"  "$fs7" 3>&1 1>&2 2>&3)
		if [ "$?" -gt "0" ]; then
			part_menu
		fi
		vfat=false
	else
		if [ "$f2fs" -eq "0" ]; then
			FS=$(dialog --nocancel --menu "$fs_msg" 17 65 7 \
				"ext4"      "$fs0" \
				"ext3"      "$fs1" \
				"ext2"      "$fs2" \
				"btrfs"     "$fs3" \
				"f2fs"		"$fs6" \
				"jfs"       "$fs4" \
				"reiserfs"  "$fs5" 3>&1 1>&2 2>&3)
		elif "$btrfs" ; then
				FS=$(dialog --nocancel --menu "$fs_msg" 16 65 6 \
				"ext4"      "$fs0" \
				"ext3"      "$fs1" \
				"ext2"      "$fs2" \
				"btrfs"     "$fs3" \
				"jfs"       "$fs4" \
				"reiserfs"  "$fs5" 3>&1 1>&2 2>&3)
		else
			FS=$(dialog --nocancel --menu "$fs_msg" 15 65 5 \
				"ext4"      "$fs0" \
				"ext3"      "$fs1" \
				"ext2"      "$fs2" \
				"jfs"       "$fs4" \
				"reiserfs"  "$fs5" 3>&1 1>&2 2>&3)
				btrfs=true
		fi
	fi

	if [ "$FS" == "f2fs" ]; then
		enable_f2fs=true
	elif [ "$FS" == "btrfs" ]; then
		enable_btrfs=true
	fi

}

prepare_core() {
	
	op_title="$install_op_msg"
	mounted=true
	if "$mounted" ; then
		base_install="SyphaxOS-Desktop"
      sh="/bin/bash"

		while (true)
		  do

			bootloader=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$loader_type_msg" 11 64 2 \
				"grub"			"$loader_msg" \
				"$none" "-" 3>&1 1>&2 2>&3)
			ex="$?"

			if [ "$?" -gt "0" ]; then
				if (dialog --defaultno --yes-button "$yes" --no-button "$no" --yesno "\n$exit_msg" 10 60) then
					main_menu
				fi
			else
				if [ "$bootloader" != "$none" ]; then
					base_install="$base_install $bootloader" ; break
				else
					if (dialog --defaultno --yes-button "$yes" --no-button "$no" --yesno "$grub_warn_msg0" 10 60) then
						dialog --ok-button "$ok" --msgbox "$grub_warn_msg1" 10 60
						break
					fi
				fi
			fi			
		done

	elif "$INSTALLED" ; then
		dialog --ok-button "$ok" --msgbox "\n$install_err_msg0" 10 60
		main_menu
	
	else

		if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$install_err_msg1" 10 60) then
			prepare_drives
		else
			dialog --ok-button "$ok" --msgbox "\n$install_err_msg2" 10 60
			main_menu
		fi
	fi
	
	install_base

}

install_base() {

	op_title="$install_op_msg"
	ARCH=/SyphaxOS-2.0.0
	pacman -Sy --print-format='%s' $(echo "$base_install") | awk '{s+=$1} END {print s/1024/1024}' >/tmp/size &
	pid=$! pri=0.1 msg="\n$pacman_load \n\n \Z1> \Z2pacman -Sy --print-format\Zn" load
	download_size=$(</tmp/size) ; rm /tmp/size
	export software_size="$download_size Mib"
	cal_rate
	
	if (dialog --yes-button "$install" --no-button "$cancel" --yesno "\n$install_var" "$x" 60); then
		tmpfile=$(mktemp)
		mkdir -p "$ARCH"/usr/var/lib/pacman
		( pacman -r "$ARCH" -Sy --noconfirm $(echo "$base_install") ; echo "$?" > /tmp/ex_status) &> "$tmpfile" &
		pid=$! pri=$(echo "$down" | sed 's/\..*$//') msg="\n$install_load_var" load_log
		genfstab -U -p "$ARCH" >> "$ARCH"/etc/fstab

		if [ $(</tmp/ex_status) -eq "0" ]; then
			INSTALLED=true
		else
			mv "$tmpfile" /tmp/SyphaxOS.log
			dialog --ok-button "$ok" --msgbox "\n$failed_msg" 10 60
			reset ; tail /tmp/SyphaxOS.log ; exit 1
		fi

		case "$bootloader" in
			grub) grub_config ;;
			syslinux) syslinux_config ;;
		esac

		configure_system
	else
		if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$exit_msg" 10 60) then
			main_menu
		else
			install_base
		fi
	fi

}

grub_config() {
	
	if "$crypted" ; then
		sed -i 's!quiet!cryptdevice=/dev/lvm/lvroot:root root=/dev/mapper/root!' "$ARCH"/etc/default/grub
	else
		sed -i 's/quiet//' "$ARCH"/etc/default/grub
	fi

	if "$UEFI" ; then
		(chroot "$ARCH" grub-install --efi-directory="$esp_mnt" --target=x86_64-efi --bootloader-id=boot
		mv "$ARCH"/"$esp"/EFI/boot/grubx64.efi "$ARCH"/"$esp"/EFI/boot/bootx64.efi) &> /dev/null &
		pid=$! pri=0.1 msg="\n$grub_load1 \n\n \Z1> \Z2grub-install --efi-directory="$esp_mnt"\Zn" load
				
		if ! "$crypted" ; then
			chroot "$ARCH" mkinitcpio -p linux &> /dev/null &
			pid=$! pri=1 msg="\n$uefi_config_load \n\n \Z1> \Z2mkinitcpio -p linux\Zn" load
		fi
	else
		chroot "$ARCH" grub-install /dev/"$DRIVE" &> /dev/null &
		pid=$! pri=0.1 msg="\n$grub_load1 \n\n \Z1> \Z2grub-install /dev/$DRIVE\Zn" load
	fi
	chroot "$ARCH" grub-mkconfig -o /boot/grub/grub.cfg &> /dev/null &
	pid=$! pri=0.1 msg="\n$grub_load2 \n\n \Z1> \Z2grub-mkconfig -o /boot/grub/grub.cfg\Zn" load

}

configure_system() {

	op_title="$config_op_msg"
	
	(sed -i -e "s/#$LOCALE/$LOCALE/" "$ARCH"/etc/locale.gen
	echo LANG="$LOCALE" > "$ARCH"/etc/locale.conf
	chroot "$ARCH" locale-gen) &> /dev/null &
	pid=$! pri=0.1 msg="\n$locale_load_var \n\n \Z1> \Z2LANG=$LOCALE ; locale-gen\Zn" load
	
	if [ "$keyboard" != "$default" ]; then
		echo "KEYMAP=$keyboard" > "$ARCH"/etc/vconsole.conf
		if "$desktop" ; then
			chroot "$ARCH" setxkbmap -layout "$keyboard"
		fi
	fi

	(chroot "$ARCH" ln -s /usr/share/zoneinfo/"$ZONE" /etc/localtime
	sleep 0.5) &
	pid=$! pri=0.1 msg="\n$zone_load_var \n\n \Z1> \Z2ln -s $ZONE /etc/localtime\Zn" load
	
	set_hostname
}


set_hostname() {

	op_title="$host_op_msg"
	hostname=$(dialog --ok-button "$ok" --nocancel --inputbox "\n$host_msg" 12 55 "SyphaxOS" 3>&1 1>&2 2>&3 | sed 's/ //g')
	
	if (<<<$hostname grep "^[0-9]\|[\[\$\!\'\"\`\\|%&#@()+=<>~;:/?.,^{}]\|]" &> /dev/null); then
		dialog --ok-button "$ok" --msgbox "\n$host_err_msg" 10 60
		set_hostname
	fi
	
	echo "$hostname" > "$ARCH"/etc/hostname
	op_title="$passwd_op_msg"
	
	while [ "$input" != "$input_chk" ]
	  do
		input=$(dialog --nocancel --clear --insecure --passwordbox "$root_passwd_msg0" 11 55 --stdout)
    	input_chk=$(dialog --nocancel --clear --insecure --passwordbox "$root_passwd_msg1" 11 55 --stdout)
	 	
	 	if [ -z "$input" ]; then
	 		dialog --ok-button "$ok" --msgbox "\n$passwd_msg0" 10 55
	 		input_chk=default
	 	
	 	elif [ "$input" != "$input_chk" ]; then
	 	     dialog --ok-button "$ok" --msgbox "\n$passwd_msg1" 10 55
	 	fi
	done

	(printf "$input\n$input" | chroot "$ARCH" passwd ; chroot "$ARCH" chsh -s "$sh") &> /dev/null &
	pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2passwd root\Zn" load
	unset input input_chk ; input_chk=default
	add_user

}

add_user() {

	op_title="$user_op_msg"
	if ! "$menu_enter" ; then
		if ! (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$user_msg0" 10 60) then
			main_menu
		fi
	fi

	user=$(dialog --nocancel --inputbox "\n$user_msg1" 12 55 "" 3>&1 1>&2 2>&3 | sed 's/ //g')
	if [ -z "$user" ]; then
		dialog --ok-button "$ok" --msgbox "\n$user_err_msg" 10 60
		add_user
	elif (<<<$user grep "^[0-9]\|[ABCDEFGHIJKLMNOPQRSTUVWXYZ\[\$\!\'\"\`\\|%&#@()_-+=<>~;:/?.,^{}]\|]" &> /dev/null); then
		dialog --ok-button "$ok" --msgbox "\n$user_err_msg" 10 60
		add_user
	fi

	chroot "$ARCH" useradd -m -g users "$user" &>/dev/null &
	pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2useradd -m -g users -G ... -s $sh $user\Zn" load

	source "$lang_file"
	op_title="$passwd_op_msg"
	while [ "$input" != "$input_chk" ]
	  do
		input=$(dialog --nocancel --clear --insecure --passwordbox "$user_var0" 11 55 --stdout)
    	input_chk=$(dialog --nocancel --clear --insecure --passwordbox "$user_var1" 11 55 --stdout)
		 
		if [ -z "$input" ]; then
			dialog --ok-button "$ok" --msgbox "\n$passwd_msg0" 10 55
			input_chk=default
		elif [ "$input" != "$input_chk" ]; then
			dialog --ok-button "$ok" --msgbox "\n$passwd_msg1" 10 55
		fi
	done

	(printf "$input\n$input" | chroot "$ARCH" passwd "$user") &> /dev/null &
	pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2passwd $user\Zn" load
	unset input input_chk ; input_chk=default
	op_title="$user_op_msg"
	
	if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$sudo_var" 10 60) then
		(sed -i '/%wheel ALL=(ALL) ALL/s/^#//' $ARCH/etc/sudoers
		chroot "$ARCH" usermod -a -G wheel "$user") &> /dev/null &
		pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2usermod -a -G wheel $user\Zn" load
	fi

	if "$menu_enter" ; then
		reboot_system
	else	
		main_menu
	fi

}

reboot_system() {

	op_title="$complete_op_msg"
	if "$INSTALLED" ; then
		if [ "$bootloader" == "$none" ]; then
			if (dialog --yes-button "$yes" --no-button "$no" --yesno "$complete_no_boot_msg" 10 60) then
				reset ; exit
			fi
		fi

		reboot_menu=$(dialog --nocancel --ok-button "$ok" --menu "$complete_msg" 15 60 6 \
			"$reboot0" "-" \
			"$reboot6" "-" \
			"$reboot2" "-" \
			"$reboot1" "-" \
			"$reboot3" "-" \
			"$reboot5" "-" 3>&1 1>&2 2>&3)
		
		case "$reboot_menu" in
			"$reboot0")		umount -R "$ARCH"
							reset ; reboot ; exit
			;;
			"$reboot6")		umount -R "$ARCH"
							reset ; poweroff ; exit
			;;
			"$reboot1")		umount -R "$ARCH"
							reset ; exit
			;;
			"$reboot2")		clear
							echo -e "$arch_chroot_msg" 
							echo "/root" > /tmp/chroot_dir.var
							syphaxos_chroot
							clear
			;;
			"$reboot3")		if (dialog --yes-button "$yes" --no-button "$no" --yesno "$user_exists_msg" 10 60); then
								menu_enter=true
								add_user	
							else
								reboot_system
							fi
			;;
			"$reboot5")		main_menu
			;;
		esac

	else

		if (dialog --yes-button "$yes" --no-button "$no" --yesno "$not_complete_msg" 10 60) then
			umount -R $ARCH
			reset ; reboot ; exit
		else
			main_menu
		fi
	fi

}

main_menu() {

	op_title="$menu_op_msg"
	menu_item=$(dialog --nocancel --ok-button "$ok" --menu "$menu" 20 60 9 \
		"$menu13" "-" \
		"$menu0"  "-" \
		"$menu1"  "-" \
		"$menu2"  "-" \
		"$menu3"  "-" \
		"$menu4"  "-" \
		"$menu5"  "-" \
		"$menu11" "-" \
		"$menu12" "-" 3>&1 1>&2 2>&3)

	case "$menu_item" in
		"$menu0")	set_locale
		;;
		"$menu1")	set_zone
		;;
		"$menu2")	set_keys
		;;
		"$menu3")	if "$mounted" ; then 
						if (dialog --yes-button "$yes" --no-button "$no" --defaultno --yesno "\n$menu_err_msg3" 10 60); then
							mounted=false ; prepare_drives
						else
							main_menu
						fi
					fi
 					prepare_drives 
		;;
		"$menu4") 	update_mirrors
		;;
		"$menu5")	prepare_core
		;;
		"$menu11") 	reboot_system
		;;
		"$menu12") 	if "$INSTALLED" ; then
						dialog --ok-button "$ok" --msgbox "\n$menu_err_msg4" 10 60
						reset ; exit
					else
						if (dialog --yes-button "$yes" --no-button "$no" --yesno "\n$menu_exit_msg" 10 60) then
							reset ; exit
						else
							main_menu
						fi
					fi
		;;
		"$menu13")	echo -e "alias SyphaxOS=exit ; echo -e '$return_msg'" > /tmp/.zshrc
					clear
					ZDOTDIR=/tmp/ zsh
					rm /tmp/.zshrc
					clear
					main_menu
		;;
	esac

}

syphaxos_chroot() {

	local char=
    local input=
    local -a history=( )
    local -i histindex=0
	trap ctrl_c INT
	working_dir=$(</tmp/chroot_dir.var)
	
	while (true)
	  do
		echo -n "${Yellow}<${Red}root${Yellow}@${Green}${hostname}-chroot${Yellow}>: $working_dir>${Red}# ${ColorOff}" ; while IFS= read -r -n 1 -s char
		  do
			if [ "$char" == $'\x1b' ]; then
				while IFS= read -r -n 2 -s rest
          		  do
                	char+="$rest"
                	break
            	done
        	fi

			if [ "$char" == $'\x1b[D' ]; then
				pos=-1

			elif [ "$char" == $'\x1b[C' ]; then
				pos=1

			elif [[ $char == $'\177' ]];  then
				input="${input%?}"
				echo -ne "\r\033[K${Yellow}<${Red}root${Yellow}@${Green}${hostname}-chroot${Yellow}>: $working_dir>${Red}# ${ColorOff}${input}"
			
			elif [ "$char" == $'\x1b[A' ]; then
            # Up
            	if [ $histindex -gt 0 ]; then
                	histindex+=-1
                	input=$(echo -ne "${history[$histindex]}")
					echo -ne "\r\033[K${Yellow}<${Red}root${Yellow}@${Green}${hostname}-chroot${Yellow}>: $working_dir>${Red}# ${ColorOff}${history[$histindex]}"
				fi  
        	elif [ "$char" == $'\x1b[B' ]; then
            # Down
            	if [ $histindex -lt $((${#history[@]} - 1)) ]; then
                	histindex+=1
                	input=$(echo -ne "${history[$histindex]}")
                	echo -ne "\r\033[K${Yellow}<${Red}root${Yellow}@${Green}${hostname}-chroot${Yellow}>: $working_dir>${Red}# ${ColorOff}${history[$histindex]}"
				fi  
        	elif [ -z "$char" ]; then
            # Newline
				echo
            	history+=( "$input" )
            	histindex=${#history[@]}
				break
        	else
            	echo -n "$char"
            	input+="$char"
        	fi  
		done
    	
		if [ "$input" == "SyphaxOS" ] || [ "$input" == "exit" ]; then
        	rm /tmp/chroot_dir.var &> /dev/null
			clear
			break
	    elif (<<<"$input" grep "^cd " &> /dev/null); then 
	    	ch_dir=$(<<<$input cut -c4-)
	        chroot "$ARCH" /bin/bash -c "cd $working_dir ; cd $ch_dir ; pwd > /etc/chroot_dir.var"
	        mv "$ARCH"/etc/chroot_dir.var /tmp/
			working_dir=$(</tmp/chroot_dir.var)
		elif  (<<<"$input" grep "^help" &> /dev/null); then
			echo -e "$arch_chroot_msg"
		else
	    	chroot "$ARCH" /bin/bash -c "cd $working_dir ; $input"
	    fi   
	input=
	done

	reboot_system

}

ctrl_c() {

	echo
	echo "${Red} Exiting and cleaning up..."
	sleep 0.5
	unset input
	rm /tmp/chroot_dir.var &> /dev/null
	clear
	reboot_system

}

dialog() {

	if "$screen_h" ; then
		/usr/bin/dialog --colors --backtitle "$backtitle" --title "$op_title" "$@"
	else
		/usr/bin/dialog --colors --title "$title" "$@"
	fi

}

cal_rate() {
			
	case "$connection_rate" in
		KB/s) 
			down_sec=$(echo "$download_size*1024/$connection_speed" | bc) ;;
		MB/s)
			down_sec=$(echo "$download_size/$connection_speed" | bc) ;;
		*) 
			down_sec="1" ;;
	esac
        
	down=$(echo "$down_sec/100+$cpu_sleep" | bc)
	down_min=$(echo "$down*100/60" | bc)
	
	if ! (<<<$down grep "^[1-9]" &> /dev/null); then
		down=3
		down_min=5
	fi
	
	export down down_min
	source "$lang_file"

}

load() {

	{	int="1"
        	while ps | grep "$pid" &> /dev/null
    	    	do
    	            sleep $pri
    	            echo $int
    	        	if [ "$int" -lt "100" ]; then
    	        		int=$((int+1))
    	        	fi
    	        done
            echo 100
            sleep 1
	} | dialog --gauge "$msg" 9 79 0

}

load_log() {
	
	{	int=1
		pos=1
		pri=$((pri*2))
		while ps | grep "$pid" &> /dev/null
    	    do
    	        sleep 0.5
    	        if [ "$pos" -eq "$pri" ] && [ "$int" -lt "100" ]; then
    	        	pos=0
    	        	int=$((int+1))
    	        fi
    	        log=$(tail -n 1 "$tmpfile" | sed 's/.pkg.tar.xz//')
    	        echo "$int"
    	        echo -e "XXX$msg \n \Z1> \Z2$log\Zn\nXXX"
    	        pos=$((pos+1))
    	    done
            echo 100
            sleep 1
	} | dialog --gauge "$msg" 10 79 0

}

opt="$1"
init
