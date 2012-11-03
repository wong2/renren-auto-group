# 用jQuery覆盖掉人人自带的$
$ = window.jQuery

AutoGroup =

    init: ->
        @NO_GROUP_NAME = '未分组好友'
        @SHARED_FRIEND_URL_TMPL = _.template 'http://friend.renren.com/shareFriends?p=
                    {%22init%22:true,%22uid%22:true,%22uhead%22:false,%22uname%22:false,
                    %22group%22:false,%22net%22:false,%22param%22:{%22guest%22:<%=uid%>}}'

        @createButtons()

    createButtons: ->
        html = '<div class="auto-group-btn-container">
                    <a href="javascript:void(0)" class="backup-group-btn">备份分组</a>
                </div>
                <div class="auto-group-btn-container">
                    <a href="javascript:void(0)" class="restore-group-btn">恢复分组</a>
                </div>
                <div class="auto-group-btn-container">
                    <a href="javascript:void(0)" class="auto-group-btn">自动分组</a>
                </div>'
        container = $(html).insertAfter '#groupList'
        container.delegate '.backup-group-btn', 'click', => @backup()
        container.delegate '.restore-group-btn', 'click', => @restore()
        container.delegate '.auto-group-btn', 'click', => @start()

    backup: ->
        m_alert = XN.DO.alert
            modal: true
            message: '正在备份当前分组信息...'

        m_alert.footer.hide()

        friends = window.friends.map (friend) ->
            _.pick friend, 'id', 'groups'
        groups = {}
        friends.forEach (friend) ->
            friend.groups.forEach (group_name) ->
                if group_name of groups
                    groups[group_name].push friend.id
                else
                    groups[group_name] = [friend.id]
        localStorage.chromeAutoGroupBackup = JSON.stringify(groups)
        m_alert.body.innerHTML = "当前分组信息已备份"
        setTimeout ->
            m_alert.remove()
        , 2000

    restore: ->
        backup = localStorage.chromeAutoGroupBackup
        if not backup
            XN.DO.showError "没有备份过啊亲~"
        else
            m_alert = XN.DO.alert "正在恢复备份的分组信息..."
            m_alert.footer.hide()

            groups = JSON.parse backup

            [count, group_count] = [0, _.size groups]
            _.each groups, (uids, group_name) =>
                @groupAdd group_name, uids, ->
                    count += 1
                    if count >= group_count
                        m_alert.body.innerHTML = "已恢复到备份的分组，将要刷新页面..."
                        setTimeout ->
                            m_alert.remove()
                            location.reload()
                        , 1000

    start: ->
        @friends = window.friends.map (friend) ->
            _.pick friend, 'name', 'id', 'head', 'groups'
        @group_names = $('#groupList li').map (index, element) -> element.title
        @group_names = _.without @group_names, @NO_GROUP_NAME

        # 加载我与这些好友的共同好友列表
        @loadSharedFriends =>
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
            m_alert.remove()
            setTimeout =>
                callback.call @
            , 500
        $queue.dequeue 'ajaxQueue'

    calculate: ->
        m_alert = XN.DO.alert
            modal: true
            title: '努力计算中，请稍等'
            message: '计算中...'
        m_alert.footer.hide()

        friends_len = @friends.length
        group_len = @group_names.length
        # 分组名到index的映射
        group_name2index = _.object @group_names, _.range group_len

        # 计算现在的分组关系
        groups = _.range(group_len).map -> [] #[ [], [], [], ... ]
        @friends.forEach (friend) ->
            friend.groups.forEach (group_name) ->
                groups[group_name2index[group_name]].push friend

        # 去web worker里计算
        worker_content = document.getElementById('chrome-auto-group-worker-content').textContent
        blob = new Blob([worker_content])
        worker = new Worker (window.webkitURL || window.URL).createObjectURL blob
        worker.onmessage = (e) =>
            data = e.data
            if data.type == 'process'
                # 计算过程中，更新弹窗内容，告知进度
                m_alert.body.innerHTML = "第#{data.loop}轮: #{data.process}%"
            else if data.type == 'over'
                m_alert.remove()
                @saveNewGroup groups, data.groups

        # 启动worker
        worker.postMessage
            type:'start'
            groups: groups
            friends: @friends
        

    saveNewGroup: (old_groups, new_groups) ->
        console.log new_groups

        m_alert = XN.DO.alert
            modal: true
            message: '添加好友到分组中..'
        m_alert.footer.hide()

        [count, group_count] = [0, new_groups.length]
        new_groups.forEach (users, index) =>
            new_user_ids = _.pluck users, 'id'
            old_user_ids = _.pluck old_groups[index], 'id'
            @groupAdd @group_names[index], _.union(new_user_ids, old_user_ids), =>
                count += 1
                if count >= group_count
                    m_alert.remove()
                    @over()

    groupAdd: (group_name, uids, callback=XN.func.empty) ->
        $.post 'http://friend.renren.com/editGroup.do',
            post: JSON.stringify {
                action: 'multiadd'
                name: group_name
                buddys: uids
            },
            callback

    over: ->
        XN.DO.showMessage '自动分组完成，即将刷新页面...'
        setTimeout ->
            location.reload()
        , 1000


AutoGroup.init()
window.AutoGroup = AutoGroup
