Mixto = require 'mixto'

merge = require 'lodash.merge'

AEvent = require 'a-event-format'

AType = require 'a-cli-type-inference'

AEventEmitter = require 'a-event-emitter'

class ACliParser extends Mixto

  constructor: (@options={}) ->

    super

  extended: () ->

    _options = () =>

      @options ?= {}

      @options.parserArgv ?= process.argv

      @options.parserDelegateCommands ?= true

      @options.parserEventNamespace ?= "cli-parser"

      @options.parserDefaultCommand ?= "cli"

      if @options.parserCommands

        @commands @options.parserCommands

    _options()

    _mixins = () =>

      @options.eventNamespace ?= @options.parserEventNamespace

      AEventEmitter.extend @

    _mixins()

    _methods = () =>

      emit = @emit

      @emit = (args) =>

        event = args.shift()

        event = "#{event}.#{@options.eventNamespace}"

        return emit.apply @, [event].concat args

  argv: (args) ->

    if not @_argv

      @_argv =

        _: []

        $: []

        commands: {}

    @_argv.commands ?= {}

    if args

      @_argv._ = [].concat args.slice(2), "--"

      @_argv.$ = []

      @_argv.command = []

      @_argv.triggers = []

    return @_argv

  commands: (commands) ->

    if commands

      if Array.isArray commands

        for command in commands

          _command = @argv().commands[command.name] or {}

          @argv().commands[command.name] = merge(

            _command, command

          )

      else if typeof commands is "object"

        for name, command of commands

          command.name ?= name

          for name, option of command.options

            option.name ?= name

          _command = @argv().commands[command.name] or {}

          @argv().commands[command.name] = merge(

            _command, command

          )

    return @argv().commands

  option: (name, value) ->

    name: "#{name}"

    command: @_command.name

    value: value

    type: AType.type(value).type

  value: (option, value) ->

    value ?= option.default

    infered = AType.type value

    if infered.type is option.type

      value = infered.value

    else

      if option.type is "string" then value =  ""

      else if option.type is "boolean" then value = true

      else if option.type is "array" then value = []

    return value

  triggerOptions: (triggers) ->

    if Array.isArray triggers

      triggers.map (name) =>

        if not @_argv.triggers[name]

          if option = @_command.options[name]

            value = @value option, value

            @_argv.triggers[name] = @option name, value

            if option.triggers then @triggerOptions option.triggers

    else if typeof triggers is "object"

      for name, value of triggers

        if not @_argv.triggers[name]

          if option = @_command.options[name]

            value = @value option, value

            @_argv.triggers[name] = @option name, value

            if option.triggers then @triggerOptions option.triggers

  parse: (args=@options.parserArgv, commands=@options.parserCommands) ->

    @enabled = true

    argv = @argv args

    commands = @commands commands

    _parse = () =>

      while arg = argv._.shift()

        switch

          when arg is "--"

            argv.$.push new AEvent

              name: "stack"

            @options.parserDelegateCommands = true

          when arg.match /^--(\w+-*)*\w+$/ then argv.$.push new AEvent

            name: "option-name"

            args: [arg.replace(/^-+/, '')]

          when arg.match /^-\w{1}/ then argv.$.push new AEvent

            name: "option-alias"

            args: [arg.replace(/^-+/, '')]

          else

            if @options.parserDelegateCommands and @commands()[arg]

              @options.parserDelegateCommands = false

              argv.$.push new AEvent

                name: "command"

                args: [arg]

            else if not argv.$.length > 0

              throw new Error "unexpected value #{arg}"

            else

              { name } = option = argv.$[argv.$.length-1]

              if name is "option-name" or name is "option-alias"

                option.args.push arg

                argv.$.push new AEvent

                  name: "value"

                  args: [arg]

      return argv.$

    events = _parse()

    events.map (e) => @emit.apply @, ["#{e.name}"].concat e.args

    return events

  "command?": (command) ->

    commands = @commands()

    if commands[command] then @_command = commands[command]

  "option-name?": (name, value) ->

    @_command ?= @commands()[@options.parserDefaultCommand]

    option = @_command.options[name]

    if option

      value = @value option, value

      @_argv.command.push @option name, value

      if triggers = option.triggers

        @triggerOptions triggers

  "option-alias?": (alias, value) ->

    @_command ?= @commands()[@options.parserDefaultCommand]

    alias = alias.split('').reverse()

    for char in alias

      for name, option of @_command.options

        if option.alias is char

          @emit "option-name", name, value

          value = null

  "stack?": () ->

    @_command ?= @commands()[@options.parserDefaultCommand]

    if triggers = @_command.triggers

      @triggerOptions triggers

    stack =

      args: {}

      name: @_command.name

      options: @_argv.command

    stack.options.map (option) ->

      stack.args[option.name] = option.value

    triggers = []

    for name, trigger of @_argv.triggers

      if not stack.args[name]

        stack.args[name] = trigger.value

        triggers.push trigger

    stack.options = triggers.concat stack.options

    if "help" of stack.args then stack.options = []

    @emit "after", stack

    @_argv.command = []

module.exports = ACliParser
