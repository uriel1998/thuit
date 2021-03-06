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

CXRAW=0
NAMES=0
EXEC=0
FILEOUT=0
OUTFILE=""

##############################################################################
# Progress bar
# From https://github.com/fearside/ProgressBar/
##############################################################################

function ProgressBar {
# Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
# Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:                           
# 1.2.1.1 Progress : [########################################] 100%
printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"

}

##############################################################################
# Find .desktop files in standard locations
##############################################################################

function find_desktop() {
    
    # Use XDG data if possible
    #directory_array=( $(echo $XDG_DATA_DIRS | sed  's/:/\/applications\n/g') )
    # Other ones I found on my system that aren't in XDG data dirs for some reason

    directory_array+=( $(if [ -d ~/desktop ];then realpath ~/desktop;fi) )
    directory_array+=( $(if [ -d ~/Desktop ];then realpath ~/Desktop;fi) )
    #directory_array+=( $(if [ -d ~/.gnome/apps ];then realpath ~/.gnome/apps;fi) )
    #directory_array+=( $(if [ -d ~/.local/share/applications ];then realpath ~/.local/share/applications;fi) )
    #directory_array+=( $(if [ -d /usr/share/applications ];then echo "/usr/share/applications";fi) )
    #directory_array+=( $(if [ -d /usr/local/share/applications ];then echo "/usr/local/share/applications";fi) )
    #directory_array+=( $(if [ -d /usr/share/gdm/applications ];then echo "/usr/share/gdm/applications";fi) )
    #directory_array+=( $(if [ -d /usr/share/applications/kde ];then echo "/usr/share/applications/kde";fi) )

    # I am tempted to put /etc/xdg/autostart and ~/.config/autostart in here, but those 
    # have some special things that I'd like to avoid...

    # Obtain *.desktop files from linux directories
    for i in "${directory_array[@]}"; do
        IFS=$(echo -en "\n\b")
        launcher_array+=( $(find "${i}" -type f -iname "*.desktop") )
    done

    # Finding crossover desktop files
    if [ $CXRAW = 1 ];then
        crossoverpath=$(realpath ~/.cxoffice)
        if [ -d "$crossoverpath" ];then
            IFS=$(echo -en "\n\b")
            launcher_array+=( $(find "$crossoverpath" -type d -iname "Launchers" -exec find '{}' -type f -iname "*.desktop" \;) )
        fi
    fi

    # So here's all the .desktop files we've found, sorting them out  
    for ((i = 0; i < ${#launcher_array[@]}; i++));do
        printf "%s\n" "${launcher_array[$i]}"  >> "$tmpfile"
    done

    # Hacky way to remove duplicates, but hey.
    # Also removing wine-extension desktop files, as they cause massive false
    # duplicates
    cat "$tmpfile" | grep -v "wine-extension" | sort -u > "$tmpfile2"
    uniq_launchers=( $(cat "$tmpfile2" | sort -u) )

    echo "There are ${#uniq_launchers[@]} desktop files to examine."
    
    echo "Reading in file data:"
    for ((i = 0; i < ${#uniq_launchers[@]}; i++));do
        ProgressBar $i ${#uniq_launchers[@]}
        bob=$(cat ${uniq_launchers[$i]}) 
        if [[ `echo "$bob" | grep -c -e "^Type="` > 0 ]];then Type[$i]=$(echo "$bob" | grep -e "^Type=" | cut -d = -f 2- );else Type[$i]="None";fi
        if [[ `echo "$bob" | grep -c -e "^Icon="` > 0 ]];then Icon[$i]=$(echo "$bob" | grep -e "^Icon=" | cut -d = -f 2- );else Icon[$i]="None";fi    
        if [[ `echo "$bob" | grep -c -e "^Exec="` > 0 ]];then Exec[$i]=$(echo "$bob" | grep -e "^Exec=" | cut -d = -f 2- );else Exec[$i]="None";fi
        if [[ `echo "$bob" | grep -c -e "^TryExec="` > 0 ]];then TryExec[$i]=$(echo "$bob" | grep -e "^TryExec=" | cut -d = -f 2- );else TryExec[$i]="None";fi
        if [[ `echo "$bob" | grep -c -e "^Name="` > 0 ]];then Name[$i]=$(echo "$bob" | grep -e "^Name=" | cut -d = -f 2- );else Name[$i]="None";fi
        if [[ `echo "$bob" | grep -c -e "^GenericName="` > 0 ]];then GenericName[$i]=$(echo "$bob" | grep -e "^GenericName=" | cut -d = -f 2- );else GenericName[$i]="None";fi
        if [[ `echo "$bob" | grep -c -e "^Categories="` > 0 ]];then Categories[$i]=$(echo "$bob" | grep -e "^Categories=" | cut -d = -f 2- );else Categories[$i]="None";fi
        if [[ `echo "$bob" | grep -c -e "^Comment="` > 0 ]];then Comment[$i]=$(echo "$bob" | grep -e "^Comment=" | cut -d = -f 2- );else Comment[$i]="None";fi
        if [[ `echo "$bob" | grep -c -e "^Hidden="` > 0 ]];then Hidden[$i]=$(echo "$bob" | grep -e "^Hidden=" | cut -d = -f 2- );else Hidden[$i]="None";fi
        if [[ `echo "$bob" | grep -c -e "^OnlyShowIn="` > 0 ]];then OnlyShowIn[$i]=$(echo "$bob" | grep -e "^OnlyShowIn=" | cut -d = -f 2- );else OnlyShowIn[$i]="None";fi
    done

    rm $tmpfile
    rm $tmpfile2
}



function find_missing_categories() {
    
    
    for ((i = 0; i < ${#uniq_launchers[@]}; i++));do
        ProgressBar $i ${#uniq_launchers[@]}
        if [[ "${Categories[$i]}" = "" ]] || [[ "${Categories[$i]}" = "None" ]];then
            if [ "$FILEOUT" = "1" ];then
                printf "\nNo category for %s in file\n%s\n" "${Name[$i]}" "${uniq_launchers[$i]}" >> "$OUTFILE"
            else
                printf "\nNo category for %s in file\n%s\n" "${Name[$i]}" "${uniq_launchers[$i]}"
            fi
        fi
        
    done
}

##############################################################################
# Find duplicate names and executables
##############################################################################

function find_duplicates() {

    
#May want to take out the Generic Name and TryExec, at least at first
    
    for ((i = 0; i < ${#uniq_launchers[@]}; i++));do
        ProgressBar $i ${#uniq_launchers[@]}
        
        if [ $NAMES = 1 ];then
            MatchString=${Name[$i]}
            if [ "$MatchString" != "None" ];then
                for ((i2 = 0; i2 < ${#uniq_launchers[@]}; i2++));do
                    if [ $i2 != $i ];then 
                        if [[ "$MatchString" == "${Name[$i2]}" ]];then   #Think I remembered the syntax rightly.
                            NameDupe+=("$i $i2")
                        fi
                    fi
                done
            fi
        fi
    
        if [ $EXEC = 1 ];then 
            MatchString=${Exec[$i]}
            if [ "$MatchString" != "None" ];then
                for ((i2 = 0; i2 < ${#uniq_launchers[@]}; i2++));do
                    if [ $i2 != $i ];then 
                        if [[ "$MatchString" == "${Exec[$i2]}" ]];then   #Think I remembered the syntax rightly.
                            ExecDupe+=("$i $i2")
                        fi
                    fi
                done
            fi
        fi
    done    
    
    #The idea here is that you can then scroll through NameDupe and ExecDupe arrays and find matches and duplicates because match number will be -gt 1
    if [ $NAMES = 1 ];then
        for ((i = 0; i < ${#NameDupe[@]}; i++));do
            one=$(echo "${NameDupe[$i]}" | awk '{print $1}')
            two=$(echo "${NameDupe[$i]}" | awk '{print $2}')
            if [ $FILEOUT =1 ];then
                printf "Duplicate name %s in files \n%s and \n%s\n\n" "${Name[$one]}" "${uniq_launchers[$one]}" "${uniq_launchers[$two]}" >> "$OUTFILE"
            else
                printf "Duplicate name %s in files \n%s and \n%s\n\n" "${Name[$one]}" "${uniq_launchers[$one]}" "${uniq_launchers[$two]}" 
            fi
        done
    fi
    if [ $EXEC = 1 ];then
    
        for ((i = 0; i < ${#ExecDupe[@]}; i++));do
            one=$(echo "${ExecDupe[$i]}" | awk '{print $1}')
            two=$(echo "${ExecDupe[$i]}" | awk '{print $2}')
            if [ $FILEOUT =1 ];then
                printf "Duplicate executable %s in files \n%s and \n%s\n\n" "${Exec[$one]}" "${uniq_launchers[$one]}" "${uniq_launchers[$two]}" >> "$OUTFILE"
            else
                printf "Duplicate executable %s in files \n%s and \n%s\n\n" "${Exec[$one]}" "${uniq_launchers[$one]}" "${uniq_launchers[$two]}" 
            fi
        done
    fi


}

function find_bad (){
    for ((i = 0; i < ${#uniq_launchers[@]}; i++));do
        
        
        # I know already this is going to fail on some, because of this\ convention\ 
        
        PartsOfExec=$(echo "${Exec[$i]}" | awk -F ' ' '{print NF1}')
        
        
        #Splitting Exec string into an array
        read -r -a TestExec <<< "${Exec[$i]}"
        
     
                # Crossover - does the first thing (before the %u) exist?
                
                
                
                
                #-probably best way (game id is at end of filename)
                #/home/steven/.steam/steam/steamapps/appmanifest_563560.acf
                #- could try looking in here, but holy fuckballs
                #/home/steven/.steam/steam/userdata/58476723/563560/
                
                #1. Find /Unix
                #2. Convert all \\ to \
                #3. Run as with crossover above
                #env WINEPREFIX="/home/steven/Games/PvZ" /home/ubuntu/buildbot/runners/wine/lutris-4.21-x86_64/bin/wine C:\\\\windows\\\\command\\\\start.exe /Unix /home/steven/Games/PvZ/dosdevices/c:/ProgramData/Microsoft/Windows/Start\\ Menu/Programs/PopCap\\ Games/Plants\\ vs.\\ Zombies/Play\\ Plants\\ vs.\\ Zombies.lnk
        #iterating over each part of the exec string so that we can handle complex
        #situations more easily.
        for part in "${TestExec[@]}"; do
        
            case "$part" in 
    
                #This may no longer be needed either...
                *cxoffice*)
                    TestExec=$(printf "%s" "${Exec[$i]}" | cut -d \" -f 2)
                    ;;
                
                #if dosbox, check each conf file
                #/home/steven/apps/dbgl/DOSBox-0.74/dosbox -conf "/home/steven/apps/dbgl/DOSBox-0.74/dosbox.conf" -conf "/home/steven/apps/dbgl/profiles/8.conf"
                *dosbox*) # this might be unneeded due to teh separation out
                    ;;
                *bash *)
                    ;;
                *'"'*)  #in case this might be better to do as an array of % and $
                    ;;
                
                ^--*)#might not be right syntax, basically stripping off any options
                    ;;
                ^-*)  #might not be right syntax, basically stripping off any options
                    ;;
                ^steam)
                    #test if just the word steam
                    ;;
                ^steam:*)
                    #steamgame argument
                    ;;
                    
                    
                    
                    
                    
                    
                #/home/steven/apps/dbgl/DOSBox-0.74/dosbox -conf "/home/steven/apps/dbgl/DOSBox-0.74/dosbox.conf" -conf "/home/steven/apps/dbgl/profiles/8.conf"

        
                #/home/steven/apps/MultiMC/MultiMC
            TestExec=$(printf "%s" "${Exec[$i]}" | cut -d \" -f 2)
        
        
        done

TABS=$(echo "$line" | awk -F ' '  )

        

   
        #Does it contain dosbox?
        
        #Does it contain steam?


        #Does it contain wineprefix


        #does is it enclosed in quotes with %u at the end or somesuch:


        #Is it "regular"?




        
        if [ ! -f "$TestExec" ];then
                BadExec+=("$i")
        fi
        
  
                
                
    done
    
    
    #Display results
    printf "\n\n"
    for ((i = 0; i < ${#BadExec[@]}; i++));do
            one=$(echo "${BadExec[$i]}" | awk '{print $1}')
            two=$(echo "${NameDupe[$i]}" | awk '{print $2}')
            if [ $FILEOUT = 1 ];then
                printf "Bad Exec name \n%s in file \n%s \n\n" "${Exec[$one]}" "${uniq_launchers[$one]}"  >> "$OUTFILE"
            else
                 printf "Bad Exec name \n%s in file \n%s \n\n" "${Exec[$one]}" "${uniq_launchers[$one]}"  
            fi
        done
}

##############################################################################
# Show help on cli
##############################################################################

display_help() {
	echo "usage: thuit.sh [-h][-n][-e][-b][-x][-c]"
	echo " "
	echo "optional arguments:"
	echo "   -h     show this help message and exit"
    echo "   -n     Parse for name duplicates"
    echo "   -e     Parse for exec duplicates"
    echo "   -b     Parse for bad desktop files"
    echo "   -c     Parse for missing Categories"    
	echo "   -x     Parse Crossover desktop files inside .cxoffice"    
    echo "   -f     Output to $file"
}

# for menus https://serverfault.com/questions/144939/multi-select-menu-in-bash-script

##############################################################################
# Main
##############################################################################

##############################################################################
# Command line options
##############################################################################

while [ $# -gt 0 ]; do
option="$1"
    case $option
    in
    -h) display_help
        exit
        shift 
        ;;        
    -f) FILEOUT=1
        shift
        OUTFILE="$1"
        shift 
        echo "File output to $OUTFILE"
        ;;        
    -c) CATEGORIES=1
        echo "Parsing for missing categories"
        shift
        ;;
    -x) CXRAW=1
        echo "Parsing raw Crossover files."
        shift 
        ;;        
    -n) NAMES=1
        echo "Looking for name duplicates"
        shift 
        ;;      
    -e) EXEC=1
        echo "Looking for exec duplicates"
        shift 
        ;;      
    -b) BAD=1
        echo "Looking for bad desktop files"
        shift 
        ;;      
    esac
done

find_desktop

# NEED TO PUT IN SOMETHING TO HANDLE THINGS LIKE THIS:
#[Desktop Action Remove]
# in .desktop files

# add in "if NAMES or EXEC is positive, do this.
if [ "$NAMES" = "1" ];then
    echo -e "\n"
    echo "Analyzing for duplicates now."
    find_duplicates
fi
if [ "$CATEGORIES" = "1" ];then
    echo -e "\n"
    echo "Analyzing for missing categories now."
    find_missing_categories
fi
find_bad

#not working/existing desktop files
#find_bad
