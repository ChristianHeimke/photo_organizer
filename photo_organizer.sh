#!/bin/bash
# Script to sort Photos and movies from digital cameras into folders by date
# When possible it uses the exif information on the photo to get the original date
# otherwise it uses the last modification date
#
#       orginal script from 
#       http://davehope.co.uk/Blog/sorting-your-photos-with-bash/
#       and
#       http://sysadminnotebook.blogspot.de/2012/01/organize-your-photos-with-script.html
#
#       modified to be mac compatible

cfgSource="$1"
cfgDestRoot="$2"

toUpper() {
    echo $1 | tr  "[:lower:]" "[:upper:]"
}
toLower() {
    echo $1 | tr "[:upper:]" "[:lower:]"
}
escapeSpaces(){
    echo $1 | sed 's/ /\\ /g'
}

if [ "$#" != "2" ]; then
    echo "Usage: $0 <source> <destination>"
    exit 1
fi
which stat > /dev/null
# make sure stat command is installed
if [ $? -eq 1 ]
then
    echo "stat command not found!"
    exit 2
fi

# using a tmp file you can have spaces in the file path
find "$cfgSource" -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.nef" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.mpg" -o -iname "*.mp4" > images.tmp
#for f in $(find "$cfgSource" -iname "*.jpg" -o -iname "*.nef")
cat ./images.tmp | while read f;
do
        #f=$(escapeSpaces "${f}")
        # Make sure the file we've been given by find actually exists.
        if [ -f "${f}" ]; then
                echo " "
                FILETYPE=$(toUpper ${f#*.})
                timestamp=""
                
                #If identify fails to read the date from exif
                # or file is not an image, use stat to get last modification date
                if [ "${timestamp}" = "" ]; then
                    timestamp=$(stat -f %m "$f" | sed 's/^\([0-9\-]*\).*/\1/')
                fi
                # Looks like there are three possible timestamp formats:
                #       2008-05-05T14:46:47.16+01:00
                #       2009:02:28 12:57:50
                #       2011-05-25 19:24:26.000000000 +0100
                # Thankfully, cut will handle all of these formats.

                moddate=$(date -r $timestamp "+%Y-%m-%d") 

                y=$(echo $moddate | cut -c 1-4)
                m=$(echo $moddate | cut -c 6-7)
                d=$(echo $moddate | cut -c 9-10)
                destFile=$cfgDestRoot/$y/$m/$d/$(basename "${f}")
                
                # If the directory doesn't exist recursively create it.
                if [ ! -d "$cfgDestRoot/$y/$m/$d" ]; then
                        mkdir -p "$cfgDestRoot/$y/$m/$d"
                fi
                # Move the file.
                if [ -f "${destFile}" ]; then
                        # Existing file found.
                        echo "Existing file found: ${destFile}"
                        echo "Source: ${f}"
                        # Is it the same file? If so, delete the file we're processing.
                        md5src=$(md5sum "${f}")
                        md5src=${md5src% *}
                        md5dst=$(md5sum "${destFile}")
                        md5dst=${md5dst% *}
                        if [ $md5src = $md5dst ]; then
                                echo "Duplicate found, discarding identical file"
                                rm "$f"
                        else
                                # Is this file larger than the existing one?
                                sizeSrc=$(stat -c%s "$f")
                                sizeDst=$(stat -c%s "$destFile")
                                echo "Duplicate Found, keeping the larger file."
                                if [ $sizeSrc -gt $sizeDst ]; then
                                        mv "$f" "$destFile"
                                else
                                        mv "$f"
                                fi
                        fi
                else
                        mv "$f" "$destFile"
                        echo "Moved $f to $destFile"
                fi
        else
            echo "${f}"
            echo "File not found!"
        fi
        echo "== =="
done
#Now delete empty folders from source
find "$cfgSource" -iname "*.DS_Store" -exec rm -v {} +
find "$cfgSource" -iname "*.thm" -exec rm -v {} +
find "$cfgSource" -iname "*.IND" -exec rm -v {} +
find "$cfgSource" -iname "Thumbs.db" -exec rm -v {} +
find "$cfgSource" -type d -empty -delete
#find "$cfgSource" -depth -type d -empty -exec rmdir -v {} +
#Delete temporary file
rm images.tmp