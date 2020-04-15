#!/bin/bash



# thuit
# by Steven Saus
#
# Finding .desktop health

########################################################################
# Declarations
########################################################################
tmpfile=$(mktemp)
tmpfile2=$(mktemp)

##############################################################################
# Find .desktop files in standard locations
##############################################################################

# Use XDG data if possible
directory_array=( $(echo $XDG_DATA_DIRS | sed  's/:/\/applications\n/g') )

# Other ones I found on my system that aren't in XDG data dirs for some reason

directory_array+=( $(if [ -d ~/desktop ];then realpath ~/desktop;fi) )
directory_array+=( $(if [ -d ~/Desktop ];then realpath ~/Desktop;fi) )
directory_array+=( $(if [ -d ~/.gnome/apps ];then realpath ~/.gnome/apps;fi) )
directory_array+=( $(if [ -d ~/.local/share/applications ];then realpath ~/.local/share/applications;fi) )
directory_array+=( $(if [ -d /usr/share/applications ];then echo "/usr/share/applications";fi) )
directory_array+=( $(if [ -d /usr/local/share/applications ];then echo "/usr/local/share/applications";fi) )
directory_array+=( $(if [ -d /usr/share/gdm/applications ];then echo "/usr/share/gdm/applications";fi) )
directory_array+=( $(if [ -d /usr/share/applications/kde ];then echo "/usr/share/applications/kde";fi) )

# I am tempted to put /etc/xdg/autostart and ~/.config/autostart in here, but those 
# have some special things that I'd like to avoid...

# Obtain *.desktop files from linux directories
for i in "${directory_array[@]}"; do
    IFS=$(echo -en "\n\b")
    launcher_array+=( $(find "${i}" -type f -iname "*.desktop") )
done

# Finding crossover desktop files
# Should probably work for Play On Linux as well
# Just goes through and finds the *.desktop files... feed this straight to an array

crossoverpath=$(realpath ~/.cxoffice)
if [ -d "$crossoverpath" ];then
    IFS=$(echo -en "\n\b")
    launcher_array+=( $(find "$crossoverpath" -type d -iname "Launchers" -exec find '{}' -type f -iname "*.desktop" \;) )
fi

# So here's all the .desktop files we've found, sorting them out  
for ((i = 0; i < ${#launcher_array[@]}; i++));do
    printf "%s\n" "${launcher_array[$i]}"  >> "$tmpfile"
done

# Hacky way to remove duplicates, but hey.
cat "$tmpfile" | sort -u > "$tmpfile2"
uniq_launchers=( $(cat "$tmpfile" | sort -u) )

echo "There are ${#uniq_launchers[@]} desktop files to examine."
read
for ((i = 0; i < ${#uniq_launchers[@]}; i++));do
    printf "%s - %s\n" "$i" "${uniq_launchers[$i]}"
    bob=$(cat ${uniq_launchers[$i]})
    echo "$bob" | grep "Type=" 
    echo "$bob" | grep "Icon="
    echo "$bob" | grep "Exec="
    echo "$bob" | grep "TryExec="
    echo "$bob" | grep "Name="
    echo "$bob" | grep "GenericName="
    echo "$bob" | grep "Categories="
    echo "$bob" | grep "Comment="
    echo "$bob" | grep "Hidden="
    echo "$bob" | grep "ShowIn="
    read
done