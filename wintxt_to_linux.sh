#/bin/sh
#windows下的.txt文档转换为Linux下可读的utf8文档

read -p "Please input filename: " filename
#echo $filename

iconv -f gbk -t utf8 $filename > $filename.utf8
#filename is fullname;means : path + fullname.

