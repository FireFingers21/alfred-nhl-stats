#!/bin/zsh --no-rcs

seasons_file="${alfred_workflow_data}/seasons.json"

mkdir -p "${alfred_workflow_data}"
curl -sf --compressed --connect-timeout 10 "https://api-web.nhle.com/v1/standings-season" -o "${seasons_file}" && downloadStatus=1

if [[ -n "${downloadStatus}" ]]; then
    # Get standings for current/selected season
    season="$(jq -r '.seasons[-1].standingsEnd' "${seasons_file}")"
    seasonYear="$(jq -r '.seasons[-1].standingsStart[0:4]' "${seasons_file}")"
    seasonDir="${alfred_workflow_data}/${seasonYear}"
    mkdir -p "${seasonDir}"
    curl -sf --compressed "https://api-web.nhle.com/v1/standings/${season}" -o "${seasonDir}/standings.json"
    set -o extendedglob
    if [[ -f "${seasonDir}/standings.json" && ! -n ${seasonDir}/icons/*.png(#qNY1) ]]; then
        # Get Team Logos
        mkdir -p "${seasonDir}/icons"
        teamLogos=($(jq -r '.standings[].teamLogo' "${seasonDir}/standings.json"))
        curl -sf --compressed --parallel --output-dir "${seasonDir}/icons" --remote-name-all -L "${teamLogos[@]}"
        for file in ${seasonDir}/icons/*.svg; do
            sips -s format png -o "${seasonDir}/icons/${${file##*/}::3}.png" --resampleHeight 256 -p 288 288 "${file}" >/dev/null && rm "${file}"
        done
    fi
    printf "Standings Updated"
else
    printf "Standings not Updated"
fi