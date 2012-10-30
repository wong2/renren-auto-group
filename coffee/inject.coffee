# 把underscore和auto_group.js插到页面里去

inject = (name, callback) ->
    s = document.createElement 'script'
    s.src = chrome.extension.getURL 'js/' + name
    s.onload = callback or ->
    document.head.appendChild s

inject 'underscore-min.js', ->
    inject 'auto_group.js'
