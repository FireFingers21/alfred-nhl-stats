#!/bin/zsh --no-rcs

# Get current/selected season
[[ "$(date +%s)" -ge "$(date -jv 9m +%s)" ]] && seasonYear="$(date +%Y)" || seasonYear="$(($(date +%Y) - 1))"
seasonDir="${alfred_workflow_data}/${seasonYear}"

# Auto Update
set -o extendedglob
[[ -f ${alfred_workflow_data}/*/*(#i)standings.json(#qNY1) ]] \
&& [[ "$(date -r "${alfred_workflow_data}" +%s)" -lt "$(date -v -"${autoUpdate}"M +%s)" || ! -d "${seasonDir}" ]] && reload=$(./reload.sh)

# Load Standings
jq -cs \
   --arg favTeam "$(iconv -f UTF-8-MAC -t UTF-8 <<< ${(L)favTeam})" \
   --arg grouping "${grouping}" \
   --arg icons_dir "${seasonDir}/icons" \
   --arg seasonYear "${seasonYear}" \
'{
    "variables": {
        "icons_dir": $icons_dir,
        "seasonYear": $seasonYear
    },
    "skipknowledge": true,
	"items": (if (length != 0) then
		.[].standings |
		([.[] | select(.clinchIndicator).divisionName]) as $clinchedDivisions |
		([.[] | select(.clinchIndicator != "e").divisionName]) as $playoffDivisions |
		(if ($grouping != "league") then map({(."\($grouping)Name"): ."\($grouping)Sequence"}) else "" end) as $groupingSeqs |
		map({
			"title": "\(."\($grouping)Sequence")  \(.teamName.default)  \(.clinchIndicator | if (.) then "(\(.))" else "" end)  \(if ((.teamName.default|ascii_downcase) == $favTeam) then "★" else "" end)",
			"subtitle": "[ GP: \(.gamesPlayed)  W: \(.wins)  L: \(.losses)  OT: \(.otLosses) ]    PTS: \(.points)    [ RW: \(.regulationWins)  ROW: \(.regulationPlusOtWins)  GF: \(.goalFor)  GA: \(.goalAgainst)  DIFF: \(.goalDifferential | (if . > 0 then "+"+(.|tostring) else . end)) ]",
			"arg": "stats",
			"match": [
                ."\($grouping)Sequence", .teamName.default, "\(.conferenceName) Conference", .divisionName,
                (if (.wildcardSequence > 0) then "wildcard" else "" end),
                (if (.clinchIndicator) then "clinched" else "" end),
                (if (.clinchIndicator != "e") then "playoffs" else "" end)
            ] | map(select(.)) | join(" "),
			"icon": { "path": "\($icons_dir)/\(.teamAbbrev.default).png" },
			"text": { "copy": .teamName.default },
			"variables": { "teamId":.teamAbbrev.default, "teamName":.teamName.default, "seq":."\($grouping)Sequence", "conference":.conferenceName, "division":.divisionName },
			"mods": {
			    "cmd": {"subtitle": "⌘↩ Sort by Division", "arg": "", "variables": {"grouping":"division"}},
			    "alt": {"subtitle": "⌥↩ Sort by Conference", "arg": "", "variables": {"grouping":"conference"}},
			    "ctrl": {"subtitle": "⌃↩ Sort by League", "arg": "", "variables": {"grouping":"league"}}
			}
		}) | (if ($grouping != "league") then ([
		    (unique_by(.variables."\($grouping)")[] | select((.variables.seq) == 1)) |
		    (. |= (.variables.division) as $division | (.variables.conference) as $conference | {
				"title":"—————  \(.variables.conference) Conference  —————",
				"subtitle":(if ($grouping == "division") then (.variables.division | " "*(47-length/2)+.) else "" end),
				"icon":{"path":"images/iconLarge.png"},
				"match":"\(.variables.conference) Conference \(.variables.division) \($groupingSeqs | map(."\($grouping)" | select(.)) | join(" ")) \((.variables.division) as $div | if ($playoffDivisions | contains([$div])) then "clinched playoffs" elif ($clinchedDivisions | contains([$div])) then "clinched" else "" end) wildcard",
				"variables":.variables, "mods":.mods, "valid": false
			}) | (.variables.seq |= 0)
		]+.) end)
		| (if ($grouping == "conference") then sort_by(.variables.conference, .variables.seq) elif ($grouping == "division") then sort_by(.variables.conference, .variables.division, .variables.seq) end)
		| [(.[] | select(($grouping == "league" and .variables.seq == 1) | not) | select(.variables.seq != 0 and (.variables.teamName|ascii_downcase) == $favTeam)) | (.match |= "")] + .
	else
		[{
			"title": "No Standings Found",
			"subtitle": "Press ↩ to load standings for the current season",
			"arg": "reload"
		}]
	end)
}' "${seasonDir}/standings.json"