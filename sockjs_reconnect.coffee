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

    eventHandlers:
        'reconnect': []
        'connect': []
        'open': []
        'close': []
        'message': []

    constructor: (@cli_path, options, @onmessage, @onopen, @onclose) ->
        # TODO add internal extend functionality
        $.extend(@reconnect, options)

    on: (event, handler)=>
        events = event.trim().split(/\s+/)
        for event in events
            handlers = @eventHandlers[event]
            handlers.push(handler)
        return this

    update_status: =>
        if @reconnect.reconnecting
            for handler in @eventHandlers['reconnect']
                handler()
        else if (@conn == null or @conn.readyState != SockJS.OPEN)
            for handler in @eventHandlers['close']
                handler()
        else
            for handler in @eventHandlers['open']
                handler()

    connect: =>
        if @conn?
            @conn.close()
            @conn = null
        @conn = new SockJS(@cli_path)
        for handler in @eventHandlers['connect']
            handler()

        @conn.onopen = @on_open
        @conn.onclose = @on_close
        @conn.onmessage = @on_message

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
        @onopen?()

    on_close: =>
        @conn = null
        @update_status()
        @onclose?()
        if @reconnect.do_not_reconnect
            return
        @reconnect_try(@connect)

    on_message: (args...)=>
        @onmessage?.apply(args)
        for handler in @eventHandlers['message']
            handler.apply(this.conn, args)

root = exports ? this
root.SockReconnect = SockReconnect
