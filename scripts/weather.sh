#!/usr/bin/env bash
# Weather feed for WeatherCard.qml — open-meteo.com, no API key required.
# Location is auto-detected via ip-api.com and cached for 24 h.
#
#   --json     print cached JSON immediately; refresh in background if stale
#   --refresh  force a synchronous refetch, then print
#
# Cache philosophy (borrowed from illyamiro's weather.sh): never destroy a
# working cache on a failed fetch — stale data beats no data.

export LC_ALL=C

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/wisp-shell"
json_file="$cache_dir/weather.json"
loc_file="$cache_dir/location.json"
mkdir -p "$cache_dir"

CACHE_TTL=900   # 15 min
LOC_TTL=86400   # 24 h

get_location() {
    if [ -f "$loc_file" ]; then
        local age=$(( $(date +%s) - $(stat -c %Y "$loc_file") ))
        if [ "$age" -lt "$LOC_TTL" ]; then
            cat "$loc_file"
            return
        fi
    fi
    local loc
    loc=$(curl -sf --max-time 5 "http://ip-api.com/json" | jq -c '{lat, lon, city}' 2>/dev/null)
    if [ -n "$loc" ] && [ "$loc" != "null" ]; then
        echo "$loc" > "$loc_file"
        echo "$loc"
    elif [ -f "$loc_file" ]; then
        cat "$loc_file"
    fi
}

fetch() {
    local loc lat lon city raw
    loc=$(get_location)
    [ -z "$loc" ] && return 1
    lat=$(echo "$loc" | jq -r .lat)
    lon=$(echo "$loc" | jq -r .lon)
    city=$(echo "$loc" | jq -r .city)

    raw=$(curl -sf --max-time 10 "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,apparent_temperature_max&hourly=temperature_2m,weather_code,relative_humidity_2m&timezone=auto&forecast_days=5")

    # On failure keep the existing cache untouched
    [ -z "$raw" ] && return 1

    echo "$raw" | jq --arg city "$city" '
        def winfo:
            if . == 0 then ["", "Clear", "#f9e2af"]
            elif . <= 2 then ["󰖕", "Partly Cloudy", "#f9e2af"]
            elif . == 3 then ["󰖐", "Overcast", "#bac2de"]
            elif . == 45 or . == 48 then ["󰖑", "Fog", "#84afdb"]
            elif . <= 57 then ["󰖗", "Drizzle", "#74c7ec"]
            elif . <= 67 then ["󰖗", "Rain", "#74c7ec"]
            elif . <= 77 then ["󰖘", "Snow", "#cdd6f4"]
            elif . <= 82 then ["󰖖", "Showers", "#74c7ec"]
            elif . <= 86 then ["󰖘", "Snow", "#cdd6f4"]
            else ["󰖓", "Storm", "#f9e2af"]
            end;
        . as $r |
        {
            city: $city,
            current: ($r.current | (.weather_code | winfo) as $w | {
                temp: .temperature_2m,
                feels: .apparent_temperature,
                humidity: .relative_humidity_2m,
                wind: .wind_speed_10m,
                icon: $w[0], desc: $w[1], hex: $w[2]
            }),
            days: [ range(0; ($r.daily.time | length)) as $i |
                ($r.daily.weather_code[$i] | winfo) as $w |
                {
                    day: ($r.daily.time[$i] | strptime("%Y-%m-%d") | strftime("%a")),
                    date: ($r.daily.time[$i] | strptime("%Y-%m-%d") | strftime("%d %b")),
                    max: $r.daily.temperature_2m_max[$i],
                    min: $r.daily.temperature_2m_min[$i],
                    pop: ($r.daily.precipitation_probability_max[$i] // 0),
                    wind: $r.daily.wind_speed_10m_max[$i],
                    feels: $r.daily.apparent_temperature_max[$i],
                    humidity: ([$r.hourly.relative_humidity_2m[($i * 24):(($i + 1) * 24)][]] | add / length | round),
                    icon: $w[0], desc: $w[1], hex: $w[2],
                    hourly: [ range(0; 8) as $h | ($i * 24 + $h * 3) as $idx |
                        ($r.hourly.weather_code[$idx] | winfo) as $hw |
                        {
                            time: ($r.hourly.time[$idx] | split("T")[1]),
                            temp: $r.hourly.temperature_2m[$idx],
                            icon: $hw[0], hex: $hw[2]
                        } ]
                } ]
        }' > "${json_file}.tmp" && mv "${json_file}.tmp" "$json_file"
}

case "$1" in
    --refresh)
        fetch
        [ -f "$json_file" ] && cat "$json_file"
        ;;
    --json|*)
        if [ -f "$json_file" ]; then
            age=$(( $(date +%s) - $(stat -c %Y "$json_file") ))
            if [ "$age" -gt "$CACHE_TTL" ]; then
                touch "$json_file"   # debounce parallel callers
                fetch &
            fi
            cat "$json_file"
        else
            fetch
            [ -f "$json_file" ] && cat "$json_file"
        fi
        ;;
esac
