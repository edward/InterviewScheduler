// Generated by CoffeeScript 1.6.3
(function() {
  var exampleBusyFree, exampleJSONresponseToBusyFree, interviewers;

  exampleJSONresponseToBusyFree = '{\n  "kind": "calendar#freeBusy",\n  "timeMin": "2013-11-30T05:00:00.000Z",\n  "timeMax": "2013-12-07T05:00:00.000Z",\n  "calendars": {\n    "interviewer@email.com": {\n      "busy": [\n        {\n          "start": "2013-12-02T15:00:00Z",\n          "end": "2013-12-02T15:15:00Z"\n        }\n      ]\n    }\n  }\n}';

  exampleBusyFree = JSON.parse(exampleJSONresponseToBusyFree);

  interviewers = busyFreeToInterviewers(exampleBusyFree);

  test("Conversion of JSON busy/free response to Interviewer instances", function() {
    ok(interviewers[0].email === 'interviewer@email.com', "Email converts");
    ok(interviewers[0].busy[0].start === "2013-12-02T15:00:00Z", "Start time converts");
    return ok(interviewers[0].busy[0].end === "2013-12-02T15:15:00Z", "End time converts");
  });

}).call(this);

/*
//@ sourceMappingURL=tests.map
*/
