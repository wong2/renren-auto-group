score_cache = {}

# 获取俩数组交集的长度
getIntersectionLength = (a, b) ->
    d = {}
    b.forEach (item) -> d[item] = true
    results = a.filter (item) -> d[item]
    return results.length

getScore = (friend1, friend2) ->
    [uid1, uid2] = [friend1.id, friend2.id]
    if not (uid1 of score_cache)
        score_cache[uid1] = {}
    if not (uid2 of score_cache[uid1])
        score_cache[uid1][uid2] = getSameLength friend1.sharedFriends, friend2.sharedFriends
    return score_cache[uid1][uid2]

# 计算一个人和一组人的分值的平均值
getAvgScore = (friends, friend)->
    if not friends.length
        return 0
    else
        scores = ( getScore(tmp_friend, friend) for tmp_friend in friends )
        sum = 0
        scores.forEach (score) -> sum += score
        return sum / friends.length

calculate = (groups, friends) ->
    [group_len, friends_len] = [groups.length, friends.length]

    groups.forEach (group) ->
        # 如果某组里还没有初始好友，随机一个进去
        if group.length == 0
            random_friend = friends[Math.floor(Math.random()*friends_len)]
            group.push random_friend

    bestmatches = no_group = null
    # 开始迭带，最多20轮
    for t in [0..20]
        bestmatches = ([] for i in [0..group_len-1])
        no_group = []

        friends.forEach (friend, index) =>
            if index % 50 == 0
                self.postMessage
                    type: 'process'
                    loop: t+1
                    process: Math.floor (index+1)/friends_len*100

            avg_scores = ( getAvgScore(group, friend) for group in groups )
            # 全是0的话，就是没有分组啦
            if Math.max(avg_scores) == 0
                no_group.push friend
            else
                #把它加到分值最高的组里
                best = 0
                avg_scores.forEach (score, index) ->
                    if score > avg_scores[best]
                        best = index
                bestmatches[best].push friend

        if JSON.stringify(bestmatches) == JSON.stringify(groups)
            break
        else
            groups = bestmatches

    self.postMessage
        type: 'over'
        groups: groups

self.onmessage = (e) ->
    data = e.data
    if data.type == 'start'
        calculate data.groups, data.friends
