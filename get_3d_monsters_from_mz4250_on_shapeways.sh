#!/bin/bash


# This will download all the files that user "mz4250" has on his shapeways account
#
# Rough how to:
# If you have access to a linux or unix computer this script should work 
# (I wrote and used this on my windows PC with cygwin). 
# But you might need to install "unzip" and "wget"; how to do this will vary depending on distro.
# If you have a windows system, I'd recommend installing cygwin, be sure to search for, and select/check, "unzip" and "wget" when selecting packages to install.
# It's important to note if you log-in to shapeways via google, you'll need to change how you login by selecting "Shapeways username and password" 
# on https://www.shapeways.com/settings/account. It's probably the same with facebook...

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
cookie_file=$1
username=$2
password=$3

# stuff we need
zip_download_dir=./ZIP_files
stl_extract_dir=./STL_files

extract_item_from_zip () {
    mkdir -p ${stl_extract_dir}
    unzip -o $1 -d ${stl_extract_dir}
}

download_item () {
    mkdir -p ${zip_download_dir}
    wget --referer="https://www.shapeways.com/login" --cookies=on --keep-session-cookies --load-cookies=${cookie_file} -O ${zip_download_dir}/$1.zip https://www.shapeways.com/product/download/$1

    extract_item_from_zip ${zip_download_dir}/$1.zip
}   

get_items_to_download_from_page () {
    # Crawl sub-page for products
    item_IDs=(`wget -q $1 -O - | \
        grep -i -o 'href="http://www.shapeways.com/product/.*=user-profile"' | \
        sed -n 's|.*href="http://www.shapeways.com/product/\([A-Za-z0-9]\+\).*|\1|p' | \
        uniq`)

    for item in "${item_IDs[@]}"; do
        download_item ${item}
    done
}

# Start
# Login to shapeways.com
#wget https://www.shapeways.com/login -O logon.html --cookies=on --keep-session-cookies --save-cookies cookies.txt --post-data 'username='${username}'&password='${password}

# Determine all the product sub-pages
# Begin by getting a list of the page navigation links. Only the first few and the last will be shown
user_page="https://www.shapeways.com/designer/mz4250/creations?s=0#more-products"
user_page_links=(`wget -q ${user_page} -O - | \
    grep -i 'href="/designer/mz4250/creations?s=[0-9]\+#more-products"' | \
    sed -n 's/.*href="\([^"]*\).*/\1/p'`)

models_per_page=`echo ${user_page_links[1]} | sed -n 's/.*?s=\([0-9]\+\).*/\1/p'`
# This is second-to-last instead of last because of the "next" button, which should be ignored
models_at_last_page=`echo ${user_page_links[-2]} | sed -n 's/.*?s=\([0-9]\+\).*/\1/p'`
num_pages=`expr $models_at_last_page  / $models_per_page + 1`

for ((i=0 ; i < $num_pages ; i++)); do
    num=`expr $i \* $models_per_page`
    page="https://www.shapeways.com/designer/mz4250/creations?s=${num}#more-products"
    get_items_to_download_from_page ${page}
done

# Finish
