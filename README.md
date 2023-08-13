# GPX Directions

Turn a GPX file into human readable directions.

## Requirements

* Ruby 3.2.2 (with Bundler)
* libbz2 (tested with 1.1.0)
* sqlite >= 3.6.16 (tested with 3.42.0)

## Development

Clone the repo:

```shell
$ git pull git@github.com:nahiluhmot/gpx_directions
$ cd gpx_directions
```

Install dependencies:

```shell
$ ./bin/setup
```

Import a map (download more from [Geofabrik](https://download.geofabrik.de/)):

```shell
$ ./bin/seed_db ./gpx_directions.sqlite ./example/rhode-island-latest.osm.bz2
```

Generate directions (create your own at [OnTheGoMap](https://onthegomap.com/)):

```shell
$ ./bin/directions ./gpx_directions.sqlite ./example/newport-middletown-loop-50km.gpx
Start at {lat: 41.496711, lon: -71.316834}
Continue on Farewell Street for 202m
Turn left onto Farewell Street
Continue on Farewell Street for 144m
Continue straight onto Farewell Street
Continue on Farewell Street for 10m
Take a sharp right onto Poplar Street
Continue on Poplar Street for 13m
Take a sharp right onto Thames Street
Continue on Thames Street for 311m
Continue straight onto Thames Street
Continue on Thames Street for 98m
...
```
