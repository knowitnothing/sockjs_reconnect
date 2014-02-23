__extend = (object, properties) ->
  for key, val of properties
    object[key] = val
  object

SockReconnect = (SockJS) ->
    class SockReconnect

        reconnect:
            reconnecting: false     # Are we reconnecting ?
            do_not_reconnect: false # Do (not) try to reconnect.

            reload_after_n: true
            max_retries: 30 # Try to reconnect this many times before reloading.
            reset_mult: 6   # After n attemps, restore the timeout to default.

            # Default timeout in ms.
            retry_timeout_ms: 1500 + Math.floor(Math.random() * 60)
            # After a failed attempt, multiply the current timeout by this much.
            retry_multiplier: 2

            retry_curr_multiplier: 0
            retry_curr_timeout: 0
            retry_count: 0 # Attempts so far.

        conn: null

        constructor: (@cli_path, options, @status_cb,
                      @cli_onmessage, @cli_onopen, @cli_onclose) ->
            __extend(@reconnect, options)

        update_status: =>
            if @reconnect.reconnecting
                if @status_cb?
                    @status_cb('reconnecting')
            else if (@conn == null or @conn.readyState != SockJS.OPEN)
                if @status_cb?
                    @status_cb('disconnected')
            else
                if @status_cb?
                    @status_cb('connected')

        connect: =>
            if @conn?
                @conn.close()
                @conn = null
            @conn = new SockJS(@cli_path)
            if @status_cb?
                @status_cb('connecting')
            
            @conn.onopen = @on_open
            @conn.onclose = @on_close
            @conn.onmessage = @cli_onmessage

        reconnect_reset: =>
            @reconnect.reconnecting = false
            @reconnect.retry_curr_timeout = 0
            @reconnect.retry_curr_multipler = 0
            @reconnect.retry_count = 0

        reconnect_try: (connfunc) =>
            if @reconnect.retry_count == @reconnect.max_retries
                # Failed to reconnect n times.
                @reconnect.reconnecting = false
                if @reconnect.reload_after_n
                    window.location.reload(true)
                return

            if not @reconnect.reconnecting
                # First attempt to reconnect.
                @reconnect.reconnecting = true
                @reconnect.retry_curr_timeout = @reconnect.retry_timeout_ms
                @reconnect.retry_curr_multipler = 1
                @reconnect.retry_count = 1
                connfunc()
            else
                @reconnect.retry_count += 1
                callback = =>
                    @reconnect.retry_curr_timeout *= @reconnect.retry_multiplier
                    @reconnect.retry_curr_multipler += 1
                    if @reconnect.retry_curr_multipler == @reconnect.reset_mult
                        @reconnect.retry_curr_timeout = @reconnect.retry_timeout_ms
                        @reconnect.retry_curr_multipler = 1
                    connfunc()
                setTimeout(callback, @reconnect.retry_curr_timeout)

        send: (data) =>
            @conn.send(data)

        on_open: =>
            @reconnect_reset()
            @update_status()
            if @cli_onopen?
                @cli_onopen()

        on_close: =>
            @conn = null
            @update_status()
            if @cli_onclose?
                @cli_onclose()
            if @reconnect.do_not_reconnect
                return
            @reconnect_try(@connect)
    return SockReconnect


if typeof define == "function" && define.amd
    define ["sockjs"],(SockJS) ->
        SockReconnect SockJS
else
    root = exports ? this
    root.SockReconnect = SockReconnect()
