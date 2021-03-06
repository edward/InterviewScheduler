// Generated by CoffeeScript 1.7.1
(function() {
  var Interviewer, accessToken, allBusyFreeSlotsOn, assert, assertEqual, authorizationUrl, busyFreeToInterviewers, busyInterviewer, busyTime, doesTodayWorkAtAll, email, exampleBusyFree, exampleJSONresponseToBusyFree, exampleSuperBusy, exampleSuperBusyDayJSONresponseToBusyFree, freeSlots, freeSlotsCount, freeTime, getBusyFree, getEmailAddresses, givenDay, googleClientId, i, interviewer, interviewers, isTokenValid, knownBusyFreeSlots, knownEmailAddresses, nextDay, niceDateTimeFormat, params, parseParams, redirectUri, schedulesPossibleInNextWeek, slot, slotsThatWork, workingSlots, _i, _j, _len, _len1;

  knownEmailAddresses = ['willem.vanbergen@jadedpixel.com', 'aaron.olson@shopify.com', 'cody@shopify.com', 'florian.weingarten@shopify.com'];

  for (_i = 0, _len = knownEmailAddresses.length; _i < _len; _i++) {
    email = knownEmailAddresses[_i];
    $('select[name="email-addresses"]').append("<option>" + email + "</option>");
  }

  getEmailAddresses = function() {
    var emails;
    return emails = $('select[name="email-addresses"]').val();
  };

  googleClientId = '131318130111-kffqdc1iu7ot57s92ep3h36scsf2b38o.apps.googleusercontent.com';

  redirectUri = "http%3A%2F%2Flocalhost:4567/oauth2callback";

  authorizationUrl = "https://accounts.google.com/o/oauth2/auth?redirect_uri=" + redirectUri + "&response_type=token&client_id=" + googleClientId + "&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcalendar.readonly&approval_prompt=auto";

  $("button[name='authorize-with-google'").click(function() {
    console.log("Redirecting to Google authorization URL");
    return document.location.assign(authorizationUrl);
  });

  parseParams = function() {
    var chunk, params, queryString, regex;
    params = {};
    queryString = location.hash.substring(1);
    regex = /([^&=]+)=([^&]*)/g;
    while (chunk = regex.exec(queryString)) {
      params[decodeURIComponent(chunk[1])] = decodeURIComponent(chunk[2]);
    }
    return params;
  };

  isTokenValid = function(accessToken, callback) {
    var tokenInfoUrl;
    tokenInfoUrl = "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=" + accessToken;
    jQuery.getJSON(tokenInfoUrl).done(function(json) {
      var validity;
      if (json.audience === googleClientId) {
        validity = true;
      }
      return callback(validity);
    }).fail(function(jqxhr, textStatus, error) {
      console.log("Request failed: " + textStatus + " " + error);
      return callback(false);
    });
    return void 0;
  };

  params = parseParams();

  accessToken = params.access_token;

  if (accessToken) {
    isTokenValid(params["access_token"], function(validity) {
      console.log("Is token valid? " + validity);
      if (!validity) {
        return alert("Looks like we need to re-authenticate with Google. Could you try hitting that button again?");
      }
    });
  }

  getBusyFree = function(accessToken, emailAddresses, callback) {
    var currentDate, data, tenDaysFromNow, url;
    url = "https://www.googleapis.com/calendar/v3/freeBusy?access_token=" + accessToken;
    currentDate = new Date;
    tenDaysFromNow = nextDay(currentDate, 10);
    data = {
      timeMin: currentDate.toISOString(),
      timeMax: tenDaysFromNow,
      timeZone: "-05:00",
      items: (function() {
        var _j, _len1, _results;
        _results = [];
        for (_j = 0, _len1 = emailAddresses.length; _j < _len1; _j++) {
          email = emailAddresses[_j];
          _results.push({
            "id": email
          });
        }
        return _results;
      })()
    };
    return jQuery.ajax({
      type: "POST",
      url: url,
      data: JSON.stringify(data),
      success: function(json) {
        return callback(json);
      },
      dataType: 'json',
      contentType: 'application/json'
    });
  };

  Interviewer = (function() {
    function Interviewer(email, busy) {
      this.email = email;
      this.busy = busy;
    }

    return Interviewer;

  })();

  busyFreeToInterviewers = function(busyFree) {
    var rest, _ref, _results;
    _ref = busyFree.calendars;
    _results = [];
    for (email in _ref) {
      rest = _ref[email];
      _results.push(new Interviewer(email, rest.busy));
    }
    return _results;
  };

  Interviewer.prototype.isFreeAtTime = function(queryTime) {
    var busyTime, endTime, free, startTime, _j, _len1, _ref;
    free = true;
    queryTime = new Date(queryTime);
    _ref = this.busy;
    for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
      busyTime = _ref[_j];
      startTime = new Date(busyTime.start);
      endTime = new Date(busyTime.end);
      if (startTime <= queryTime && endTime >= queryTime) {
        free = false;
        break;
      }
    }
    return free;
  };

  Interviewer.prototype.busyFreeSlotsOn = function(day) {
    var advanceHour, freeSlots;
    day = new Date(day);
    day.setMinutes(0);
    day.setSeconds(0);
    freeSlots = (function() {
      var _j, _results;
      _results = [];
      for (advanceHour = _j = 0; _j < 7; advanceHour = ++_j) {
        day.setHours(10 + advanceHour);
        _results.push({
          free: this.isFreeAtTime(day),
          time: day.toString()
        });
      }
      return _results;
    }).call(this);
    return freeSlots;
  };

  Interviewer.prototype.freeSlotsCount = function(day) {
    var freeSlot, freeSlots;
    freeSlots = (function() {
      var _j, _len1, _ref, _results;
      _ref = this.busyFreeSlotsOn(day);
      _results = [];
      for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
        freeSlot = _ref[_j];
        if (freeSlot.free === true) {
          _results.push(freeSlot);
        }
      }
      return _results;
    }).call(this);
    return freeSlots.length;
  };

  allBusyFreeSlotsOn = function(day, interviewers) {
    var interviewer, _j, _len1, _results;
    _results = [];
    for (_j = 0, _len1 = interviewers.length; _j < _len1; _j++) {
      interviewer = interviewers[_j];
      _results.push(interviewer.busyFreeSlotsOn(day));
    }
    return _results;
  };

  doesTodayWorkAtAll = function(day, interviewers) {
    var freeSlots, interviewer, totalFreeSlots, _j, _len1;
    totalFreeSlots = 0;
    for (_j = 0, _len1 = interviewers.length; _j < _len1; _j++) {
      interviewer = interviewers[_j];
      freeSlots = interviewer.freeSlotsCount(day);
      if (freeSlots < 1) {
        return false;
      }
      totalFreeSlots = freeSlots + totalFreeSlots;
    }
    if (totalFreeSlots < interviewers.length) {
      return false;
    }
    return true;
  };

  slotsThatWork = function(day, interviewers) {
    var allPermutations, interviewerOrder, timeSlot, timeSlots, timeSlotsForGivenInterviewerPermutation, _j, _len1, _ref;
    if (!doesTodayWorkAtAll(day, interviewers)) {
      return [];
    }
    timeSlots = (function() {
      var _j, _len1, _ref, _results;
      _ref = interviewers[0].busyFreeSlotsOn(day);
      _results = [];
      for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
        timeSlot = _ref[_j];
        _results.push(timeSlot.time);
      }
      return _results;
    })();
    timeSlotsForGivenInterviewerPermutation = function(day, interviewers) {
      var interviewer, interviewerSlot, interviewersAvailable, workingSlots, _j, _k, _len1, _len2;
      interviewersAvailable = (function() {
        var _j, _len1, _results;
        _results = [];
        for (_j = 0, _len1 = interviewers.length; _j < _len1; _j++) {
          interviewer = interviewers[_j];
          _results.push({
            "interviewer": interviewer,
            "selected": false
          });
        }
        return _results;
      })();
      workingSlots = [];
      for (_j = 0, _len1 = timeSlots.length; _j < _len1; _j++) {
        timeSlot = timeSlots[_j];
        for (_k = 0, _len2 = interviewersAvailable.length; _k < _len2; _k++) {
          interviewerSlot = interviewersAvailable[_k];
          if ((interviewerSlot.selected !== true) && interviewerSlot.interviewer.isFreeAtTime(timeSlot)) {
            workingSlots.push({
              "timeSlot": timeSlot,
              "interviewer": interviewerSlot.interviewer.email
            });
            interviewerSlot.selected = true;
            break;
          }
        }
        if (workingSlots.length === interviewers.length) {
          break;
        }
      }
      return workingSlots;
    };
    allPermutations = function(input) {
      var permArr, permute, usedElements;
      permArr = [];
      usedElements = [];
      permute = function(input) {
        var element, i;
        i = 0;
        while (i < input.length) {
          element = input.splice(i, 1)[0];
          usedElements.push(element);
          if (input.length === 0) {
            permArr.push(usedElements.slice());
          }
          permute(input);
          input.splice(i, 0, element);
          usedElements.pop();
          i++;
        }
        return permArr;
      };
      return permute(input);
    };
    _ref = allPermutations(interviewers);
    for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
      interviewerOrder = _ref[_j];
      timeSlots = timeSlotsForGivenInterviewerPermutation(day, interviewerOrder);
      if (timeSlots.length === interviewers.length) {
        return timeSlots;
      }
    }
    return [];
  };

  schedulesPossibleInNextWeek = function(interviewers) {
    var comingWeek, day, i, today, workingSlots, _j, _len1, _results;
    today = new Date();
    comingWeek = (function() {
      var _j, _results;
      _results = [];
      for (i = _j = 0; _j <= 6; i = ++_j) {
        _results.push(nextDay(today, i));
      }
      return _results;
    })();
    _results = [];
    for (_j = 0, _len1 = comingWeek.length; _j < _len1; _j++) {
      day = comingWeek[_j];
      _results.push(workingSlots = slotsThatWork(day, interviewers));
    }
    return _results;
  };

  $("#go").click(function() {
    var emailAddresses;
    emailAddresses = getEmailAddresses();
    return getBusyFree(accessToken, emailAddresses, function(busyFree) {
      var dateTime, day, interviewer, interviewers, schedules, slot, _j, _len1, _results;
      interviewers = busyFreeToInterviewers(busyFree);
      schedules = schedulesPossibleInNextWeek(interviewers);
      console.log(schedules);
      _results = [];
      for (_j = 0, _len1 = schedules.length; _j < _len1; _j++) {
        day = schedules[_j];
        _results.push((function() {
          var _k, _len2, _results1;
          _results1 = [];
          for (_k = 0, _len2 = day.length; _k < _len2; _k++) {
            slot = day[_k];
            interviewer = slot.interviewer;
            dateTime = niceDateTimeFormat(new Date(slot.timeSlot));
            _results1.push($("#schedule-results").append("<tr><td>" + interviewer + "</td> <td>" + dateTime + "</td></tr>"));
          }
          return _results1;
        })());
      }
      return _results;
    });
  });

  assert = function(condition, message) {
    if (!condition) {
      throw message || "Assertion failed";
    }
  };

  assertEqual = function(expected, actual, message) {
    if (expected !== actual) {
      throw message || console.log("Assertion failed; expected " + expected + " but was " + actual);
    }
  };

  nextDay = function(day, advance) {
    var date;
    date = new Date(day);
    date.setHours(0);
    date.setMinutes(0);
    date.setSeconds(0);
    date.setHours(24 * advance);
    return date;
  };

  niceDateTimeFormat = function(date) {
    var options;
    options = {
      weekday: "long",
      day: "numeric",
      month: "long",
      hour: "numeric",
      minute: "numeric",
      hour12: true
    };
    return date.toLocaleString("en-CA", options);
  };

  exampleJSONresponseToBusyFree = '{\n  "kind": "calendar#freeBusy",\n  "timeMin": "2013-11-30T05:00:00.000Z",\n  "timeMax": "2013-12-07T05:00:00.000Z",\n  "calendars": {\n    "interviewer@email.com": {\n      "busy": [\n        {\n          "start": "2013-12-02T15:00:00Z",\n          "end": "2013-12-02T15:15:00Z"\n        }\n      ]\n    }\n  }\n}';

  exampleBusyFree = JSON.parse(exampleJSONresponseToBusyFree);

  interviewers = busyFreeToInterviewers(exampleBusyFree);

  assert(interviewers[0].email === 'interviewer@email.com');

  assert(interviewers[0].busy[0].start === "2013-12-02T15:00:00Z");

  assert(interviewers[0].busy[0].end === "2013-12-02T15:15:00Z");

  interviewer = interviewers[0];

  busyTime = "2013-12-02T15:00:00Z";

  freeTime = nextDay(busyTime, 1);

  assert(!interviewer.isFreeAtTime(busyTime));

  assert(interviewer.isFreeAtTime(freeTime));

  givenDay = "2013-12-02T15:00:00Z";

  knownBusyFreeSlots = [
    {
      "free": false,
      "time": "Mon Dec 02 2013 10:00:00 GMT-0500 (EST)"
    }, {
      "free": true,
      "time": "Mon Dec 02 2013 11:00:00 GMT-0500 (EST)"
    }, {
      "free": true,
      "time": "Mon Dec 02 2013 12:00:00 GMT-0500 (EST)"
    }, {
      "free": true,
      "time": "Mon Dec 02 2013 01:00:00 GMT-0500 (EST)"
    }, {
      "free": true,
      "time": "Mon Dec 02 2013 02:00:00 GMT-0500 (EST)"
    }, {
      "free": true,
      "time": "Mon Dec 02 2013 03:00:00 GMT-0500 (EST)"
    }, {
      "free": true,
      "time": "Mon Dec 02 2013 04:00:00 GMT-0500 (EST)"
    }
  ];

  freeSlots = interviewer.busyFreeSlotsOn(givenDay);

  for (i = _j = 0, _len1 = freeSlots.length; _j < _len1; i = ++_j) {
    slot = freeSlots[i];
    assert(slot.free === knownBusyFreeSlots[i].free);
  }

  givenDay = "2013-12-02T15:00:00Z";

  freeSlotsCount = interviewer.freeSlotsCount(givenDay);

  assert(freeSlotsCount === 6);

  assert(doesTodayWorkAtAll(givenDay, [interviewer]));

  exampleSuperBusyDayJSONresponseToBusyFree = '{\n  "kind": "calendar#freeBusy",\n  "timeMin": "2013-11-30T05:00:00.000Z",\n  "timeMax": "2013-12-07T05:00:00.000Z",\n  "calendars": {\n    "interviewer@email.com": {\n      "busy": [\n        {\n          "start": "2013-12-02T15:00:00Z",\n          "end": "2013-12-02T23:15:00Z"\n        }\n      ]\n    }\n  }\n}';

  exampleSuperBusy = JSON.parse(exampleSuperBusyDayJSONresponseToBusyFree);

  busyInterviewer = busyFreeToInterviewers(exampleSuperBusy)[0];

  assert(!doesTodayWorkAtAll(givenDay, [busyInterviewer]));

  workingSlots = slotsThatWork(givenDay, [interviewer, interviewer]);

  assert(workingSlots[0].timeSlot === "Mon Dec 02 2013 11:00:00 GMT-0500 (EST)");

  assert(workingSlots[1].timeSlot === "Mon Dec 02 2013 12:00:00 GMT-0500 (EST)");

}).call(this);

//# sourceMappingURL=interview-scheduler.map
