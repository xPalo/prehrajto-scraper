import sys
import json
from datetime import datetime
from ryanair import Ryanair

# airport_origin = sys.argv[1]
# date_from = sys.argv[2].strptime(date_from_str, "%Y-%m-%d").date()
# date_to = sys.argv[3].strptime(date_from_str, "%Y-%m-%d").date()
# destination_country = sys.argv[4]
# departure_time_from = sys.argv[5].strptime(date_from_str, "%Y-%m-%d").date()
# departure_time_to = sys.argv[6].strptime(date_from_str, "%Y-%m-%d").date()
# destination_airport = sys.argv[7]

parser = argparse.ArgumentParser(description="Fetch Ryanair flights")
parser.add_argument('--from', dest='airport_origin', required=True, help='Origin airport (e.g. VLC)')
parser.add_argument('--date-from', required=True, help='Start date (YYYY-MM-DD)')
parser.add_argument('--date-to', required=True, help='End date (YYYY-MM-DD)')
parser.add_argument('--to-country', help='Destination country (e.g. Austria)')
parser.add_argument('--departure-time-from', help='Earliest departure time (YYYY-MM-DD)')
parser.add_argument('--departure-time-to', help='Latest departure time (YYYY-MM-DD)')
parser.add_argument('--to-airport', help='Destination airport (e.g. VIE)')

args = parser.parse_args()

date_from = datetime.strptime(args.date_from, "%Y-%m-%d").date()
date_to = datetime.strptime(args.date_to, "%Y-%m-%d").date()

departure_time_from = (
    datetime.strptime(args.departure_time_from, "%Y-%m-%d").date()
    if args.departure_time_from else None
)
departure_time_to = (
    datetime.strptime(args.departure_time_to, "%Y-%m-%d").date()
    if args.departure_time_to else None
)

api = Ryanair()
flights = api.get_cheapest_flights(
    airport=args.airport_origin,
    date_from=date_from,
    date_to=date_to,
    destination_country=args.to_country,
    departure_time_from=departure_time_from,
    departure_time_to=departure_time_to,
    destination_airport=args.to_airport
)

output = []
for f in flights:
    output.append({
        "departure": f.departureTime.isoformat(),
	    "flight_number": f.flightNumber,
        "price": f.price,
	    "currency": f.currency,
        "origin": f.origin,
	    "originFull": f.originFull,
        "destination": f.destination,
	    "destinationFull": f.destinationFull,
	    "airline": "Ryanair"
    })

print(json.dumps(output))
