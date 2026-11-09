# discourse-walking-challenge

A shared distance challenge for Discourse. Members log their walks, runs, rides and ski trips, and everyone travels together along a 708 mile route through Kanto at `/walk`.

Built for the "Let's Be He4lthy" distance challenge on Elite Fourum.

## What it does

- **Race strip**: one track from Pallet Town to Indigo Plateau with everyone's avatar at their relative position.
- **Map**: a full map of Kanto laid out like the Gen 1 Town Map, with the challenge route drawn along the real roads and sea routes, and members' avatars where they are. Clicking an avatar opens their user card.
- **Your progress**: total distance, distance to the next stop, and a checklist of all nine stops, in the forum's own styling.
- **Logging**: walk, run, bike, hike, ski or other, in miles or kilometers. Each member can review and remove their own entries; staff can remove any entry.
- **Arrival posts (optional)**: when someone reaches a new town, the system user posts in a topic you choose. Each stop is announced once per member, even if entries are later edited.
- **Safety rails**: a per-entry distance cap to catch typos, and a rate limit on logging.

The map is drawn in code from Town Map coordinates. It follows Kanto's geography but uses no artwork from the games.

## Install

Add the repository to the `hooks` section of `containers/app.yml`, then rebuild:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/ScottMastro/discourse-walking-challenge.git
```

```sh
cd /var/discourse && ./launcher rebuild app
```

## Settings

| Setting | Default | Purpose |
| --- | --- | --- |
| `walking_challenge_enabled` | `false` | Turns on `/walk` and the sidebar link. |
| `walking_challenge_announce_topic_id` | `0` | Topic for arrival posts. `0` turns them off. |
| `walking_challenge_max_entry_km` | `160` | Largest distance a single entry can record. |

## Development

From the Discourse root:

```sh
LOAD_PLUGINS=discourse-walking-challenge bin/dev
bin/rspec plugins/discourse-walking-challenge/spec
bin/lint plugins/discourse-walking-challenge
```

QUnit tests run in the browser at `/tests?target=discourse-walking-challenge`.

## License

MIT. See `LICENSE`.

## Planned

- Optional device sync: Strava (which covers Garmin, Apple Watch, Fitbit and others) and an Apple Health shortcut. Typing distances in will always work.
- A route strip at the top of the challenge topic.
- Badges for each leg of the route.
