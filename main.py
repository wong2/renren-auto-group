#-*-coding:utf-8-*-

import json
import random


def loadFriends():
    with open("friends.json") as fp:
        return json.loads(fp.read())

def loadShareFriends(uid):
    with open("friends/" + str(uid) + ".json") as fp:
        return json.loads(fp.read())

friends = loadFriends()
print "You have ", len(friends), " friends."

id2name = {}
vector = {}
cache = {}

for friend in friends:
    uid = friend["id"]
    id2name[uid] = friend["name"]
    vector[uid] = [friend["id"] for friend in loadShareFriends(uid)]

def score(uid1, uid2):
    if not uid1 in cache:
        cache[uid1] = {}
    if not uid2 in cache[uid1]:
        result = len(set(vector[uid1]) & set(vector[uid2]))
        cache[uid1][uid2] = result
    else:
        result = cache[uid1][uid2]
    return result

def avgScore(clustered, uid):
    if len(clustered) == 0:
        return 0
    return 1.0 * sum(map(lambda x: score(x, uid), clustered)) / len(clustered)

"""
clusters = [ 
    [254929290, 272079126, 257341505, 252278630, 247470194], 
    [255008330, 251097835, 335303442, 251668975, 280215520, 278783035, 229553860], 
    [284861914, 311296261, 255647749], 
    [42033604, 228847846, 230961237, 85432256, 1920648986, 30314], 
    [269402888],
    [269402888, 239384288, 222785680, 179945202, 315022897, 262195161, 249793012, 319621581], 
    [249488460, 257426685, 277640852, 228537234, 275424842, 229889874]
]
"""

k = 7

friends_count = len(friends)

clusters = [ [ friends[random.randint(0, friends_count-1)]["id"] ] for i in range(k)]
print clusters

bestmatches = None
for t in range(20):
    print "Iteration ", t
    bestmatches = [[] for i in range(k)]
    no_group = []

    for friend in friends:
        uid = friend["id"]
        avg_scores = [avgScore(clusters[i], uid) for i in range(k)]

        if not any(avg_scores):
            no_group.append(uid)
            continue

        best = 0
        for i, avg_score in enumerate(avg_scores):
            if avg_score > avg_scores[best]:
                best = i
        bestmatches[best].append(uid)

    if bestmatches == clusters:
        break

    clusters = bestmatches

group_names = ["高中同学", "HUST", "初中同学", "同事", "家人", "技术", "政治"]

for i, group in enumerate(clusters):
    #print group_names[i], ": "
    for uid in group:
        print id2name[uid],
    print "\n"

#print "未分组："
for uid in no_group:
    print id2name[uid],

