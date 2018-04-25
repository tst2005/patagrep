
#echo "1st arg: $1"
#echo "patagrep_basedir: $patagrep_basedir"

# try to read test.lib.sh
[ ! -f "$patagrep_basedir/$1.lib.sh" ] || . "$patagrep_basedir/$1.lib.sh"

# try to read demo.lib.sh
[ ! -f "$patagrep_basedir/${1%/*}/demo.lib.sh" ] || . "$patagrep_basedir/${1%/*}/demo.lib.sh"

demo "$1"
