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
        @groups = $('#groupList li').map (index, element) -> element.title
        @groups = _.without @groups, @NO_GROUP_NAME

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

    calculate: ->
        m_alert = XN.DO.alert
            modal: true
            title: '努力计算中，请稍等'
            message: '计算中...'
        m_alert.footer.hide()



 

AutoGroup.init()
window.AutoGroup = AutoGroup
