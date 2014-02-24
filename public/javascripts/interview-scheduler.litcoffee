An idea for an interview scheduler
==================================

General idea as follows:

1. Get a short list of emails. Five of them, let’s say.

2. Ask Google Calendar for those peoples’ busy/free times.

3. Figure out when all of those people can meet a candidate on the same day on some day during the next week based on their busy/free times.

4. Print the possible schedules.


Getting some email addresses
----------------------------

Start by setting some known emails. We could get these from Google Calendar’s `calendarList` API but let’s stay simple for now and hard-code them:

    knownEmailAddresses = ['willem.vanbergen@jadedpixel.com', 'aaron.olson@shopify.com', 'cody@shopify.com', 'florian.weingarten@shopify.com']

    for email in knownEmailAddresses
      $('select[name="email-addresses"]').append("<option>#{email}</option>")

    getEmailAddresses = ->
      emails = $('select[name="email-addresses"]').val()

Asking Google for busy/free times
---------------------------------

With a list of email addresses, we can ask Google for when those folks are busy. Before being able to ask, we’re going to first have to authenticate with Google, which involves a couple steps:

1. Redirect to a Google auth URL/screen and have the user agree to the read-only calendar API permission we’re implicitly asking for in the redirect URL
2. Google redirects back to whatever we set the redirect URI to be when we configured the Google API client and appends some extra query parameters, like the access token needed to make API calls. In development, this redirect URI is something like `http://localhost:4567/oauth2callback`
3. Parse the access token out of the current URL
4. Validate that the token is legit and that there isn’t any tampering

Set up Google API authentication

    googleClientId = '131318130111-kffqdc1iu7ot57s92ep3h36scsf2b38o.apps.googleusercontent.com'
    redirectUri = "http%3A%2F%2Flocalhost:4567/oauth2callback"
    authorizationUrl = "https://accounts.google.com/o/oauth2/auth?redirect_uri=#{redirectUri}&response_type=token&client_id=#{googleClientId}&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcalendar.readonly&approval_prompt=auto"

    $("button[name='authorize-with-google'").click ->
      console.log "Redirecting to Google authorization URL"
      document.location.assign(authorizationUrl)

    parseParams = ->
      params = {}
      queryString = location.hash.substring(1)
      regex = /([^&=]+)=([^&]*)/g

      while chunk = regex.exec(queryString)
        params[decodeURIComponent(chunk[1])] = decodeURIComponent(chunk[2])

      params

    isTokenValid = (accessToken, callback) ->
      tokenInfoUrl = "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=#{accessToken}"
      jQuery.getJSON(tokenInfoUrl)
        .done (json) ->
          validity = true if json.audience == googleClientId
          callback(validity)
        .fail (jqxhr, textStatus, error) ->
          console.log "Request failed: #{textStatus} #{error}"
          callback(false)

      return undefined

    params = parseParams()
    accessToken = params.access_token

Check to see if there’s a known access token and that it’s valid and take action if invalid

    if accessToken
      isTokenValid params["access_token"], (validity) ->
        console.log "Is token valid? #{validity}"
        alert("Looks like we need to re-authenticate with Google. Could you try hitting that button again?") unless validity


Asking Google for when people are busy/free
-------------------------------------------

    getBusyFree = (accessToken, emailAddresses, callback) ->
      url = "https://www.googleapis.com/calendar/v3/freeBusy?access_token=#{accessToken}"
      currentDate = new Date
      tenDaysFromNow = nextDay(currentDate, 10)
      data = 
        timeMin: currentDate.toISOString()
        timeMax: tenDaysFromNow
        timeZone: "-05:00"
        items: ({"id": email} for email in emailAddresses)

      jQuery.ajax 
        type: "POST",
        url: url,
        data: JSON.stringify(data),
        success: (json) ->
          callback(json)
        dataType: 'json',
        contentType: 'application/json'

Figure out when everyone can meet
---------------------------------

Break out response into an Interviewer class instance

    class Interviewer
      constructor: (@email, @busy) ->

    busyFreeToInterviewers = (busyFree) ->
      for email, rest of busyFree.calendars
        new Interviewer(email, rest.busy)

Start with a function that tells me if one person is free at a time.

    Interviewer::isFreeAtTime = (queryTime) -> 
      free = true
      queryTime = new Date(queryTime)
      for busyTime in @busy
        startTime = new Date(busyTime.start)
        endTime = new Date(busyTime.end)
        if startTime <= queryTime and endTime >= queryTime
          free = false
          break
      free

I need to know what the day looks like in terms of 7 blocks of hour-long slots, representing the time between 10am and 5pm, which is usually when we conduct interviews. If any busy-times fall into one of these slots, then mark that slot as busy.

    Interviewer::busyFreeSlotsOn = (day) ->
      day = new Date(day)
      day.setMinutes(0)
      day.setSeconds(0)
      
      freeSlots = for advanceHour in [0...7]
        day.setHours(10 + advanceHour)
        {free: @.isFreeAtTime(day), time: day.toString()}
      freeSlots

    Interviewer::freeSlotsCount = (day) ->
      freeSlots = (freeSlot for freeSlot in @.busyFreeSlotsOn(day) when freeSlot.free is true)
      freeSlots.length

    allBusyFreeSlotsOn = (day, interviewers) ->
      # returns an array of free/busy arrays
      for interviewer in interviewers
        interviewer.busyFreeSlotsOn(day)

A cheap heuristic to see if this day works at all: check to see that each interviewer has at least one free slot and that there are at least as many free slots as interviewers requested

    doesTodayWorkAtAll = (day, interviewers) ->
      totalFreeSlots = 0
      for interviewer in interviewers
        freeSlots = interviewer.freeSlotsCount(day)
        if freeSlots < 1
          return false
        totalFreeSlots = freeSlots + totalFreeSlots
      return false if totalFreeSlots < interviewers.length

      return true

Go through each hour of the interviewing day and see if the currently inspected slot works for any interviewers

    slotsThatWork = (day, interviewers) ->
      return [] unless doesTodayWorkAtAll(day, interviewers)

      timeSlots = (timeSlot.time for timeSlot in interviewers[0].busyFreeSlotsOn(day))

Look through each time slot and interviewer to see if there’s someone free at that time and mark them as such if so. Permute the order of interviewers if it doesn’t work.

      timeSlotsForGivenInterviewerPermutation = (day, interviewers) ->
        interviewersAvailable = ({"interviewer": interviewer, "selected": false} for interviewer in interviewers)

        workingSlots = []

        for timeSlot in timeSlots
          for interviewerSlot in interviewersAvailable
            if (interviewerSlot.selected isnt true) && interviewerSlot.interviewer.isFreeAtTime(timeSlot)
              workingSlots.push {"timeSlot": timeSlot, "interviewer": interviewerSlot.interviewer.email}

              interviewerSlot.selected = true
              break
          break if workingSlots.length is interviewers.length

        workingSlots

      allPermutations = (input) ->
        # Adapted from http://stackoverflow.com/questions/9960908/permutations-in-javascript
        permArr = []
        usedElements = []

        permute = (input) ->
          i = 0
          while i < input.length
            element = input.splice(i, 1)[0]
            usedElements.push element
            permArr.push usedElements.slice() if input.length is 0
            permute input
            input.splice i, 0, element
            usedElements.pop()
            i++
          permArr
        permute(input)

Look at each of the possible non-repeated orderings of interviewers to see if there’s a fit for the day:

      for interviewerOrder in allPermutations(interviewers)
        timeSlots = timeSlotsForGivenInterviewerPermutation(day, interviewerOrder)
        return timeSlots if timeSlots.length is interviewers.length

      return []


    schedulesPossibleInNextWeek = (interviewers) ->
      today = new Date()
      comingWeek = for i in [0..6]
        nextDay(today, i)

      for day in comingWeek
        workingSlots = slotsThatWork(day, interviewers)


Putting it all together
-----------------------

Add a handler to get the email addresses and calculate a schedule that works upon a button click

    $("#go").click ->
      emailAddresses = getEmailAddresses()
      getBusyFree accessToken, emailAddresses, (busyFree) ->
        interviewers = busyFreeToInterviewers(busyFree)
        schedules = schedulesPossibleInNextWeek(interviewers)
        console.log schedules
        for day in schedules
          for slot in day
            interviewer = slot.interviewer
            dateTime = niceDateTimeFormat(new Date(slot.timeSlot))
            $("#schedule-results").append "<tr><td>#{interviewer}</td> <td>#{dateTime}</td></tr>"
        

Some handy utility functions
----------------------------

    assert = (condition, message) ->
      throw message || "Assertion failed" unless condition

    assertEqual = (expected, actual, message) ->
      throw message || console.log "Assertion failed; expected #{expected} but was #{actual}" unless expected is actual

    nextDay = (day, advance) ->
      date = new Date(day)
      date.setHours(0)
      date.setMinutes(0)
      date.setSeconds(0)
      date.setHours(24 * advance)
      date

    niceDateTimeFormat = (date) ->
      options = 
        weekday: "long", day: "numeric", month: "long",
        hour: "numeric", minute: "numeric", hour12: true
      date.toLocaleString("en-CA", options)

Some neato tests
----------------

Test conversion of busy/free data to Interviewer objects

    exampleJSONresponseToBusyFree = '''
    {
      "kind": "calendar#freeBusy",
      "timeMin": "2013-11-30T05:00:00.000Z",
      "timeMax": "2013-12-07T05:00:00.000Z",
      "calendars": {
        "interviewer@email.com": {
          "busy": [
            {
              "start": "2013-12-02T15:00:00Z",
              "end": "2013-12-02T15:15:00Z"
            }
          ]
        }
      }
    }
    '''
    exampleBusyFree = JSON.parse(exampleJSONresponseToBusyFree)

    interviewers = busyFreeToInterviewers exampleBusyFree

    assert interviewers[0].email is 'interviewer@email.com'
    assert interviewers[0].busy[0].start is "2013-12-02T15:00:00Z"
    assert interviewers[0].busy[0].end is "2013-12-02T15:15:00Z"

Test that Interviewer objects (an Interviewer) know if they are free at a given time

    interviewer = interviewers[0]
    busyTime = "2013-12-02T15:00:00Z"
    freeTime = nextDay(busyTime, 1)
    assert !interviewer.isFreeAtTime(busyTime)
    assert interviewer.isFreeAtTime(freeTime)

Test that an Interviewer can produce a list of time slots of when it is busy/free for a given day

    givenDay = "2013-12-02T15:00:00Z"
    knownBusyFreeSlots = [
      {"free": false, "time": "Mon Dec 02 2013 10:00:00 GMT-0500 (EST)"},
      {"free": true, "time": "Mon Dec 02 2013 11:00:00 GMT-0500 (EST)"},
      {"free": true, "time": "Mon Dec 02 2013 12:00:00 GMT-0500 (EST)"},
      {"free": true, "time": "Mon Dec 02 2013 01:00:00 GMT-0500 (EST)"},
      {"free": true, "time": "Mon Dec 02 2013 02:00:00 GMT-0500 (EST)"},
      {"free": true, "time": "Mon Dec 02 2013 03:00:00 GMT-0500 (EST)"},
      {"free": true, "time": "Mon Dec 02 2013 04:00:00 GMT-0500 (EST)"}
    ]

    freeSlots = interviewer.busyFreeSlotsOn(givenDay)
    for slot, i in freeSlots
      assert slot.free is knownBusyFreeSlots[i].free

Test that an Interviewer can tell you how many free slots they have for a given day

    givenDay = "2013-12-02T15:00:00Z"
    freeSlotsCount = interviewer.freeSlotsCount(givenDay)
    assert freeSlotsCount is 6

Test that we can tell early-on if a day is even scheduleable at all

    assert doesTodayWorkAtAll(givenDay, [interviewer])

    exampleSuperBusyDayJSONresponseToBusyFree = '''
    {
      "kind": "calendar#freeBusy",
      "timeMin": "2013-11-30T05:00:00.000Z",
      "timeMax": "2013-12-07T05:00:00.000Z",
      "calendars": {
        "interviewer@email.com": {
          "busy": [
            {
              "start": "2013-12-02T15:00:00Z",
              "end": "2013-12-02T23:15:00Z"
            }
          ]
        }
      }
    }
    '''
    exampleSuperBusy = JSON.parse(exampleSuperBusyDayJSONresponseToBusyFree)

    busyInterviewer = busyFreeToInterviewers(exampleSuperBusy)[0]

    assert !doesTodayWorkAtAll(givenDay, [busyInterviewer])

Test that given two Interviewers both busy in the morning but free later on a particular day that a working meeting schedule will be produced

    workingSlots = slotsThatWork(givenDay, [interviewer, interviewer])
    assert workingSlots[0].timeSlot is "Mon Dec 02 2013 11:00:00 GMT-0500 (EST)"
    assert workingSlots[1].timeSlot is "Mon Dec 02 2013 12:00:00 GMT-0500 (EST)"

Test that given two Interviewers with schedules that look like the following, that a working schedule is still produced

interviewer 1: 10am busy | 11am free
interviewer 2: 10am free | 11am busy





More thoughts on the fitting/optimization problem here
------------------------------------------------------

There must be a better way.

What if I were to represent each person’s schedule as a simplified array of hour blocks of the day, from 10am to 5pm, so 7 blocks. I mark the available slots, and then put the arrays next to each other, and then walk a path through the resulting graph and then back track when I have a problem. (This still feels very costly.)

Is there a way to use another dimension to better optimize the algorithm? Can I somehow stack the time slots on top of each other and see things topographically to see if a combination is even possible at all?

This feels a lot like the 8 queens problem.