# Oh, shit. We got some CoffeeScript up in here.

# General idea as follows:
# 
# 1. Get a list of emails (likely like 5) and ask Google Calendar for those peoples’ busy/free times.
# 
# 2. Figure out when all of those people can meet over the next week based on their busy/free times.
#
# 3. Print the possible schedules.

emails = ['willem.vanbergen@jadedpixel.com', 'aaron.olson@shopify.com', 'cody@shopify.com', 'florian.weingarten@shopify.com']

# Start by just getting the busy/free times

function post(url, body) {
  # something jquery?
}

apiKey = "whatever"

body = {
  "timeMin":"2013-11-30T00:00:00-05:00",
  "timeMax":"2013-12-07T00:00:00-05:00",
  "items": [
    {"id":"willem.vanbergen@jadedpixel.com"},
    {"id":"justin.mutter@jadedpixel.com"}
  ],
  "timeZone":"-05:00"
}

results = post("https://www.googleapis.com/calendar/v3/freeBusy?key=" + apiKey, body)

# What post results actually look like:
results = {
  "kind": "calendar#freeBusy",
  "timeMin": "2013-11-30T05:00:00.000Z",
  "timeMax": "2013-12-07T05:00:00.000Z",
  "calendars": {
    "willem.vanbergen@jadedpixel.com": {
      "busy": [
        {
          "start": "2013-12-02T15:00:00Z",
          "end": "2013-12-02T15:15:00Z"
        },
        {
          "start": "2013-12-02T15:30:00Z",
          "end": "2013-12-02T16:00:00Z"
        },
        {
          "start": "2013-12-02T18:00:00Z",
          "end": "2013-12-02T18:50:00Z"
        },
        {
          "start": "2013-12-02T21:00:00Z",
          "end": "2013-12-02T22:00:00Z"
        },
        {
          "start": "2013-12-04T15:00:00Z",
          "end": "2013-12-04T16:00:00Z"
        }
      ]
    },
    "justin.mutter@jadedpixel.com": {
      "busy": [
        {
          "start": "2013-12-02T15:30:00Z",
          "end": "2013-12-02T17:00:00Z"
        },
        {
          "start": "2013-12-02T18:00:00Z",
          "end": "2013-12-02T19:00:00Z"
        },
        {
          "start": "2013-12-03T15:30:00Z",
          "end": "2013-12-03T16:15:00Z"
        },
        {
          "start": "2013-12-03T16:30:00Z",
          "end": "2013-12-03T16:45:00Z"
        },
        {
          "start": "2013-12-04T15:30:00Z",
          "end": "2013-12-04T16:15:00Z"
        },
        {
          "start": "2013-12-04T16:30:00Z",
          "end": "2013-12-04T16:45:00Z"
        },
        {
          "start": "2013-12-04T20:00:00Z",
          "end": "2013-12-04T21:00:00Z"
        },
        {
          "start": "2013-12-05T15:30:00Z",
          "end": "2013-12-05T16:15:00Z"
        },
        {
          "start": "2013-12-05T16:30:00Z",
          "end": "2013-12-05T16:45:00Z"
        },
        {
          "start": "2013-12-05T18:30:00Z",
          "end": "2013-12-05T19:00:00Z"
        },
        {
          "start": "2013-12-06T15:30:00Z",
          "end": "2013-12-06T16:15:00Z"
        },
        {
          "start": "2013-12-06T16:30:00Z",
          "end": "2013-12-06T16:45:00Z"
        },
        {
          "start": "2013-12-06T19:00:00Z",
          "end": "2013-12-06T19:30:00Z"
        }
      ]
    }
  }
}

# Ok, so now how do I figure out the times? Algorithms, man.

# Use a big array?

# start with a function that tells me if one person is free at a time.
isFreeAtATime = (busyTimes, time) -> 
  # The idea is that I perform a Date.parse to get 

freeSlots = (busyTimes) ->
  # returns an array of times between 10am and 5pm (7 slots) indicating free/busy

allSlots = (emails) ->
  # returns an array of free/busy arrays

countAvailableSlots = (freeBusySlots) ->
  # returns number of available slots

# maybe keep freeBusySlots as an object that also links to names

slotsThatWork = (day, interviewers) ->
  interviewers
  workingSlots

  # Go through each hour of the interviewing day and see if the currently inspected slot works for any interviewers

  timeframe.each {|timeframe|
    interviewers.each {|interviewer|
      if doesTimeframeWork(interviewer, timeframe) {
        workingSlots << [timeframe, interviewer]
        removeInterviewer(interviewer)
        break
      }
    }
  }

  return workingslots
  # returns the slots that work matching with emails

permuteUntilSlotsWork(interviewers)
  slotsThatWork = []
  permutations = 1
  do {
    interviewers = permuteInterviewers(interviewers, permutations)
    slotsThatWork = slotsThatWork(day, interviewers)
  } while slotsThatWork.length == interviewers || permutationsExhausted(interviewers, permutations)

comingWeek = []

for i = 0; i < 7; i++ {
  comingWeek << today + i.days
}

class Interviewer
  email
  slotsAvailable

interviewers = [...]

comingWeek.each {|day|
  workingSlots = permuteUntilSlotsWork(day, interviewers)
  print workingSlots
}



Then walk through each hour of the day starting from 10am to see if a person is free at that time. If someone is, then remove them from the list of people you’re trying to fit into a day.

Try all permutations of order of people you have in the list to determine if a day can work, but stop as soon as it does.

Hmm... there must be a better way.

What if I were to represent each person’s schedule as a simplified array of hour blocks of the day, from 10am to 5pm, so 7 blocks. I mark the available slots, and then put the arrays next to each other, and then walk a path through the resulting graph and then back track when I have a problem. (This still feels very costly.)

Is there a way to use another dimension to better optimize the algorithm? Can I somehow stack the time slots on top of each other and see things topographically to see if a combination is even possible at all?

That could be interesting – first start out by looking to see everyone’s schedule for a day to count the free slots of an hour. If there are fewer than the number of interviewers, then reject the day immediately.

Ok, let’s try that approach:

1. Count free slots for each person. Reject if # free slots < # interviewers
2. Fit the first free
3. If the first tree fails, permute (or I bet I could just shuffle the interviewers) until it works or I exhaust the possibilities