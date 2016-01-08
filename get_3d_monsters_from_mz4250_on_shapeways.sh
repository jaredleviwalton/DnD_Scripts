# Shapeways.com login info:
username=YOUR_USERNAME
password=YOUR_PASSWORD

# Shapeways.com user page:
user_page=https://www.shapeways.com/designer/mz4250
user=`basename ${user_page}`

# Setup proxies if needed.
export http_proxy=YOUR_PROXY
export https_proxy=YOUR_PROXY

# stuff we need
webpage_domain=https://www.shapeways.com
zip_downlaod_dir=./ZIP_files
stl_extract_dir=./STL_files

extract_item_from_zip () {
    unzip -o $1 -d ${stl_extract_dir}
}

download_item () {
    item_name=(`echo $1 | awk -F/ '{print $5}'`)
    wget --referer="https://www.shapeways.com/login" --cookies=on --keep-session-cookies --load-cookies=cookies.txt -O ${zip_downlaod_dir}/${item_name}.zip https://www.shapeways.com/product/download/${item_name}

    extract_item_from_zip ${zip_downlaod_dir}/${item_name}.zip
}   

get_items_to_download_from_page () {

    # Crawl sub-page for products
    page_links=(`wget -q $1 -O - | \
        tr "\t\r\n'" '   "' | \
        grep -i -o '<a[^>]\+href[ ]*=[ \t]*"\(ht\|f\)tps\?:[^"]\+"' | \
        sed -e 's/^.*"\([^"]\+\)".*$/\1/g'`)

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
    sed -e 's/^.*"\([^"]\+\)".*$/\1/g'`)

pages_to_check=()
for user_page_link in "${user_page_links[@]}"
do
    # Check if item already in array
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
