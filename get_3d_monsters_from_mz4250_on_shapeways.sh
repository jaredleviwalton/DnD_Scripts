#!/bin/bash


# This will download all the files that user "mz4250" has on his shapeways account
# Possible bugs:
#   1. It will choke if it's not able to download something due to it not being free to download... I think, I might fix that at some point
# 
#
# Rough how to:
# If you have access to a linux or unix computer this script should work 
# (I wrote and used this on my windows PC with cygwin). 
# But you might need to install "unzip" and "wget"; how to do this will vary depending on distro.
# If you have a windows system, I'd recommend installing cygwin, be sure to search for, and select/check, "unzip" and "wget" when selecting packages to install.
# Once you download the script you'll want to update some code:
# 1. for lines 2 and 3 you'll want enter your shapeways user name and password in place of "YOUR_USERNAME" and "YOUR_PASSWORD". 
# It's important to note if you log-in to shapeways via google, you'll need to change how you login by selecting "Shapeways username and password" 
# on https://www.shapeways.com/settings/account. It's probably the same with facebook...
# 2. You'll probably want to delete lines 10 and 11, the ones with export proxy stuff. It's not likely your behind a proxy.
# 3. Now save the file and run it!
# 4. To run the script open up a console (or cygwin), navigate to where you saved the file (for cygwin something like "cd /cygdrive/d/GitHub/DnD_Scripts/") and type: "./get_3d_monsters_from_mz4250_on_shapeways.sh"

# The files will be downloaded into a sub folder called "STL_files" this is where the extracted 3D files are. 
# The zip files with funny names will be in the "ZIP_files" folder, 
# these are just zip files containing the same 3D files in the other folder, 
# I just don't like deleting stuff in scripts, especially ones I share.
# Hope it works for people!

# script version: 0.02

# Bug fix log:
# ver. 0.02
#   1. Commented out export stuff as people will likely not need it.
#   2. Added directory creation before downloading and creating as OS X was having a hard time.
#   3. Changed link crawler to specifically remove the "href=" bit as OS X was having a hard time:
#       old: sed -e 's/^.*"\([^"]\+\)".*$/\1/g'
#       new: sed -n 's/.*href="\([^"]*\).*/\1/p'
#   4. Add how-to comment at header, fix formating, miss-spellings, add/remove comments
#
#   Tested on:
#       OS: OS X 10.11.1
#          wget: GNU Wget 1.15 built on darwin13.1.0.
#          unzip: UnZip 5.52 of 28 February 2005, by Info-ZIP
#          bash: GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin15)
#       
#       NOTE:
#           I didn't test this with linux or cygwin, but it *should* still work...
    

# Shapeways.com login info:
username=YOUR_USERNAME
password=YOUR_PASSWORD

# Shapeways.com user page:
user_page=https://www.shapeways.com/designer/mz4250
user=`basename ${user_page}`

# Setup proxies if needed.
# export http_proxy=YOUR_PROXY
# export https_proxy=YOUR_PROXY

# stuff we need
webpage_domain=https://www.shapeways.com
zip_download_dir=./ZIP_files
stl_extract_dir=./STL_files

extract_item_from_zip () {
    mkdir -p ${stl_extract_dir}
    unzip -o $1 -d ${stl_extract_dir}
}

download_item () {
    item_name=(`echo $1 | awk -F/ '{print $5}'`)
    
    mkdir -p ${zip_download_dir}
    wget --referer="https://www.shapeways.com/login" --cookies=on --keep-session-cookies --load-cookies=cookies.txt -O ${zip_download_dir}/${item_name}.zip https://www.shapeways.com/product/download/${item_name}

    extract_item_from_zip ${zip_download_dir}/${item_name}.zip
}   

get_items_to_download_from_page () {

    # Crawl sub-page for products
    page_links=(`wget -q $1 -O - | \
        tr "\t\r\n'" '   "' | \
        grep -i -o '<a[^>]\+href[ ]*=[ \t]*"\(ht\|f\)tps\?:[^"]\+"' | \
        sed -n 's/.*href="\([^"]*\).*/\1/p'`)

    items_to_download=()
    for link in "${page_links[@]}"
    do
        if [[ ${link} =~ .*www.shapeways.com/product/.* ]]
            then
            # Check if item already in array
            if [[ ! " ${items_to_download[@]} " =~ " ${link} " ]]; then
                items_to_download+=($link)
            fi
        fi
    done

    for item in "${items_to_download[@]}"
    do
        download_item ${item}
    done
}

# Start
# Login to shapeways.com
wget https://www.shapeways.com/login -O logon.html --cookies=on --keep-session-cookies --save-cookies cookies.txt --post-data 'username='${username}'&password='${password}

# Crawl page for "more-products" (each user sub-page)
user_page_links=(`wget -q ${user_page} -O - | \
    tr "\t\r\n'" '   "' | \
    grep -i -o '<a[^>]\+href[ ]*=[ \t]*"/[^"]\+"' | \
    sed -n 's/.*href="\([^"]*\).*/\1/p'`)

pages_to_check=()
for user_page_link in "${user_page_links[@]}"
do
    if [[ ${user_page_link} =~ .*/designer/${user}.*more-products.* ]]
        then
        pages_to_check+=(${webpage_domain}${user_page_link})
    fi
done

# Foreach sub-page, download all products
for page in "${pages_to_check[@]}"
do
    get_items_to_download_from_page ${page}
done
# Finish
