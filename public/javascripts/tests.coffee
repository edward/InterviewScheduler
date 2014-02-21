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

test "Conversion of JSON busy/free response to Interviewer instances", ->
  ok interviewers[0].email is 'interviewer@email.com', "Email converts"
  ok interviewers[0].busy[0].start is "2013-12-02T15:00:00Z", "Start time converts"
  ok interviewers[0].busy[0].end is "2013-12-02T15:15:00Z", "End time converts"