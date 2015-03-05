describe 'ACliParser', () ->

  it 'before', () ->

    kosher.alias 'fixture', kosher.spec.fixtures.parser

    kosher.alias 'instance', new kosher.fixture.A

  describe 'methods', () ->

    describe 'constructor', () ->

      it 'expects a options object', () ->

    describe 'commands', () ->

      it 'should allow CliParser.commands to be set explicitly', () ->

        commands =

          "hello":

            options:

              long:

                alias: "l"

                type: "string"

          "world":

            options:

              short:

                alias: "s"

                type: "string"

              multiple:

                alias: "m"

                type: "string"

                triggers:

                  triggered: 200

                default: "multiple"

              triggered:

                default: 900

        kosher.instance.commands commands

        Object.keys(kosher.instance.commands()).should.eql ["hello", "world"]

    describe 'parse', () ->

      it 'should be able to parse multiple commands', () ->

        events = kosher.instance.parse kosher.argv "hello", "--", "world"

        events.map((e) -> return e.name).should.eql [
          "command", "stack"
          "command", "stack"
        ]

      it 'shoud associate option names with commands', () ->

        events = kosher.instance.parse kosher.argv "hello", "--long", "long"

        events.map((e) -> return e.args).should.eql [

          ["hello"], ["long", "long"], ["long"], []

        ]

        events.map((e) -> return e.name).should.eql [

          "command", "option-name", "value", "stack"

        ]

      it 'shoud associate single option alias with commands', () ->

        events = kosher.instance.parse kosher.argv "hello", "-l", "long"

        events.map((e) -> return e.args).should.eql [

          ["hello"], ["l", "long"], ["long"], []

        ]

        events.map((e) -> return e.name).should.eql [

          "command", "option-alias", "value", "stack"

        ]

      it 'shoud associate multiple option alias with commands', () ->

        events = kosher.instance.parse kosher.argv "world", "-sm", "multiple"

        events.map((e) -> return e.args).should.eql [

          ["world"], ["sm", "multiple"], ["multiple"], []

        ]

        events.map((e) -> return e.name).should.eql [

          "command", "option-alias", "value", "stack"

        ]

      it 'should set the command when command event is triggered', () ->

        kosher.instance.parse kosher.argv "world", "-sm", "value"

    describe 'properties', () ->

      describe 'options', () ->
