import sys
import json
import argparse
from datetime import datetime
from ryanair import Ryanair

parser = argparse.ArgumentParser(description="Fetch Ryanair flights")
parser.add_argument('--from', dest='airport_origin', required=True, help='Origin airport (e.g. VLC)')
parser.add_argument('--date-from', required=True, help='Start date (YYYY-MM-DD)')
parser.add_argument('--date-to', required=True, help='End date (YYYY-MM-DD)')
parser.add_argument('--to-country', help='Destination country (e.g. Austria)')
parser.add_argument('--departure-time-from', help='Earliest departure time (YYYY-MM-DD)')
parser.add_argument('--departure-time-to', help='Latest departure time (YYYY-MM-DD)')
parser.add_argument('--to-airport', help='Destination airport (e.g. VIE)')

args = parser.parse_args()

kwargs = {
    'airport': args.airport_origin,
    'date_from': datetime.strptime(args.date_from, "%Y-%m-%d").date(),
    'date_to': datetime.strptime(args.date_to, "%Y-%m-%d").date()
}

if args.to_country:
    kwargs['destination_country'] = args.to_country

if args.departure_time_from:
    kwargs['departure_time_from'] = datetime.strptime(args.departure_time_from, "%Y-%m-%d").date()

if args.departure_time_to:
    kwargs['departure_time_to'] = datetime.strptime(args.departure_time_to, "%Y-%m-%d").date()

if args.to_airport:
    kwargs['destination_airport'] = args.to_airport

api = Ryanair()
flights = api.get_cheapest_flights(**kwargs)

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