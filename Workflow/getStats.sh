#!/bin/zsh --no-rcs

# Get age of standings_file in minutes
[[ -f "${standings_file}" ]] && minutes="$((($(date +%s)-$(date -r "${standings_file}" +%s))/60))"

# Download Stats Data
if [[ "${forceReload}" -eq 1 ]]; then
    # Rate limit to only refresh if data is older than 1 minute
    [[ "${minutes}" -gt 0 || -z "${minutes}" ]] && reload=$(./reload.sh) && minutes=0
fi

# Format Last Updated Time
if [[ ! -f "${standings_file}" || ${minutes} -eq 0 ]]; then
    lastUpdated="Just now"
elif [[ ${minutes} -eq 1 ]]; then
    lastUpdated="${minutes} minute ago"
elif [[ ${minutes} -lt 60 ]]; then
    lastUpdated="${minutes} minutes ago"
elif [[ ${minutes} -ge 60 && ${minutes} -lt 120 ]]; then
    lastUpdated="$((${minutes}/60)) hour ago"
elif [[ ${minutes} -ge 120 && ${minutes} -lt 1440 ]]; then
    lastUpdated="$((${minutes}/60)) hours ago"
else
    lastUpdated="$(date -r "${standings_file}" +'%Y-%m-%d')"
fi

# Format Stats to Markdown
mdOutput=$(jq -crs --arg teamId "${teamId}" --arg icons_dir "${icons_dir}" \
'.[].standings |
(length) as $leagueCnt |
(group_by(.conferenceName)[] | select(.[].teamAbbrev.default == $teamId) | length) as $conferenceCnt |
(group_by(.divisionName)[] | select(.[].teamAbbrev.default == $teamId) | length) as $divisionCnt |
.[] | select(.teamAbbrev.default == $teamId) | 40 as $spaces |
    "![Team Logo](\($icons_dir)/\($teamId)small.png)\n",
    "# "+.teamName.default,
    "\n**Games Played:** \(.gamesPlayed)      ·      **Points:** \(.points)      ·      **Date:** \(.date)",
    "\n***\n\n### League\n\n```",
    ("Conference (Division):"|.+" "*($spaces-length))+"\(.conferenceName) (\(.divisionName))",
    ("Regulation Wins (OT Wins):"|.+" "*($spaces-length))+"\(.regulationWins) (\(.regulationPlusOtWins-.regulationWins))",
    ("Wins:"|.+" "*($spaces-length))+"\(.wins)",
    ("Ties:"|.+" "*($spaces-length))+"\(.ties)",
    ("Losses (OT Losses):"|.+" "*($spaces-length))+"\(.losses) (\(.otLosses))",
    ("Goals For/Against (Diff):"|.+" "*($spaces-length))+"\(.goalFor)/\(.goalAgainst) (\(.goalDifferential | (if . > 0 then "+"+(.|tostring) else . end)))",
    ("Shootout Record:"|.+" "*($spaces-length))+"\(.shootoutWins)-\(.shootoutLosses)",
    ("Streak:"|.+" "*($spaces-length))+"\(.streakCode)\(.streakCount)",
    "",
    ("League Rank:"|.+" "*($spaces-length))+"\(.leagueSequence)/\($leagueCnt)",
    ("Conference Rank:"|.+" "*($spaces-length))+"\(.conferenceSequence)/\($conferenceCnt)",
    ("Division Rank:"|.+" "*($spaces-length))+"\(.divisionSequence)/\($divisionCnt)",
    "```\n\n### Home\n\n```",
    ("Games Played:"|.+" "*($spaces-length))+"\(.homeGamesPlayed)",
    ("Regulation Wins (OT Wins):"|.+" "*($spaces-length))+"\(.homeRegulationWins) (\(.homeRegulationPlusOtWins-.homeRegulationWins))",
    ("Wins:"|.+" "*($spaces-length))+"\(.homeWins)",
    ("Ties:"|.+" "*($spaces-length))+"\(.homeTies)",
    ("Losses (OT Losses):"|.+" "*($spaces-length))+"\(.homeLosses) (\(.homeOtLosses))",
    ("Goals For/Against (Diff):"|.+" "*($spaces-length))+"\(.homeGoalsFor)/\(.homeGoalsAgainst) (\(.homeGoalDifferential | (if . > 0 then "+"+(.|tostring) else . end)))",
    ("Points:"|.+" "*($spaces-length))+"\(.homePoints)",
    "```\n\n### Away\n\n```",
    ("Games Played:"|.+" "*($spaces-length))+"\(.roadGamesPlayed)",
    ("Regulation Wins (OT Wins):"|.+" "*($spaces-length))+"\(.roadRegulationWins) (\(.roadRegulationPlusOtWins-.roadRegulationWins))",
    ("Wins:"|.+" "*($spaces-length))+"\(.roadWins)",
    ("Ties:"|.+" "*($spaces-length))+"\(.roadTies)",
    ("Losses (OT Losses):"|.+" "*($spaces-length))+"\(.roadLosses) (\(.roadOtLosses))",
    ("Goals For/Against (Diff):"|.+" "*($spaces-length))+"\(.roadGoalsFor)/\(.roadGoalsAgainst) (\(.roadGoalDifferential | (if . > 0 then "+"+(.|tostring) else . end)))",
    ("Points:"|.+" "*($spaces-length))+"\(.roadPoints)",
    "```\n\n### L10\n\n```",
    ("Regulation Wins (OT Wins):"|.+" "*($spaces-length))+"\(.l10RegulationWins) (\(.l10RegulationPlusOtWins-.l10RegulationWins))",
    ("Wins:"|.+" "*($spaces-length))+"\(.l10Wins)",
    ("Ties:"|.+" "*($spaces-length))+"\(.l10Ties)",
    ("Losses (OT Losses):"|.+" "*($spaces-length))+"\(.l10Losses) (\(.l10OtLosses))",
    ("Goals For/Against (Diff):"|.+" "*($spaces-length))+"\(.l10GoalsFor)/\(.l10GoalsAgainst) (\(.l10GoalDifferential | (if . > 0 then "+"+(.|tostring) else . end)))",
    ("Points:"|.+" "*($spaces-length))+"\(.l10Points)",
    "```"
' "${standings_file}" | sed 's/\"/\\"/g')

# Output Formatted Stats to Text View
cat << EOB
{
    "variables": { "forceReload": 1 },
    "response": "${mdOutput//$'\n'/\n}",
    "footer": "Last Updated: ${lastUpdated}            ⌥↩ Update Now"
}
EOB