# 用jQuery覆盖掉人人自带的$
$ = window.jQuery

AutoGroup =

    init: ->
        @NO_GROUP_NAME = '未分组好友'
        @SHARED_FRIEND_URL_TMPL = _.template 'http://friend.renren.com/shareFriends?p=
                    {%22init%22:true,%22uid%22:true,%22uhead%22:false,%22uname%22:false,
                    %22group%22:false,%22net%22:false,%22param%22:{%22guest%22:<%=uid%>}}'

        @createInitBtn()

    createInitBtn: ->
        html = '<div class="auto-group-btn-container">
                     <a href="javascript:void(0)" class="auto-group-btn">自动分组</a>
                 </div>'
        @btn = $(html).insertAfter('#groupList').click => @start()

    start: ->
        @friends = window.friends.map (friend) ->
            _.pick friend, 'name', 'id', 'head', 'groups'
        @group_names = $('#groupList li').map (index, element) -> element.title
        @group_names = _.without @group_names, @NO_GROUP_NAME

        # 加载我与这些好友的共同好友列表
        @loadSharedFriends =>
            console.log "all loaded"
            @calculate()

    loadSharedFriends: (callback) ->
        m_alert = XN.DO.alert
            modal: true
            title: '获取共同好友信息，请稍等'
            message: '加载中..'
        m_alert.footer.hide()

        [complete_count, friend_count] = [0, @friends.length]

        $queue = $ {}
        @friends.forEach (friend, index) =>
            $queue.queue 'ajaxQueue', (next) =>
                url = @SHARED_FRIEND_URL_TMPL uid: friend.id
                $.getJSON url, (data) ->
                    complete_count += 1
                    m_alert.body.innerHTML = "进度：#{complete_count}/#{friend_count}"
                    friend.sharedFriends = _.pluck data.candidate, 'id'
                    next()

        $queue.queue 'ajaxQueue', =>
            m_alert.hide()
            callback.call @
        $queue.dequeue 'ajaxQueue'

    score: (friend1, friend2) ->
        _.intersection(friend1.sharedFriends, friend2.sharedFriends).length

    avgScore: (friends, friend)->
        if not friends.length
            return 0
        else
            scores = ( @score(tmp_friend, friend) for tmp_friend in friends )
            sum = _.reduce scores, (memo, num) -> memo + num
            return sum / friends.length

    calculate: ->
        m_alert = XN.DO.alert
            modal: true
            title: '努力计算中，请稍等'
            message: '计算中...'
        m_alert.footer.hide()

        group_len = @group_names.length
        # 分组名到index的映射
        group_name2index = _.object @group_names, _.range group_len

        # 计算现在的分组关系
        groups = _.range(group_len).map -> [] #[ [], [], [], ... ]
        @friends.forEach (friend) ->
            friend.groups.forEach (group_name) ->
                groups[group_name2index[group_name]].push friend
        console.log groups

        bestmatches = no_group = null
        for t in _.range(20)
            console.log "Iteration", t
            bestmatches = ([] for i in [0..group_len-1])
            no_group = []

            @friends.forEach (friend) =>
                avg_scores = ( @avgScore(group, friend) for group in groups )
                if not _.any(avg_scores)
                    no_group.push friend
                else
                    best = 0
                    avg_scores.forEach (score, index) ->
                        if score > avg_scores[best]
                            best = index
                    bestmatches[best].push friend

            if bestmatches == groups
                break
            else
                groups = bestmatches

        @over groups

    over: (groups) ->
        console.log groups
                

 

AutoGroup.init()
window.AutoGroup = AutoGroup
