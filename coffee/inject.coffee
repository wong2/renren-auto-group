# 把underscore和auto_group.js插到页面里去

inject = (name, callback) ->
    s = document.createElement 'script'
    s.src = chrome.extension.getURL 'js/' + name
    s.onload = callback or ->
    document.head.appendChild s

injectContent = (content) ->
    s = document.createElement 'script'
    s.type = 'text/webworker'
    s.textContent = content
    s.id = 'chrome-auto-group-worker-content'
    document.body.appendChild s


inject 'underscore-min.js', ->
    inject 'auto_group.js'

# 加载worker文件并插入页面一个script里
xhr = new XMLHttpRequest
xhr.onreadystatechange = ->
    if xhr.readyState == 4 and xhr.status == 200
        injectContent xhr.responseText
xhr.open 'GET', chrome.extension.getURL('js/calculate.js'), true
xhr.send null
