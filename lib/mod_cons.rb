module ModCons
  
  class Configuration
    REQUIRED_METHODS = ["[]", "==", "class", "config_changed", "configure", "declare", 
                        "initialize", "inspect", "instance_eval", "method_missing", 
                        "methods", "to_hash", "to_s"]

    instance_methods.each { |m| undef_method m unless m =~ /^[^a-z]/ or m =~ /\?$/ or REQUIRED_METHODS.include?(m) }

    class << self
      def declare(namespace = nil, &block)
        result = self.new(namespace)
        result.declare(&block)
        return result
      end
    end
    
    def initialize(namespace)
      @config_changed = []
      @namespace = namespace
      @mode = :access
      @mode_stack = []
      @table = {}
    end

    def declare(namespace = nil, &block)
      result = self
      unless (namespace.nil?)
        ns = namespace.to_sym
        if @table[ns]
          warn "WARNING: Redeclaring configuration namespace #{namespace}"
        end
        result = (@table[ns] ||= self.class.new(ns))
      end
      if block_given?
        result._push_mode(:declare, &block)
      end
      return(result)
    end

    def _dispatch_declare(sym, *args, &block)
      unless sym.to_s =~ /^[A-Za-z][A-Za-z0-9_]+$/
        raise NameError, "Invalid configuration option name: #{sym}"
      end
      if @table[sym]
        warn "WARNING: Redeclaring configuration option #{sym}"
      end
      if block_given?
        self.declare(sym, &block)
      else
        @table[sym] = args.first
      end
      return self
    end
  
    def _dispatch_config(sym, *args, &block)
      if @table.has_key?(sym)
        if @table[sym].is_a?(self.class) and (args.length > 0 or block_given?)
          @table[sym].configure(*args, &block)
        elsif args.length == 1
          @table[sym] = args.first
        elsif args.length == 0
          @table[sym]
        else
          raise ArgumentError, "wrong number of arguments (#{args.length} for 1)"
        end
      else
        raise NameError, "Unknown configuration option: #{sym}"
      end
    end
  
    def _dispatch_access(sym)
      if @table.has_key?(sym)
        @table[sym]
      else
        raise NameError, "Unknown configuration option: #{sym}"
      end
    end
  
    def method_missing(sym, *args, &block)
      case @mode
      when :declare
        _dispatch_declare(sym, *args, &block)
      when :config
        _dispatch_config(sym, *args, &block)
      else
        _dispatch_access(sym)
      end
    end
  
    def configure(hash = nil, &block)
      config_signature = self.to_hash
      self._push_mode(:config) do
        if hash
          hash.each_pair do |k,v|
            key = k.to_sym
            unless @table.has_key?(key)
              raise NameError, "Unknown configuration option: #{key}"
            end
      
            if @table[key].is_a?(self.class)
              @table[key].configure(v)
            else
              @table[key] = v
            end
          end
        end
        self.instance_eval(&block) if block_given?
      end
      unless self.to_hash == config_signature
        @config_changed.each do |listener|
          listener.call(self)
        end
      end
      return self
    end

    def config_changed(&block)
      @config_changed << block
      return self
    end
    
    def template(indent = '')
      result = "#{indent}#{@namespace.to_s}"
      if indent.length == 0
        result << ".configure"
      end
      result << " do\n"
      _keys.sort { |a,b| a.to_s <=> b.to_s }.each do |key|
        value = @table[key]
        display_value = nil
        if value.is_a?(self.class)
          if value._keys.length == 1 and not value[value._keys.first].is_a?(Hash)
            child_key = value._keys.first
            display_value = value[child_key].inspect
            result << "#{indent}  #{key.to_s}.#{child_key}"
          else
            result << value.template("#{indent}  ")
          end
        else
          result << "#{indent}  #{key.to_s}"
          display_value = value.inspect
        end
        
        unless display_value.nil?
          if display_value[0,1] == '{'
            display_value = "(#{display_value})"
          else
            display_value = " #{display_value}"
          end
          result << "#{display_value}\n"
        end
      end
      result << "#{indent}end\n"
      return(result)
    end
    
    def [](key)
      result = @table[key.to_sym]
      if result.is_a?(self.class)
        result.to_hash
      else
        result
      end
    end
  
    def _keys
      @table.keys
    end
  
    def to_hash
      result = @table.dup
      result.each_pair do |k,v|
        if v.is_a?(self.class)
          result[k] = v.to_hash
        end
      end
    end

    def inspect
      (initial,rest) = @namespace.to_s.split(//,2)
      "#<#{initial.to_s.upcase}#{rest}: {#{_keys.join(', ')}}>"
    end
  
    def methods
      super + _keys.collect { |k| k.to_s }
    end
    
    protected
    def _push_mode(new_mode, &block)
      @mode_stack.push(@mode)
      @mode = new_mode
      @table.values.each do |v|
        if v.is_a?(self.class)
          v._push_mode(new_mode)
        end
      end
      if block_given?
        begin
          self.instance_eval(&block)
        ensure
          _pop_mode
        end
      end
    end
    
    def _pop_mode
      @table.values.each do |v|
        if v.is_a?(self.class)
          v._pop_mode
        end
      end
      @mode = @mode_stack.pop || :access
    end
  end
  
  Config = Configuration.new(:"ModCons::Config")
end