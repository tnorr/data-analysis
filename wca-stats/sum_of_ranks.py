import json
from collections import OrderedDict


def convert_file(filename):
    file = open(filename, encoding='utf-8')
    data = json.load(file)
    return data


def format_competitor_list(data):
    competitors_by_id = {}
    for competitor in data['persons']:
        competitor_id = competitor['id']
        del competitor['id']
        del competitor['dob']
        del competitor['gender']
        competitor['sumOfRanks'] = 0
        competitors_by_id[competitor_id] = competitor
    return competitors_by_id


def format_event_rankings(data):
    results = {}
    for event in data['events']:
        results[event['eventId']] = event['rounds']
    for eventId in results:
        for round in results[eventId]:
            del round['formatId']
            del round['groups']

    event_rankings = {}
    max_positions = {}  # Assigned for anyone not participating in the event. Number of successful results + 1
    for eventId in results:
        event_rankings[eventId] = {}
        round_index = 0
        max_positions[eventId] = 1
        for round in results[eventId]:  # The rounds must be in ascending order in the json file
            round_index += 1
            if round_index == 1:
                for result in round['results']:
                    if result['best'] > 0 and max_positions[eventId] < result['position'] + 1:
                        max_positions[eventId] = result['position'] + 1
                    event_rankings[eventId][result['personId']] = result['position']
            else:
                for result in round['results']:
                    event_rankings[eventId][result['personId']] = result['position']
    return event_rankings, max_positions


def print_sor_table(competitors_by_id, event_rankings):
    ordered_competitors = OrderedDict(sorted(competitors_by_id.items(), key=lambda row: row[1]['sumOfRanks']))

    def print_title_row():
        print("-" * (90 + len(event_rankings) * 6))
        print("{:10s}{:10s}{:30s}{:15s}{:10s}{:15s}".format('Position', 'ID', 'Name',
                                                            'WCA ID', 'Country', 'Sum of Ranks'), end='')
        for eventId in event_rankings:
            print("{:6s}".format(eventId), end='')
        print('')
        print("-" * (90 + len(event_rankings) * 6))

    position = 0
    for competitor_id in ordered_competitors:
        if position % 20 == 0:
            print_title_row()
        position += 1
        info_dict = competitors_by_id[competitor_id]
        name = info_dict['name']
        wcaId = info_dict['wcaId']
        countryId = info_dict['countryId']
        sumOfRanks = info_dict['sumOfRanks']
        print("{:<10d}{:<10d}{:<30s}{:<15s}{:<10s}{:<15d}".format(position, competitor_id,
                                                                  name[:30], wcaId, countryId, sumOfRanks), end='')

        for eventId in event_rankings:
            print('{:<6d}'.format(event_rankings[eventId][competitor_id]), end='')
        print('')


def main():
    competitionId = input("Type the competition ID:\n")
    filename = "Results for " + competitionId + ".json"
    while True:
        try:
            data = convert_file(filename)
            break
        except FileNotFoundError:
            competitionId = input("File '{:s}' not found. Try again.\n".format(filename))
            filename = "Results for " + competitionId + ".json"
    competitors_by_id = format_competitor_list(data)
    event_rankings, max_positions = format_event_rankings(data)

    # Calculate sum of ranks for each competitor
    for eventId in event_rankings:
        for competitor_id in competitors_by_id:
            if competitor_id not in event_rankings[eventId]:
                event_rankings[eventId][competitor_id] = max_positions[eventId]
        for competitor_id in event_rankings[eventId]:
            competitors_by_id[competitor_id]['sumOfRanks'] += event_rankings[eventId][competitor_id]

    print("\nSum of ranks for {:s}".format(competitionId))
    print_sor_table(competitors_by_id, event_rankings)


main()
