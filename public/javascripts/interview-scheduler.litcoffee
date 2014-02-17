This is an idea for an interview scheduler.

General idea as follows:

1. Get a list of emails (likely like 5) and ask Google Calendar for those peoples’ busy/free times.

2. Figure out when all of those people can meet over the next week based on their busy/free times.

3. Print the possible schedules.

Start by setting some known emails. We could get these from Google Calendar’s `calendarList` API but let’s stay simple for now and hard-code them:

    knownEmailAddresses = ['willem.vanbergen@jadedpixel.com', 'aaron.olson@shopify.com', 'cody@shopify.com', 'florian.weingarten@shopify.com']

    for email in knownEmailAddresses
      $('select[name="email-addresses"]').append("<option>#{email}</option>")

    getEmailAddresses = ->
      emails = $('select[name="email-addresses"]').val()

Add a handler to get the email addresses

    $("#go").click ->
      emailAddresses = getEmailAddresses()
      getBusyFree accessToken, emailAddresses

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

    if accessToken
      isTokenValid params["access_token"], (validity) ->
        console.log "Is token valid? #{validity}"
        alert("Looks like we need to re-authenticate with Google. Could you try hitting that button again?") unless validity


Start by just getting the busy/free times:

    getBusyFree = (accessToken, emailAddresses) ->
      url = "https://www.googleapis.com/calendar/v3/freeBusy?access_token=#{accessToken}"
      currentDate = new Date
      tenDaysFromNow = new Date; tenDaysFromNow.setHours(currentDate.getHours() + 24 * 10)
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
          console.log "Check out this awesome busy/free list:"
          console.log json
        dataType: 'json',
        contentType: 'application/json'

What post results actually look like:

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

Ok, so now how do I figure out the times? Algorithms, man.

Use a big array?

Start with a function that tells me if one person is free at a time.

    isFreeAtATime = (busyTimes, time) -> 
      # The idea is that I perform a Date.parse to get 

    freeSlots = (busyTimes) ->
      # returns an array of times between 10am and 5pm (7 slots) indicating free/busy

    allSlots = (emails) ->
      # returns an array of free/busy arrays

    countAvailableSlots = (freeBusySlots) ->
      # returns number of available slots

Maybe keep freeBusySlots as an object that also links to names?

    slotsThatWork = (day, interviewers) ->
      interviewers
      workingSlots

Go through each hour of the interviewing day and see if the currently inspected slot works for any interviewers

      for timeframe in timeframes
        for interviewer in interviewers
          if doesTimeframeWork(interviewer, timeframe)
            workingSlots << [timeframe, interviewer]
            removeInterviewer(interviewer)
            break

      return workingslots
      # returns the slots that work matching with emails

    permutationsExhausted = ->
      # fill this in?

    permuteUntilSlotsWork = (interviewers) ->
      slotsThatWork = []
      permutations = 1
      while (slotsThatWork.length == interviewers || permutationsExhausted(interviewers, permutations))
        interviewers = permuteInterviewers(interviewers, permutations)
        slotsThatWork = slotsThatWork(day, interviewers)

    nextDay = (date, advance) ->
      date = new Date(today)
      date.setHours(0)
      date.setMinutes(0)
      date.setSeconds(0)
      date.setHours(24 * advance)
      date

    comingWeek = []
    today = new Date()
    for i in [0..6] by 1
      comingWeek.push nextDay(today, i)

    class Interviewer
      constructor: (@email, @slotsAvailable) ->

    interviewers = ['...']

    for day in comingWeek
      workingSlots = permuteUntilSlotsWork(day, interviewers)
      # print workingSlots

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

This feels a lot like the 8 queens problem.