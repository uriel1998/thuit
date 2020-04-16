#!/bin/bash



# thuit
# by Steven Saus
#
# Finding .desktop health

##############################################################################
# Declarations
##############################################################################
tmpfile=$(mktemp)
tmpfile2=$(mktemp)

##############################################################################
# Find .desktop files in standard locations
##############################################################################

function find_desktop() {
    
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
#read
echo "Reading in file data:"
for ((i = 0; i < ${#uniq_launchers[@]}; i++));do
    echo "$i of ${#uniq_launchers[@]}"
    #printf "%s - %s\n" "$i" "${uniq_launchers[$i]}"
    bob=$(cat ${uniq_launchers[$i]}) 
    if [ `echo "$bob" | grep -c "Type="` > 0 ];then Type[$i]=$(echo "$bob" | grep "Type=" | cut -d = -f 2);else Type[$i]="None";fi
    if [ `echo "$bob" | grep -c "Icon="` > 0 ];then Icon[$i]=$(echo "$bob" | grep "Icon=" | cut -d = -f 2);else Icon[$i]="None";fi    
    if [ `echo "$bob" | grep -c "Exec="` > 0 ];then Exec[$i]=$(echo "$bob" | grep "Exec=" | cut -d = -f 2);else Exec[$i]="None";fi
    if [ `echo "$bob" | grep -c "TryExec="` > 0 ];then TryExec[$i]=$(echo "$bob" | grep "TryExec=" | cut -d = -f 2);else TryExec[$i]="None";fi
    if [ `echo "$bob" | grep -c "Name="` > 0 ];then Name[$i]=$(echo "$bob" | grep "Name=" | cut -d = -f 2);else Name[$i]="None";fi
    if [ `echo "$bob" | grep -c "Generic Name="` > 0 ];then Generic_Name[$i]=$(echo "$bob" | grep "Generic Name=" | cut -d = -f 2);else Generic_Name[$i]="None";fi
    if [ `echo "$bob" | grep -c "Categories="` > 0 ];then Categories[$i]=$(echo "$bob" | grep "Categories=" | cut -d = -f 2);else Categories[$i]="None";fi
    if [ `echo "$bob" | grep -c "Comment="` > 0 ];then Comment[$i]=$(echo "$bob" | grep "Comment=" | cut -d = -f 2);else Comment[$i]="None";fi
    if [ `echo "$bob" | grep -c "Hidden="` > 0 ];then Hidden[$i]=$(echo "$bob" | grep "Hidden=" | cut -d = -f 2);else Hidden[$i]="None";fi
    if [ `echo "$bob" | grep -c "OnlyShowIn="` > 0 ];then OnlyShowIn[$i]=$(echo "$bob" | grep "OnlyShowIn=" | cut -d = -f 2);else OnlyShowIn[$i]="None";fi
done

}



##############################################################################
# Main
##############################################################################

find_desktop
