import json
from ryanair.airport_utils import load_airports

airports = load_airports()

output = []
for code, airport in sorted(airports.items(), key=lambda x: x[1].location):
    output.append({
        "code": airport.IATA_code,
        "name": airport.location
    })

print(json.dumps(output))
