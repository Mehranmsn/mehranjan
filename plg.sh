#!/bin/bash

arwpqf() {
    local WP=(wp1 wp2 wp3)
    local subd=(sub1 sub2 sub3)
    local dom=(domain1.com domain2.com domain3.com)
    local customsubd=(csub1 csub2 csub3)
    local customdom=(cdomain1.com cdomain2.com cdomain3.com)
    local webroot=$(pwd)

    if [ "$1" == "cfg" ]; then
        echo -e "\n\033[1m\033[4mDEFAULT PATHS\033[0m"
        for i in "${!WP[@]}"; do
            echo -e "${WP[$i]}\t-> https://${subd[$i]}.${dom[$i]}"
        done

        echo -e "\n\033[1m\033[4mCUSTOM PATHS\033[0m"
        for i in "${!customsubd[@]}"; do
            echo -e "${customsubd[$i]}\t-> https://${customsubd[$i]}.${customdom[$i]}"
        done

    elif [ "$1" == "go" ]; then
        if [[ "$webroot" == *"/public_html/wp"* ]]; then
            local folder_name=$(basename "$webroot")
            for i in "${!WP[@]}"; do
                if [[ "${WP[$i]}" == "$folder_name" ]]; then
                    echo "https://${subd[$i]}.${dom[$i]}"
                    return
                fi
            done
        else
            local folder_name=$(basename "$webroot")
            for i in "${!customsubd[@]}"; do
                if [[ "${customsubd[$i]}" == "$folder_name" ]]; then
                    echo "https://${customsubd[$i]}.${customdom[$i]}"
                    return
                fi
            done
        fi
    else
        echo "Usage:"
        echo "  $0 cfg   # نمایش تنظیمات دامنه‌ها"
        echo "  $0 go    # تولید URL براساس پوشه جاری"
    fi
}
