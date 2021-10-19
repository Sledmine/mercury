#curl -O -J -L
curl -s https://api.github.com/repos/Sledmine/mercury/releases/latest \
| grep "browser_download_url.*ubuntu" \
| cut -d : -f 2,3 \
| tr -d \" \
| xargs wget
