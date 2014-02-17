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

params = parseParams()
console.log params
accessToken = params.access_token

isTokenValid = (accessToken, callback) ->
  tokenInfoUrl = "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=#{accessToken}"
  jQuery.getJSON(tokenInfoUrl)
    .done (json) ->
      validity = true if json.audience == googleClientId
      console.log "Checked validation of token with Google: #{validity}"
      callback(validity)
      validity
    .fail (jqxhr, textStatus, error) ->
      console.log "Request failed: #{textStatus} #{error}"
      callback(false)

  return undefined

isTokenValid params["access_token"], (validity) ->
  console.log "Is token valid? #{validity}"

getCalendarList = (accessToken) ->
  maxResults = 10
  url = "https://www.googleapis.com/calendar/v3/users/me/calendarList?maxResults=#{maxResults}&access_token=#{accessToken}"
  jQuery.getJSON(url)
    .done (json) ->
      console.log "Check out this sweet list of calendars:"
      console.log json
    .fail (jqxhr, textStatus, error) ->
      console.log "Request failed: #{textStatus} #{error}"

# getCalendarList accessToken

getBusyFree = (accessToken) ->
  url = "https://www.googleapis.com/calendar/v3/freeBusy?access_token=#{accessToken}"
  data = 
    timeMin: "2013-11-30T00:00:00-05:00"
    timeMax: "2013-12-07T00:00:00-05:00"
    timeZone: "-05:00"
    items: [
      {id: "willem.vanbergen@jadedpixel.com"}
      {id: "justin.mutter@jadedpixel.com"}
    ]

  jQuery.ajax 
    type: "POST",
    url: url,
    data: JSON.stringify(data),
    success: (json) ->
      console.log "Check out this awesome busy/free list:"
      console.log json
    dataType: 'json',
    contentType: 'application/json'

getBusyFree accessToken

knownEmailAddresses = ['willem.vanbergen@jadedpixel.com', 'aaron.olson@shopify.com', 'cody@shopify.com', 'florian.weingarten@shopify.com']

for email in knownEmailAddresses
  $('select[name="email-addresses"]').append("<option>#{email}</option>")

getEmailAddresses = ->
  emails = $('select[name="email-addresses"]').val()
  console.log emails

$("#go").click ->
  getEmailAddresses()


########

assert = (condition, message) ->
  throw message || "Assertion failed" unless condition

class Interviewer
  constructor: (@email, @slotsAvailable) ->

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

today = new Date
console.log nextDay today, 1
console.log nextDay today, 2
console.log nextDay today, 3
console.log comingWeek

exampleJSONresponseToBusyFree = '''
{
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
'''
busyFree = JSON.parse(exampleJSONresponseToBusyFree)
console.log busyFree

interviewers = []

interviewers.push new Interviewer email = "willem@bla.com", slotsAvailable = ['some', 'slots']

# for interviewer busyFree