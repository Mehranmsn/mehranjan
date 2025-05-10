arwpqf() {
  local op_name=()
  local op_value=()
  if [[ -f wp-config.php ]]; then
    IFS=$'\n' read -r -d '' -a web_db < <( awk 'BEGIN{i=0;} match($0,/(define\()? *['\''"\$](DB_NAME|DB_USER|DB_PASSWORD|table_prefix)['\''"]? *[,=] *['\''"](.+)['\''"] *\)?;/,arr) { webdb[arr[2]] = arr[3]; i++;}; {if (i == 4) { printf "%s\n%s\n%s\n%s\n",webdb["DB_NAME"],webdb["DB_USER"],webdb["DB_PASSWORD"],webdb["table_prefix"]; exit 1;}}' wp-config.php && printf '\0' )
  else
    echo "no wp-config"
    return 1
  fi

  getdata() {
    local sqldata=()
    IFS=$'\n' read -r -d '' -a sqldata < <( mysql -u"${web_db[1]}" -p"${web_db[2]}" -D"${web_db[0]}" -e "SELECT option_value FROM ${web_db[3]}options WHERE option_name REGEXP \"$1\";" -N -s )
    echo "${sqldata[@]}"
  }

  setdata() {
    [ "$1" = sd_name ] || local -n sd_name=$1
    [ "$2" = sd_value ] || local -n sd_value=$2
    local query_str=""
    for o in "${!sd_name[@]}"; do
      # Escape کردن مقادیر برای جلوگیری از SQL injection
      local escaped_value=$(printf '%q' "${sd_value[$o]}")
      query_str+="('${sd_name[$o]}','${escaped_value}')"
      if (( o < ${#sd_name[@]} - 1 )); then query_str+=","; fi
    done
    mysql -u"${web_db[1]}" -p"${web_db[2]}" -D"${web_db[0]}" -e "INSERT INTO ${web_db[3]}options (option_name,option_value) VALUES ${query_str} ON DUPLICATE KEY UPDATE option_value = VALUES(option_value);"
    return $?
  }

  changeplg() {
    [ "$2" = lists ] || local -n lists=$2
    [ "$3" = revlist ] || local -n revlist=$3
    local newplgstr="${plg_string}"
    until
      read -ep "which plugins do you want to $1: press any key not in number range for quit:  " choice
      [[ $choice =~ ^[0-9a-zA-Z]+$ ]]
      case $choice in
        [0-9,]*)
          IFS=',' read -ra choices <<< "$choice"
          if [[ ${#choices[@]} > 0 ]]; then
            for c in "${choices[@]}"; do
              if [[ -z ${lists[$c]+x} ]]; then
                echo "not in list"
                break 2
              fi
              local chplg=$(awk -v plgname="${lists[$c]}" 'BEGIN{printf "%s", gensub(/^"(.+)"$/,"\\1",1,plgname)}')
              if [[ $1 = "disable" ]]; then
                newplgstr=${newplgstr//"${chplg}"}
              elif [[ $1 = "enable" ]]; then
                newplgstr=$(awk -v plgstr="${newplgstr}" -v newplg="${chplg}" 'BEGIN{ plgnextnum = gensub(/^i:([0-9]+);.+/,"\\1",1,newplg); pos = index(plgstr,"i:" (plgnextnum) + 1 ";"); if (pos > 0) {print substr(plgstr,1,pos - 1) newplg substr(plgstr,pos, length(plgstr) - pos + 1);} else {print substr(plgstr,1, length(plgstr) - 1) newplg "}";}}')
              fi
            done
            newplgstr=$(awk -v op="$1" -v selcount="${#choices[@]}" -v plgcount="${#lists[@]}" -v plgstr="${newplgstr}" 'BEGIN{if (op == "enable") {total=(gensub(/^a:([0-9]+).+/,"\\1",1,plgstr)) + selcount;} else {total=(plgcount - selcount);} print gensub(/^a:[0-9]+:(.+)$/,"a:" total ":\\1",1,plgstr);}')
            local cp_name=("active_plugins")
            local cp_value=("$newplgstr")
            if setdata cp_name cp_value; then
              for p in "${choices[@]}"; do
                revlist[$p]=${lists[$p]}
                unset "$2[$p]"
              done
              plg_string=${newplgstr}
            else
              echo "failed"
            fi
            break
          fi
          ;;
        *)
          echo "exiting"
          break
          ;;
      esac
    do
      :
    done
  }

  case $1 in
    "cfg")
      echo -e "Current Wordpress Configuration:\n\tDatabase name:\t\t${web_db[0]}\n\tDatabase username:\t${web_db[1]}\n\tDatabase password:\t${web_db[2]}\n\tTable prefix:\t\t${web_db[3]}"
      ;;
    "home")
      local home_data=()
      if [[ "${#home_data[@]}" = 0 ]]; then
        home_data=($(getdata "^(home|siteurl)$"))
      fi
      case $2 in
        "set")
          if [ -z "$3" ]; then
            echo "third arg must be set"
          else
            op_name=("home" "siteurl")
            op_value=("$3" "$3")
            if setdata op_name op_value; then
              echo -e "home address:\t\t$3\nsite address:\t\t$3"
              home_data=("${op_value[0]}" "${op_value[1]}")
            else
              echo "failed to set home/siteurl"
            fi
          fi
          ;;
        *)
          echo -e "home address:\t\t${home_data[0]}\nsite address:\t\t${home_data[1]}"
          ;;
      esac
      ;;
  esac
}
