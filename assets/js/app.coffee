socket = io.connect()

$.scrollBottom = () ->
  $('body').trigger 'scrollBottom'

$ ->
  $('body').on 'scrollBottom', ->
    m = $('body, html')
    m.scrollTop m[0].scrollHeight

  appendMessage = (message) ->
    handlers =
      TextMessage: (message) ->
        messageEl = $("""
          <div class="media message" data-user-id="#{message.user_id}">
            <a class="pull-left" href='#'>
              <img class="media-object" src="http://www.gravatar.com/avatar/#{message.user.emailHash}?s=32">
            </a>
            <div class="media-body">
              <h5 class="media-heading">#{message.user.name}</h5>
              <p>#{message.body}</p>
            </div>
          </div>
        """)

        $('#messages').append messageEl

        previous = messageEl.prev()
        sameUser = previous.data('user-id') is message.user_id

        if sameUser
          messageEl.find('a.pull-left').html '<div class="placeholder">&nbsp;</div>'
          messageEl.find('h5').remove()

      TimestampMessage: (message) ->
        $('#messages').append $("""
          <div class="meta timestamp">
            <time datetime="#{message.created_at}">#{moment(message.created_at).format 'h:mm a'}</time>
          </div>
        """)

      EnterMessage: (message) ->
        $('#messages').append $("""
          <div class="meta enter-exit enter">
            #{message.user.name} has entered the room.
          </div>
        """)

      KickMessage: (message) ->
        $('#messages').append $("""
          <div class="meta enter-exit exit">
            #{message.user.name} has left the room.
          </div>
        """)

      LeaveMessage: (message) ->
        $('#messages').append $("""
          <div class="meta enter-exit exit">
            #{message.user.name} has left the room.
          </div>
        """)


    handlers[message.type](message) if handlers[message.type]
    console.log message unless handlers[message.type]

  socket.on 'recent',  (messages) ->
    appendMessage message for message in messages
    $.scrollBottom()

  socket.on 'message', (message) ->
    $scope.messages.push message
    $.scrollBottom()

