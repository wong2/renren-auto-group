// Generated by CoffeeScript 1.3.3
(function() {
  var calculate, getAvgScore, getIntersectionLength, getScore, score_cache;

  score_cache = {};

  getIntersectionLength = function(a, b) {
    var d, results;
    d = {};
    b.forEach(function(item) {
      return d[item] = true;
    });
    results = a.filter(function(item) {
      return d[item];
    });
    return results.length;
  };

  getScore = function(friend1, friend2) {
    var uid1, uid2, _ref;
    _ref = [friend1.id, friend2.id], uid1 = _ref[0], uid2 = _ref[1];
    if (!(uid1 in score_cache)) {
      score_cache[uid1] = {};
    }
    if (!(uid2 in score_cache[uid1])) {
      score_cache[uid1][uid2] = getIntersectionLength(friend1.sharedFriends, friend2.sharedFriends);
    }
    return score_cache[uid1][uid2];
  };

  getAvgScore = function(friends, friend) {
    var scores, sum, tmp_friend;
    if (!friends.length) {
      return 0;
    } else {
      scores = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = friends.length; _i < _len; _i++) {
          tmp_friend = friends[_i];
          _results.push(getScore(tmp_friend, friend));
        }
        return _results;
      })();
      sum = 0;
      scores.forEach(function(score) {
        return sum += score;
      });
      return sum / friends.length;
    }
  };

  calculate = function(groups, friends) {
    var bestmatches, friends_len, group_len, i, no_group, t, _i, _ref,
      _this = this;
    _ref = [groups.length, friends.length], group_len = _ref[0], friends_len = _ref[1];
    groups.forEach(function(group) {
      var random_friend;
      if (group.length === 0) {
        random_friend = friends[Math.floor(Math.random() * friends_len)];
        return group.push(random_friend);
      }
    });
    bestmatches = no_group = null;
    for (t = _i = 0; _i <= 20; t = ++_i) {
      bestmatches = (function() {
        var _j, _ref1, _results;
        _results = [];
        for (i = _j = 0, _ref1 = group_len - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; i = 0 <= _ref1 ? ++_j : --_j) {
          _results.push([]);
        }
        return _results;
      })();
      no_group = [];
      friends.forEach(function(friend, index) {
        var avg_scores, best, group;
        if (index % 50 === 0) {
          self.postMessage({
            type: 'process',
            loop: t + 1,
            process: Math.floor((index + 1) / friends_len * 100)
          });
        }
        avg_scores = (function() {
          var _j, _len, _results;
          _results = [];
          for (_j = 0, _len = groups.length; _j < _len; _j++) {
            group = groups[_j];
            _results.push(getAvgScore(group, friend));
          }
          return _results;
        })();
        if (Math.max(avg_scores) === 0) {
          return no_group.push(friend);
        } else {
          best = 0;
          avg_scores.forEach(function(score, index) {
            if (score > avg_scores[best]) {
              return best = index;
            }
          });
          return bestmatches[best].push(friend);
        }
      });
      if (JSON.stringify(bestmatches) === JSON.stringify(groups)) {
        break;
      } else {
        groups = bestmatches;
      }
    }
    return self.postMessage({
      type: 'over',
      groups: groups
    });
  };

  self.onmessage = function(e) {
    var data;
    data = e.data;
    if (data.type === 'start') {
      return calculate(data.groups, data.friends);
    }
  };

}).call(this);
