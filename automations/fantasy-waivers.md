# fantasy-waivers

Schedule: `55 6 * * 2` (Tuesday morning, before waivers clear).

The hub fetches the league on its own every 3 hours (public ESPN league, no login) and writes `/data/fantasy.json`. The model never touches ESPN. It only reads that file and gives its judgment.

```
Fantasy waiver picks for this week.

1. Use the read tool on /data/fantasy.json. It contains my roster, this week's matchup, and the best available free agents per position, with projections and injury status.
2. Pick up to 3 adds. For each: player, position, who to drop from my roster, and one short reason based ONLY on numbers in the file.
3. Note any of my starters who are OUT or DOUBTFUL.

Under 100 words. Do not invent players or stats that are not in the file.

Always finish by using the write tool to write the result to /screen/fantasy.md, then write /screen/now.json with {"text": "Waiver picks are up.", "mood": "happy", "ttl_min": 240}. Do not just print the answer: the job only counts if the files are written.
```
