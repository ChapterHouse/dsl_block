# DslBlock

DslBlock allows you to use classes to define blocks with commands for a Domain Specific Language. The commands are automatically relayed to your instance method.

## Installation

Add this line to your application's Gemfile:

    gem 'dsl_block'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dsl_block

## Usage

    class Foo < DslBlock
      commands :show_foo
      def show_foo(x)
        puts "Mr. T says you are a foo times #{x.to_i}"
      end
    end

    class Bar < DslBlock
      commands :show_bar
      def show_bar(x)
        puts "Ordering #{x.to_i} Shirley Temples from the bar"
      end
    end

    class Baz < DslBlock
      commands :show_baz
      def show_baz(x)
        puts "Baz spaz #{x.inspect}"
      end
    end

    Baz.add_command_to(Bar)
    Bar.add_command_to(Foo, true)
    Foo.add_command_to(self)


    foo do
      puts self.inspect       # => #<Foo:0x007f98f187e240 @block=#<Proc:0x...>, @parent=nil>
      x = 10/10
      show_foo x              # => Mr. T says you are a foo times 1

      bar do
        x *= 2
        show_bar x            # => Ordering 2 Shirley Temples from the bar
        x += 1
        show_foo x            # => Mr. T says you are a foo times 3

        baz do
          x *= 4
          x /= 3
          show_baz x          # => Baz spaz 4
          begin
            x += 1
            show_bar 5        # This will throw a NameError
          rescue NameError
            puts 'No bar for us'
          end

        end

      end

    end


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
