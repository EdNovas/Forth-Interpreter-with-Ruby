class ForthInterpreter
    def initialize
        @stack = [] # the stack
        @error_occurred = false # whether an error has occurred
        @string_status = false # whether we are in a string
        @in_loop_block = false # whether we are in a do-loop block
        @I_index = -1 # the index of the I variable

        @heap = {} # the heap
        @heap_address = 999 # the heap address
        # Set up the dictionary:
        @dictionary = {
            "+" => lambda {op(:+)},
            "-" => lambda {op(:-)},
            "*" => lambda {op(:*)},
            "/" => lambda {op(:/)},
            "MOD" => lambda {op(:%)},
            "DUP" => lambda {check_stack_size(1) {@stack.push(@stack.last)}},
            "SWAP" => lambda {check_stack_size(2) {@stack[-1], @stack[-2] = @stack[-2], @stack[-1]}},
            "DROP" => lambda {check_stack_size(1) {@stack.pop}},
            "DUMP" => lambda {puts @stack.inspect},
            "OVER" => lambda {check_stack_size(2) {@stack.push(@stack[-2])}},
            "ROT" => lambda {check_stack_size(3) {@stack[-1], @stack[-2], @stack[-3] = @stack[-3],@stack[-1], @stack[-2]}},
            "." => lambda {check_stack_size(1) {print @stack.pop.to_s + ' '}},
            "EMIT" => lambda {check_stack_size(1) {print @stack.pop.chr}},
            "CR" => lambda {puts},
            "=" => lambda {comparison(:==)},
            "<" => lambda {comparison(:<)},
            ">" => lambda {comparison(:>)},
            "AND" => lambda {bitwise_op(:&)},
            "OR" => lambda {bitwise_op(:|)},
            "XOR" => lambda {bitwise_op(:^)},
            "INVERT" => lambda {check_stack_size(1) {@stack.push(~@stack.pop)}},
            "CELLS" => lambda {interpret("1 * ")},
        }
    end

    def interpret(line)
        line.gsub!(/\(.*?\)/, '') # remove comments
        words = line.split # split into words

        # Set up for strings:
        in_string = false # whether we are in a string
        string = "" # the string we are building
        @error_occurred = false # whether an error has occurred

        # Set up for definitions:
        in_definition = false # whether we are in a definition
        definition_name = nil # the name of the definition
        definition_words = "" # the words in the definition
        definition_name_status = false # whether the defniition name has been found

        # Set up for if-else blocks:
        true_block = ""
        false_block = ""
        if_else = false # whether we are in an if-else block
        then_stop = -1 # the index of the last word in the if-else block

        # Set up for begin-until blocks:
        begin_block = ""
        begin_until = false # whether we are in a begin-until block
        until_stop = -1 # the index of the last word in the begin-until block

        # Set up for do-loop blocks:
        do_block = ""
        # @in_loop_block = false # whether we are in a do-loop block
        loop_stop_status = false # whether we are in a do-loop block
        loop_stop = -1 # the index of the last word in the do-loop block

        # Set up for constants:
        constant_status = false # whether we are in a constant definition
        constant_stop = -1 # the index of the last word in the constant definition

        # Set up for variables:
        variable_stop = -1 # the index of the last word in the variable definition

        # Make all words uppercase
        words.each_with_index do |word, index|
            if word == '."'
                in_string = true
            elsif in_string && word.end_with?('"')
                in_string = false
            elsif in_string
                next
            end
            if @dictionary.key?(word.upcase)
                words[index] = word.upcase
            end
            if word.upcase == "IF" || word.upcase == "ELSE" || word.upcase == "THEN"
                words[index] = word.upcase
            end
            if word.upcase == "BEGIN" || word.upcase == "UNTIL"
                words[index] = word.upcase
            end
            if word.upcase == "DO" || word.upcase == "LOOP"
                words[index] = word.upcase
            end
            if word.upcase == "CONSTANT" || word.upcase == "ALLOT" || word.upcase == "CELLS"
                words[index] = word.upcase
            end
            if word.upcase == "VARIABLE"
                words[index] = word.upcase
            end
        end
        
        # puts words
        words.each_with_index do |word, index|
            if definition_name_status
                definition_name_status = false
                next
            elsif !in_string && index == then_stop
                if_else = false
            elsif !in_string && index == until_stop
                begin_until = false
            elsif !in_string && index == loop_stop
                loop_stop_status = false
            elsif !in_string && index == constant_stop
                constant_status = false
            elsif !in_string && index == variable_stop
                next
            elsif !in_string && word == "I" && @in_loop_block
                # puts "pushed one I"
                @stack.push(@I_index)
                next
            elsif !in_string && if_else
                next
            elsif !in_string && begin_until
                next
            elsif !in_string && loop_stop_status
                next
            elsif !in_string && constant_status
                next
            elsif !in_string && word == "VARIABLE"
                variable_name = words[index + 1]
                @heap_address += 1
                set_heap_address = @heap_address
                @dictionary[variable_name.upcase] = lambda {@stack.push(set_heap_address)}
                @heap[set_heap_address] = 0
                variable_stop = index + 1
            elsif !in_string && word == "ALLOT" && words[index - 1] == "CELLS"
                check_stack_size_2(1)
                if @error_occurred
                    break
                end
                @heap_address += @stack.pop
            elsif !in_string && word == "!"
                check_stack_size_2(2)
                if @error_occurred
                    break
                end
                get_heap_address = @stack.pop
                if get_heap_address < 1000
                    @error_occurred = true
                    puts "Error: Cannot write to address " + get_heap_address.to_s
                    break
                end
                popped_value = @stack.pop
                @heap[get_heap_address] = popped_value
            elsif !in_string && word == "@"
                check_stack_size_2(1)
                if @error_occurred
                    break
                end
                get_heap_address = @stack.pop
                if get_heap_address < 1000
                    @error_occurred = true
                    puts "Error: Cannot read from address " + get_heap_address.to_s
                    break
                end
                push_value = @heap[get_heap_address]
                @stack.push(push_value)
            elsif !in_string && word == "?"
                check_stack_size_2(1)
                if @error_occurred
                    break
                end
                get_heap_address = @stack.pop
                if get_heap_address < 1000
                    @error_occurred = true
                    puts "Error: Cannot read from address " + get_heap_address.to_s
                    break
                end
                push_value = @heap[get_heap_address]
                print push_value.to_s + " "
            elsif in_definition
                if word == ";"
                    in_definition = false
                    # puts definition_name.upcase
                    # puts definition_words
                    @dictionary[definition_name.upcase] = lambda {interpret(definition_words)}
                else
                    definition_words += word + " "
                    next
                end
            elsif !in_string && word == "CONSTANT"
                name = words[words.index(word) + 1]
                value = @stack.pop
                @dictionary[name.upcase] = lambda {@stack.push(value)}
                constant_stop = words.index(word) + 1
                constant_status = true
            elsif !in_string && word == ":"
                in_definition = true
                definition_name = words[words.index(word) + 1]
                definition_name_status = true
                # puts definition_name
            elsif !in_string && word == "IF"
                if_else = false
                if words.index("ELSE") != nil
                    true_block = words[words.index(word) + 1..words.index("ELSE") - 1].join(" ")
                    false_block = words[words.index("ELSE") + 1..words.rindex("THEN") - 1].join(" ")
                else
                    true_block = words[words.index(word) + 1..words.rindex("THEN") - 1].join(" ")
                end
                then_stop = words.rindex("THEN")
                # puts true_block
                # puts false_block
                check_stack_size_2(1)
                if @error_occurred
                    break
                end
                if @stack.pop != 0
                    interpret(true_block)
                    if_else = true
                else
                    interpret(false_block)
                    if_else = true
                end
            elsif !in_string && word == "DO"
                check_stack_size_2(2)
                if @error_occurred
                    break
                end
                loop_start = @stack.pop
                loop_end = @stack.pop
                do_block = words[words.index(word) + 1..words.rindex("LOOP") - 1].join(" ")
                loop_stop = words.rindex("LOOP")
                # puts do_block
                for i in loop_start..loop_end - 1
                    @in_loop_block = true
                    @I_index = i
                    # puts @I_index
                    interpret(do_block)
                end
                loop_stop_status = true
                @in_loop_block = false
                next
            elsif !in_string && word == "BEGIN"
                begin_block = words[words.index(word) + 1..words.rindex("UNTIL") - 1].join(" ")
                # puts begin_block
                interpret(begin_block)
                while true
                    check_stack_size_2(1)
                    if @error_occurred
                        break
                    end
                    temp = @stack.pop
                    if temp == 0
                        interpret(begin_block)
                    elsif temp != 0
                        break
                    end
                end
                if @error_occurred
                    break
                end
                begin_until = true
                until_stop = words.rindex("UNTIL")
            elsif !in_string && word.match?(/\A-?\d+\z/)
                @stack.push(word.to_i)
            elsif !in_string && @dictionary.key?(word)
                @dictionary[word].call
            elsif word == '."'
                in_string = true
                string = word[2..-1]
            elsif in_string && word.end_with?('"')
                in_string = false
                string += word[0..-2]
                print string
                string = ""
            elsif in_string
                string += word[0..-1] + ' '
            else
                puts "error: unknown input word '#{word}'"
                @error_occurred = true
            end
        end
        if in_string
            puts ""
        end
    end

    private

    def op(operation)
        check_stack_size(2) do
            n2 = @stack.pop
            n1 = @stack.pop
            @stack.push(n1.send(operation, n2))
        end
    end

    def comparison(operation)
        check_stack_size(2) do
            n2 = @stack.pop
            n1 = @stack.pop
            @stack.push(n1.send(operation, n2) ? -1 : 0)
        end
    end

    def bitwise_op(operation)
        check_stack_size(2) do
            n2 = @stack.pop
            n1 = @stack.pop
            @stack.push(n1.send(operation, n2))
        end
    end

    def check_stack_size(size)
        if @stack.size >= size
            yield
        elsif @stack.size == 0
            puts "error: empty stack"
            @error_occurred = true
        elsif @stack.size < size
            puts "error: not enough elements in stack"
            @error_occurred = true
        end
    end

    def check_stack_size_2(size)
        if @stack.size == 0
            puts "error: empty stack"
            @error_occurred = true
        elsif @stack.size < size
            puts "error: not enough elements in stack"
            @error_occurred = true
        end
    end
end

interpreter = ForthInterpreter.new
@multi_line_def = false
@multi_line_begin = false
@multi_line_if = false
@multi_line_do = false

Signal.trap("INT") do
    puts "\nExit Forth Interpreter"
    exit 0
end

loop do
    print "> "
    line = gets.strip
    if line == "QUIT" || line == "EXIT" || line == "quit" || line == "exit"
        puts "Exit Forth Interpreter"
        exit 0
    end
    if line.start_with?(":") && !line.include?(";")
        @multi_line_def = true
        input = line.clone
        loop do
            line = gets.strip
            input += " " + line
            if line.include?(";")
                break
            end
        end
        line = input
    end
    if line.match?(/BEGIN/i) && !line.match?(/UNTIL/i)
        @multi_line_begin = true
        input = line.clone
        loop do
            line = gets.strip
            input += " " + line
            if line.match?(/UNTIL/i)
                break
            end
        end
        line = input
    end
    if line.match?(/IF/i) && !line.match?(/THEN/i)
        @multi_line_if = true
        input = line.clone
        loop do
            line = gets.strip
            input += " " + line
            if line.match?(/THEN/i)
                break
            end
        end
        line = input
    end
    if line.match?(/DO/i) && !line.match?(/LOOP/i)
        @multi_line_do = true
        input = line.clone
        loop do
            line = gets.strip
            input += " " + line
            if line.match?(/LOOP/i)
                break
            end
        end
        line = input
    end
    begin
        interpreter.interpret(line)
        if interpreter.instance_variable_get(:@error_occurred)
            print ""
        else
            puts "ok"
        end
        rescue => e
        puts "An error occurred: #{e.message}"
    end
end
