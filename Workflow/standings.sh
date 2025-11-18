#!/bin/zsh --no-rcs

# Auto Update
[[ -f "${alfred_workflow_data}/seasons.json" ]] && [[ "$(date -r "${alfred_workflow_data}/seasons.json" +%s)" -lt "$(date -v -"${autoUpdate}"M +%s)" ]] && reload=$(./reload.sh)

# Get files for current season
seasons_file="${alfred_workflow_data}/seasons.json"
season="$(jq -r '.seasons[-1].standingsEnd' "${seasons_file}")"
seasonYear="$(jq -r '.seasons[-1].standingsStart[0:4]' "${seasons_file}")"
standings_file="${alfred_workflow_data}/${seasonYear}/standings.json"
icons_dir="${alfred_workflow_data}/${seasonYear}/icons"

# Load Standings
jq -cs \
   --arg icons_dir "${icons_dir}" \
   --arg favTeam "${(L)favTeam}" \
   --arg grouping "${grouping}" \
'{
    "variables": {
        "seasons_file": "'${seasons_file}'",
        "season": "'${season}'",
        "seasonYear": "'${seasonYear}'",
        "standings_file": "'${standings_file}'",
        "icons_dir": "'${icons_dir}'"
    },
    "skipknowledge": true,
	"items": (if (length != 0) then
		.[].standings | map({
			"title": "\(.'${grouping}Sequence')  \(.teamName.default)",
			"subtitle": "[ GP: \(.gamesPlayed)  W: \(.wins)  L: \(.losses)  OT: \(.otLosses) ]    PTS: \(.points)    [ RW: \(.regulationWins)  ROW: \(.regulationPlusOtWins)  GF: \(.goalFor)  GA: \(.goalAgainst)  DIFF: \(.goalDifferential | (if . > 0 then "+"+(.|tostring) else . end)) ]",
			"arg": "stats",
			"match": "\(.'${grouping}Sequence')  \(.teamName.default) \(.conferenceName) \(.divisionName) \(.wildcardSequence | if (. > 0) then "wildcard" else "" end)",
			"icon": { "path": "\($icons_dir)/\(.teamAbbrev.default).png" },
			"text": { "copy": .teamName.default },
			"variables": { "teamId":.teamAbbrev.default, "teamName":.teamName.default, "seq":.'${grouping}Sequence', "conference":.conferenceName, "division":.divisionName },
			"mods": {
			    "cmd": {"subtitle": "⌘↩ Sort by Division", "arg": "", "variables": {"grouping":"division"}},
			    "alt": {"subtitle": "⌥↩ Sort by Conference", "arg": "", "variables": {"grouping":"conference"}},
			    "ctrl": {"subtitle": "⌃↩ Sort by League", "arg": "", "variables": {"grouping":"league"}}
			}
		}) | (if ($grouping != "league") then ([
		    (.[] | select((.variables.seq) == 1)) |
		    (. |= {"title":"——  \(.variables.conference)  ——", "subtitle":(if ($grouping == "division") then .variables.division else "" end), "valid": false, "variables":.variables, "mods":.mods, "match":"\(.variables.conference) \(.variables.division) wildcard"}) |
			(.variables.seq |= 0)
		]+.) end)
		| (if ($grouping == "conference") then sort_by(.variables.conference, .variables.seq) elif ($grouping == "division") then sort_by(.variables.conference, .variables.division, .variables.seq) end)
		| [(.[] | select((.variables.teamName|ascii_downcase) == $favTeam)) | (.match |= "")] + .
		| [(.[] | if ((.variables.teamName|ascii_downcase) == $favTeam) then (.title |= .+"  ★") end)]
	else
		[{
			"title": "No Standings Found",
			"subtitle": "Press ↩ to load standings for the current season",
			"arg": "reload"
		}]
	end)
}' "${standings_file}"