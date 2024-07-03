function exit_error() {
  echo "> Usage: binday <UPRN>"
  exit 1
}

function exit_error_uprn() {
  echo "> Check the UPRN value is correct and try again."
  exit_error
}

if [ $# -gt 1 ]; then
  exit_error
fi

UPRN=""
if [ $# -eq 1 ]; then
  UPRN="$1"
else
  BINDAY_UPRN_FILE="${BINDAY_UPRN_FILE:-$HOME/.config/binday/uprn}"
  if [ ! -f "$BINDAY_UPRN_FILE" ]; then
    printf "> File not found: %s\n" "$BINDAY_UPRN_FILE"
    printf "> Go to the following link in a browser while doing an inspect (usually ctrl+shift+i) on the network tab.\n"
    printf "> After entering your address, you should find the POST request form data payload.\n"
    printf "> Copy the 'UPRN' value, which should look something like '123456789123|x+YO+HOUSE+y+YO+STREET+LONDON'.\n"
    printf "> Save the 'UPRN' value to the file %s.\n" "$BINDAY_UPRN_FILE"
    exit_error_uprn
  fi
  UPRN=$(cat "$BINDAY_UPRN_FILE")
fi

URL="https://www.hounslow.gov.uk/homepage/86/recycling_and_waste_collection_day_finder\#collectionday"
RES=$(curl -s -w "%{http_code}" "$URL" -d "UPRN=$UPRN")
BODY=${RES::-3}
STATUS=$(printf "%s" "$RES" | tail -c 3)

if [[ "$BODY" == *"Sorry we encountered an issue"* ]]; then
  printf "%s\n" "$BODY" | tail -n 1
  exit_error_uprn
fi

if [ "$STATUS" -ne "200" ]; then
  printf "%s\n" "$BODY" | tail -n 1
  printf "\n>\n> Error: HTTP repsonse is '%s'.\n" "$STATUS"
  exit_error_uprn
fi
HEADER=$(printf "%s" "$BODY" | grep '<h4>')
mapfile -t array < <( echo "${HEADER//<h4>/$'\n'}" )

printf "%s" "${array[1]}" | awk -F'"|<' '
  /img alt=/ {
    match($0, /<h4>([^<]+)/, bins)
    date = substr(bins[1], 6)

    while (match($0, /img alt="([^"]+)/)) {
      bin_name = substr($0, RSTART + 9, RLENGTH - 9)
      next_bins[bin_name]
      $0 = substr($0, RSTART + RLENGTH)
    }
  }
  END {
    printf "Bins for %s:\n", date
    sep = ""
    for (bin in next_bins) {
      printf "%s- %s", sep, bin
      sep = "\n"
    }
    printf "\n"
  }
'
