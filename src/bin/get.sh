#!/bin/bash
# 
# BSD LICENSE
# 
# Copyright (c) 2009, Michael Truog
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#     * All advertising materials mentioning features or use of this
#       software must display the following acknowledgment:
#         This product includes software developed by Michael Truog
#     * The name of the author may not be used to endorse or promote
#       products derived from this software without specific prior
#       written permission
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.

if [ $# -ne 2 ]; then
    echo "Usage: $0 file destination_directory"
    exit 1
fi
FILE=$1
DESTINATION=$2

cd $DESTINATION
if [ -e $FILE ]; then
    echo "$FILE already exists"
    exit 0
fi

MIRRORS_FILE="mirrors.txt"
if [ ! -e $MIRRORS_FILE ]; then
    echo "no \"$MIRRORS_FILE\" file found at $DESTINATION"
    exit 1
fi

MIRROR_SEARCH_TIME=`cat $MIRRORS_FILE | wc -l`
echo "finding the best mirror... (please wait $MIRROR_SEARCH_TIME seconds)"

# find the best mirror by pinging each host and sorting the results
TMP_DATA_FILE=`date +"/tmp/get_sh-%Y%m%d%H%M%S.data"`
ZEROES="000000000000000000"
echo -n > $TMP_DATA_FILE
for SOURCE in `cat $MIRRORS_FILE`; do
    HOST=`echo "$SOURCE" | cut -d '/' -f 3` # Bob Bemer's escape sequence
    PING_TIME=`ping -i 0.5 -c 2 $HOST | tail -n 1 | cut -d '/' -f 5`
    PING_TIME_LEN=`echo -n "$PING_TIME" | wc -c`
    if [ $PING_TIME_LEN -ge 4 ] ; then
        echo ${ZEROES:1:18-$PING_TIME_LEN}"$PING_TIME $SOURCE" >> $TMP_DATA_FILE
    fi
done
if [ `cat $TMP_DATA_FILE | wc -l` -eq 0 ]; then
    echo "no mirror hosts can be reached"
    rm -f $TMP_DATA_FILE
    exit 1
fi
sort -o $TMP_DATA_FILE $TMP_DATA_FILE
SOURCE=`head -n 1 $TMP_DATA_FILE | cut -d' ' -f 2`
rm -f $TMP_DATA_FILE

# determine how to download the file
which curl > /dev/null
USE_CURL=$?
which wget > /dev/null
USE_WGET=$?

if [ $USE_CURL -eq 0 ]; then
    echo "downloading $FILE..."
    echo "(using $SOURCE)"
    curl --progress-bar -O -L "$SOURCE""$FILE"
elif [ $USE_WGET -eq 0 ]; then
    echo "downloading $FILE..."
    wget --progress=bar:force -O $FILE -p "$SOURCE""$FILE"
else
    echo "install either curl or wget"
    exit 1
fi
echo "done"
