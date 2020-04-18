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
# Find duplicate names and executables
##############################################################################

function find_duplicates() {

#May want to take out the Generic Name and TryExec, at least at first
    
    for ((i = 0; i < ${#uniq_launchers[@]}; i++));do
        MatchString=${Name[$i]}
        if [ "$MatchString" != "None" ];then
            for ((i2 = 0; i2 < ${#uniq_launchers[@]}; i2++));do
                if [ $i2 != $i ];then 
                    if [[ "$MatchString" =~ ${Name[$i2]} ]];then   #Think I remembered the syntax rightly.
                        ${NameDupe[$i]}++
                    fi
                fi
            done
            
            for ((i2 = 0; i2 < ${#uniq_launchers[@]}; i2++));do
                if [ $i2 != $i ];then 
                    if [[ "$MatchString" =~ ${Generic_Name[$i2]} ]];then   #Think I remembered the syntax rightly.
###THIS DOES NOT WORK
####MAKE AN ARRAY OF EACH WITH THE VALUE BEING THE INDEX ON THE OTHER ARRAY  ARRAY=()
#ARRAY+=('foo')
#ARRAY+=('bar')                        ${NameDupe[$i]}++
                    fi
                fi
            done
        fi

        MatchString=${Exec[$i]}
        if [ "$MatchString" != "None" ];then
            for ((i2 = 0; i2 < ${#uniq_launchers[@]}; i2++));do
                if [ $i2 != $i ];then 
                    if [[ "$MatchString" =~ ${Exec[$i2]} ]];then   #Think I remembered the syntax rightly.
                        ${ExecDupe[$i]}++
                    fi
                fi
            done
            for ((i2 = 0; i2 < ${#uniq_launchers[@]}; i2++));do
                if [ $i2 != $i ];then 
                    if [[ "$MatchString" =~ ${TryExec[$i2]} ]];then   #Think I remembered the syntax rightly.
                        ${ExecDupe[$i]}++
                    fi
                fi
            done
        fi
    done    
    
    #The idea here is that you can then scroll through NameDupe and ExecDupe arrays and find matches and duplicates because match number will be -gt 1
    
    for ((i = 0; i < ${#uniq_launchers[@]}; i++));do
        if [ ${NameDupe[$i]} -gt 0 ];then
            printf "Duplicate name %s \nin file %s" "${Name[$i]}" "${#uniq_launchers[$i]}"
        fi
        if [ ${ExecDupe[$i]} -gt 0 ];then
            printf "Duplicate exec string %s \nin file %s" "${Exec[$i]}" "${#uniq_launchers[$i]}"
        fi
    done
}

function find_bad (){
    for ((i = 0; i < ${#uniq_launchers[@]}; i++));do
        echo "whoops" > /dev/null
        #Turn ${Exec[$i]} into full pathname (readlink, iirc)
        #[ ! -f ${Exec[$i]} ]
        #if does not exist
            #which ${TryExec[$i]}
                #if does not exist, output filename
                #"/home/steven/.cxoffice/Steam/desktopdata/cxmenu/Desktop.C^5E3A_users_crossover_Desktop/Bit+Odyssey.url" %u
                #/home/steven/apps/dbgl/DOSBox-0.74/dosbox -conf "/home/steven/apps/dbgl/DOSBox-0.74/dosbox.conf" -conf "/home/steven/apps/dbgl/profiles/8.conf"
                #/home/steven/apps/MultiMC/MultiMC
                #steam steam://rungameid/563560
                #env WINEPREFIX="/home/steven/Games/PvZ" /home/ubuntu/buildbot/runners/wine/lutris-4.21-x86_64/bin/wine C:\\\\windows\\\\command\\\\start.exe /Unix /home/steven/Games/PvZ/dosdevices/c:/ProgramData/Microsoft/Windows/Start\\ Menu/Programs/PopCap\\ Games/Plants\\ vs.\\ Zombies/Play\\ Plants\\ vs.\\ Zombies.lnk
                
    done
}


##############################################################################
# Main
##############################################################################

find_desktop

# NEED TO PUT IN SOMETHING TO HANDLE THINGS LIKE THIS:
#[Desktop Action Remove]
# in .desktop files

find_duplicates

#not working/existing desktop files
find_bad
