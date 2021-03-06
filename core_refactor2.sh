export gui=$1
clear -x
echo "These are here because I'm a lazy coder and i want an easy reference for text formatting in the menu - if you're able to read this inside the program, something is very wrong."
echo -e "\e[30mBlack Text\e[0m"
echo -e "\e[31mRed Text\e[0m"
echo -e "\e[32mGreen Text\e[0m"
echo -e "\e[33mBrown Text\e[0m"
echo -e "\e[34mBlue Text\e[0m"
echo -e "\e[35mPurple Text\e[0m"
echo -e "\e[36mCyan Text\e[0m"
echo -e "\e[37mLight Gray Text\e[0m"

echo -e "\e[1mbold\e[0m"
echo -e "\e[3mitalic\e[0m"
echo -e "\e[3m\e[1mbold italic\e[0m"
echo -e "\e[4munderline\e[0m"
echo -e "\e[9mstrikethrough\e[0m"
echo -e "\e[31mHello World\e[0m"
echo -e "\x1B[31mHello World\e[0m"
clear -x
x=1
# num_log = 0
# while [ -f "/tmp/megascript_log$num_log.txt" ]
# do
#   num_log=$((num_log + 1))
# done
# script "/tmp/megascript_log$num_log.txt"
megascript_start_time=$(date +%s)

#allow developer to set repository username and branch
#developers use export repository_username= and export repository_branch= for your own github username and branch of the L4T-Megascript
if [ -v $repository_username ] || [ $repository_username == cobalt2727 ]; then
  export repository_username=cobalt2727
else
  echo "Developer Mode Enabled! Repository = $repository_username"
fi
if [ -v $repository_branch ] || [ $repository_branch == master ]; then
  export repository_branch=master
else
  echo "Developer Mode Enabled! Branch = $repository_branch"
fi

function add_desktop {
  #create .desktop file for the megascript
  sudo rm -rf /usr/share/applications/L4T-Megascript.desktop
  sudo rm -rf /usr/share/icons/L4T-Megascript.png
  sudo curl "https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/assets/L4T_Megascript-logo-transparent.png" --output /usr/share/icons/L4T-Megascript.png
  sudo curl "https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/assets/L4T-Megascript.desktop" --output /usr/share/applications/L4T-Megascript.desktop
  sudo chmod +x '/usr/share/applications/L4T-Megascript.desktop'
}
FUNC=$(declare -f add_desktop)

dependencies=("bash" "dialog" "gnutls-bin" "curl" "zenity")
## Install dependencies if necessary
dpkg -s "${dependencies[@]}" >/dev/null 2>&1 || if [[ $gui == "gui" ]]; then
  pkexec sh -c "apt update; apt upgrade -y; apt-get install $(echo "${dependencies[@]}") -y; hash -r; $FUNC; repository_branch=$repository_branch; repository_username=$repository_username; add_desktop; hash -r"
else
  sudo sh -c "apt update; apt upgrade -y; apt-get install $(echo "${dependencies[@]}") -y; hash -r; $FUNC; repository_branch=$repository_branch; repository_username=$repository_username; add_desktop; hash -r"
fi

function install_post_depends {
  ## Check SDL2 version
  if $(dpkg --compare-versions $(dpkg-query -f='${Version}' --show libsdl2-2.0-0) lt 2.0.14); then
    echo "Installing SDL2 from binary..."
    bash -c "$(curl -s https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/scripts/sdl2_install_helper.sh)"
  fi
}

function add_desktop_if {
  test -f "/usr/share/applications/L4T-Megascript.desktop" || if [[ $gui == "gui" ]]; then
    zenity --info --width="500" --height="250" --title "Welcome!" --text "Looks like you don't have the L4T-Megascript.desktop file (the applications icon) \nPlease give your password at the prompt"
    pkexec sh -c "$FUNC; repository_branch=$repository_branch; repository_username=$repository_username; add_desktop; hash -r"
    clear -x
  else
    echo 'Looks like you do not have the L4T-Megascript.desktop file (the applications icon)'
    echo "Please give your password at the prompt"
    sudo sh -c "$FUNC; repository_branch=$repository_branch; repository_username=$repository_username; add_desktop; hash -r"
    clear -x
  fi
}
#####################################################################################

#functions used by megascript scripts

#####################################################################################

function get_system {
  # architecture is the native cpu architecture (aarch64, x86_64, etc)
  architecture="$(uname -m)"
  # jetson codename is the name reported in the DTS filename
  jetson_codename=""
  # jetson model is the friendly name that we assign
  jetson_model=""
  local __platform=""
  # if [ -f /proc/device-tree/nvidia,dtsfilename ]; then
  #     jetson_codename=$(tr -d '\0' < /proc/device-tree/nvidia,dtsfilename)
  #     jetson_codename=$(echo ${jetson_codename#*"/hardware/nvidia/platform/"} | tr '/' '\n' | head -2 | tail -1 )
  #     case "$jetson_codename" in
  #         icosa*) __platform="nintendo-switch" ;;
  #         *2180*) __platform="tx1" ;;
  #         P3310*|P3489-0080*|P3489*) __platform="tx2" ;;
  #         P2888-0006*|P2888-0001*|P2888-0004*|P2888*|P3668-0001*|P3668*) __platform="xavier" ;;
  #         P3448-0002*|P3448*) __platform="nano" ;;
  #     esac
  #     jetson_model="$__platform"
  # fi
  if [[ -e "/proc/device-tree/compatible" ]]; then
      CHIP="$(tr -d '\0' < /proc/device-tree/compatible)"
      if [[ ${CHIP} =~ "tegra186" ]]; then
          __platform="tegra-x2"
      elif [[ ${CHIP} =~ "tegra210" ]]; then
          __platform="tegra-x1"
      elif [[ ${CHIP} =~ "tegra194" ]]; then
          __platform="xavier"
      fi
      jetson_model="$__platform"
  elif [[ -e "/sys/devices/soc0/family" ]]; then
      CHIP="$(tr -d '\0' < /sys/devices/soc0/family)"
      if [[ ${CHIP} =~ "tegra20" ]]; then
          __platform="tegra-2"
      elif [[ ${CHIP} =~ "tegra30" ]]; then
          __platform="tegra-3"
      elif [[ ${CHIP} =~ "tegra114" ]]; then
          __platform="tegra-4"
      elif [[ ${CHIP} =~ "tegra124" ]]; then
          __platform="tegra-k1-32"
      elif [[ ${CHIP} =~ "tegra132" ]]; then
          __platform="tegra-k1-64"
      elif [[ ${CHIP} =~ "tegra210" ]]; then
          __platform="tegra-x1"
      fi
      jetson_model="$__platform"
  fi
  unset __platform
}
export -f get_system

# run get_system function for the refactor to use
get_system

function userinput_func {
  unset uniq_selection
  height=$(($(echo "$description" | grep -o '\\n' | wc -l) + 8))
  if [[ $gui == "gui" ]]; then
    if [[ "${#@}" == "3" ]];then
      zenity --width 500 --question \
      --text="$1" \
      --ok-label "$2" \
      --cancel-label "$3"
      if [[ $? -ne 0 ]]; then
        output="$3"
      else
        output="$2"
      fi
    else
      for string in "${@:2}"; do
        uniq_selection+=(FALSE "$string")
      done
      uniq_selection[0]=TRUE
      output=$(
        zenity \
          --text "$1" \
          --list \
          --radiolist \
          --column "" \
          --column "Selection" \
          --ok-label="OK" \
          "${uniq_selection[@]}" \
          --cancel-label "Cancel Choice"
      )
    fi
  else
    if [[ "${#@}" == "3" ]];then
      dialog --clear --yes-label "$2" --no-label "$3" --yesno "$1" "$height" "120"
      if [[ $? -ne 0 ]]; then
        output="$3"
      else
        output="$2"
      fi
    else
      for string in "${@:2}"; do
        uniq_selection+=("$string" "")
      done
      output=$(
        dialog --clear \
          --backtitle "CLI Chooser Helper" \
          --title "Choices" \
          --menu "$1" \
          "$height" "120" "$($# - 1)" \
          "${uniq_selection[@]}" \
          2>&1 >/dev/tty
      )
    fi
  fi
  status=$?
  if [[ $status = "1" ]]; then
    clear -x
    echo "Canceling Install, Back to the Megascript"
    exit 1
  fi
  clear -x
}
export -f userinput_func

#####################################################################################

#end of functions used by megascript scripts

#####################################################################################

conversion() {
  for ((i = 1; i <= ${length}; i++)); do
    if [[ ! " ${hidden[@]} " =~ " ${i} " ]]; then
      fn=""
      d=""
      e=""
      f=""
      sn=""
      selected="FALSE"
      is_root=""
      line=$(sed -n $i"p" <"/tmp/megascript_apps.txt")
      if [[ "$line" != \#* ]]; then
        eval "$(echo "$line" | tr ";" "\n")"
        scripts[$i]=$sn
        if [ "$f" = "scripts" ]; then
          folder[$i]=$f
        else
          folder[$i]="scripts/$f"
        fi
        execute[$i]=$e
        root[$i]=$is_root
        if [[ $gui == "gui" ]]; then
          ids+=($f)
          declare -n current_table=table_$f
          f="$(echo "$f" | sed -e 's/_/ /g' | sed -e "s/\b\(.\)/\u\1/g")"
          current_table+=($selected $i "$fn" "$d")
          unset -n current_table
          table_all_categories+=($selected $i "$f" "$fn" "$d")
        else
          ff="$(echo "$f" | sed -e 's/_/ /g' | sed -e "s/\b\(.\)/\u\1/g")"
          echo "$i...............$ff - $fn - $d"
        fi
      fi
    fi
  done
}
# force reload programs list
hash -r
hidden=()
rm -rf /tmp/megascript_apps.txt
wget https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/megascript_apps.txt -O /tmp/megascript_apps.txt
sed -i '/^$/d' /tmp/megascript_apps.txt
length=$(wc -l "/tmp/megascript_apps.txt" | awk '{ print $1 }')

while [ $x == 1 ]; do
  cd ~
  available_space=$(df -PH . | awk 'NR==2 {print $4"B"}')
  clear -x
  table=()
  scripts=()
  folder=()
  execute=()
  ids=()
  if [[ $gui == "gui" ]]; then
    zenity --info --width="500" --height="250" --title "Welcome!" --text "Welcome back to the main menu of the L4T Megascript, $USER. This isn't quite finished yet - we'll be ready eventually! \n\nAdd a check from the choices in the GUI and then press INSTALL to configure the specified program." --window-icon=/usr/share/icons/L4T-Megascript.png
    zenity --warning --width="500" --height="250" --title "Welcome!" --text "You have $available_space of space left on your SD card! Make sure you don't use too much! \
    \n\n\You are running an $architecture $jetson_model system." --window-icon=/usr/share/icons/L4T-Megascript.png
    free=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    divisor="1024000"
    free_gb=$(echo "scale=2 ; $free / $divisor" | bc)
    if [[ $free -lt 2048000 ]]; then
      zenity --warning --width="500" --height="250" --title "Welcome!" --text "You have only $free_gb GB of free ram! \
      \n\n\Please consider closing out of any unnecessary programs before starting the megascript." --window-icon=/usr/share/icons/L4T-Megascript.png
    fi
    add_desktop_if
    conversion
    uniq_selection=()
    CHOICE=""
    uniq=($(printf "%s\n" "${ids[@]}" | sort -u))
    for string in "${uniq[@]}"; do
      pretty_string="$(echo "$string" | sed -e 's/_/ /g' | sed -e "s/\b\(.\)/\u\1/g")"
      uniq_selection+=(FALSE " $pretty_string" "$string")
    done
    uniq_selection+=(TRUE "All Categories" "all_categories")
    while [ "$CHOICE" == "Go Back to Categories" -o "$CHOICE" == "" ]; do
      CATEGORY=$(
        zenity \
          --width="250" \
          --height="350" \
          --title "Welcome to the L4T-Megascript" \
          --text "Please Choose a Scripts Category" \
          --window-icon=/usr/share/icons/L4T-Megascript.png \
          --list \
          --radiolist \
          --column "Selection" \
          --column "Category" \
          --column "Real Folder" \
          --hide-column=3 \
          --print-column=3 \
          "${uniq_selection[@]}" \
          --cancel-label "Exit the Megascript" \
          --ok-label "Go to Selection"
      )
      if [ "$?" != 1 ]; then
        category_space="$(echo "$CATEGORY" | sed -e 's/_/ /g' | sed -e "s/\b\(.\)/\u\1/g")"
        declare -n current_table="table_$CATEGORY"
        if [ "$CATEGORY" == "all_categories" ]; then
          CHOICE=$(
            zenity \
              --width="1000" \
              --height="500" \
              --title "$category_space" \
              --text "Please Select the Desired Programs to Install" \
              --window-icon=/usr/share/icons/L4T-Megascript.png \
              --list \
              --checklist \
              --column "Install" \
              --column "Number" \
              --column "Category" \
              --column "Program" \
              --column "Details" \
              --ok-label="INSTALL" \
              --hide-column=2 \
              "${current_table[@]}" \
              --separator=':' \
              --cancel-label "Exit the Megascript" \
              --extra-button "Go Back to Categories"
          )
        else
          CHOICE=$(
            zenity \
              --width="1000" \
              --height="500" \
              --title "$category_space" \
              --text "Please Select the Desired Programs to Install" \
              --window-icon=/usr/share/icons/L4T-Megascript.png \
              --list \
              --checklist \
              --column "Install" \
              --column "Number" \
              --column "Program" \
              --column "Details" \
              --ok-label="INSTALL" \
              --hide-column=2 \
              "${current_table[@]}" \
              --separator=':' \
              --cancel-label "Exit the Megascript" \
              --extra-button "Go Back to Categories"
          )
        fi
        if [ "$?" != 1 ]; then
          sudo -k
          state="0"
          while [ "$state" == "0" ]; do
            zenity --password | sudo -S echo "" 2>&1 >/dev/null | grep -q "incorrect"
            state=$?
          done
        elif [ "$CHOICE" == "Go Back to Categories" ]; then
          echo ""
        else
          CHOICE="exit"
        fi
        unset -n current_table
      else
        CHOICE="exit"
      fi
    done
    x=0
  else
    free=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    divisor="1024000"
    free_gb=$(echo "scale=2 ; $free / $divisor" | bc)
    if [[ $free -lt 2048000 ]]; then
      echo "You have only $free_gb GB of free ram!"
      echo "Please consider closing out of any unnecessary programs before starting the megascript."
      sleep 4
    fi
    echo "Welcome back to the main menu of the L4T Megascript, $USER. This isn't quite finished yet - we'll be ready eventually!"
    echo
    add_desktop_if
    echo -e "\x1B[31mYou have about $available_space of space left on your Linux installation! Make sure you don't use too much!\e[0m"
    echo "You are running an $architecture $jetson_model system."
    echo ""
    echo "Enter a number from the choices below and then press ENTER to configure the specified program."

    sleep 2
    echo
    conversion
    echo "X...............Close L4T Megascript, view credits and source code, and get Discord support server link"
    echo
    echo
    read -p "Make a selection: " CHOICE
    if [[ $CHOICE == x || $CHOICE == X || $CHOICE == exit || $CHOICE == Exit ]]; then
      x=0
      continue
    else
      sudo -S echo ""
    fi

    echo "you have chosen $CHOICE"

  fi
  # https://unix.stackexchange.com/questions/261103/how-do-i-maintain-sudo-in-a-bash-script
  # initialize sudo password and extent timeout so we never run out
  IFS=":"
  if sudo -n true; then
    while true; do
      sleep 60
      sudo -v
      kill -0 "$$" 2>/dev/null || exit
    done &
    sudo apt update
    if [[ $? -ne 0 ]]; then
      # fix for error (for some reason was never pulled into bionic...)
      # http://launchpadlibrarian.net/384348932/appstream_0.12.2-1_0.12.2-2.diff.gz patch is seen at the bottom here
      # E: Problem executing scripts APT::Update::Post-Invoke-Success 'if /usr/bin/test -w /var/cache/app-info -a -e /usr/bin/appstreamcli; then appstreamcli refresh > /dev/null; fi'
      # https://askubuntu.com/questions/942895/e-problem-executing-scripts-aptupdatepost-invoke-success
      sudo sed -i 's%/dev/null;%/dev/null \| true;%g' /etc/apt/apt.conf.d/50appstream
      sudo apt update
    fi
    install_post_depends
    rm -rf /tmp/megascript_times.txt
    for word in $CHOICE; do
      time_script_start=$(date +%s)
      if [ -z ${execute[$word]} ]; then
        if [ -z ${root[$word]} ]; then
          bash -c "$(curl -s https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/${folder[$word]}/${scripts[$word]})"
        else
          sudo -E bash -c "$(curl -s https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/${folder[$word]}/${scripts[$word]})"
        fi
        time_script_stop=$(date +%s)
        time_elapsed=$(echo "$time_script_stop - $time_script_start" | bc)
        time_elapsed_friendly=$(eval "echo $(date -ud "@$time_elapsed" +'$((%s/3600/24)) days %H hours %M minutes %S seconds')")
        echo "${scripts[$word]} took $time_elapsed_friendly" >> /tmp/megascript_times.txt        
      else
        # this is legacy use, no current scripts use this function
        eval "${execute[$word]}"
        time_script_stop=$(date +%s)
        time_elapsed=$(echo "$time_script_stop - $time_script_start" | bc)
        time_elapsed_friendly=$(eval "echo $(date -ud "@$time_elapsed" +'$((%s/3600/24)) days %H hours %M minutes %S seconds')")
        echo "${execute[$word]} took $time_elapsed_friendly" >> /tmp/megascript_times.txt  
      fi
    done
  fi
done

if sudo -n true; then
  add_desktop
else
  echo "didn't add the L4T-Megascript.desktop file, sudo timer ran out"
fi

megascript_end_time=$(date +%s)
megascript_elapsed=$(echo "$megascript_end_time - $megascript_start_time" | bc)
megascript_elapsed_friendly=$(eval "echo $(date -ud "@$megascript_elapsed" +'$((%s/3600/24)) days %H hours %M minutes %S seconds')")

if [[ $gui == "gui" ]]; then
  zenity --info --width="500" --height="250" --title "Bye" --text "Thank you for using the L4T Megascript!\n\nCredits:\nCobalt - Manager/Lead Dev\nGman - Developer/GUI and CLI Management/RetroPie/Minecraft Handler\nLugsole - Contributor/GUI Manager\nLang Kasempo - Contributor/Beta Tester/did a lot of the standalone game scripts\n\nthe Switchroot L4T Ubuntu team (https://switchroot.org/) - making the actual OS you're running right now\n\nThe Megascript ran for $megascript_elapsed_friendly" --window-icon=/usr/share/icons/L4T-Megascript.png
  clear -x
else
  echo "Thank you for using the L4T Megascript!"
  sleep 2
  clear -x
  echo "Credits:"
  echo "CTRL + CLICK ON A LINK TO OPEN IT"
  echo
  echo -e "\e[38;2;0;71;171mCobalt - Manager/Lead Dev/Benevolent Dictator\e[0m"
  echo -e "\e[32mGman - Developer/GUI and CLI Management/RetroPie/Minecraft Handler\e[0m" 
  echo -e "\e[38;2;$(shuf -i 0-255 -n 1);$(shuf -i 0-255 -n 1);$(shuf -i 0-255 -n 1)mLugsole - Contributor\e[0m"
  echo -e "\e[35mLang Kasempo - Contributor/Beta Tester\e[0m"

  echo -e "All the contributors and beta testers that put up with Cobalt pinging them incessantly"
  #echo "hey, if you're reading this, odds are you probably helped make the thing. you can add your name to the credits in your PRs!"
  echo "the Switchroot L4T Ubuntu team (https://switchroot.org/) - making the actual OS you're running right now"
  echo ""
  echo "The Megascript ran for $megascript_elapsed_friendly"
fi
unset repository_username
unset repository_branch
unset gui

echo ""
echo -e 'Thank you for using the L4T Megascript! Stop by our \e[36mDiscord\e[0m server at [link not public yet] for support.'
echo 'Source code is available here: https://github.com/cobalt2727/L4T-Megascript/'

# #stop logging
# exit
