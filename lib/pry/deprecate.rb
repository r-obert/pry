module Pry::Deprecate
  require 'set'
  DEPRECATE_PRYS = Set.new []

  #
  # Deprecates a method so that all future calls to it display a deprecation message,
  # unless _pry_.config.print_deprecations is not 'true'.
  #
  # @example
  #
  #  deprecate_method! [Kernel.method(:puts), "StringIO#puts"],
  #                    "#puts is deprecated, use #write instead"
  #  Kernel.puts "foo"
  #  StringIO.new("").puts "bar"
  #
  # @param [Array<String, Method>] sigs
  #   An array of signatures in the form of a String as 'Foo::Bar#baz' (instance method),
  #   'Foo::Bar.baz' (class method) or Method objects.
  #
  # @param [Pry] pry
  #   An instance of Pry. `Pry#output` is used for writing.
  #
  # @return [nil]
  #
  def deprecate_method! sigs, message, pry=((defined?(_pry_) and _pry_) or raise)
    DEPRECATE_PRYS.add(pry)
    sigs.each do |sig|
      mod, method, copy = String === sig ?
                          __deprecate_string_sig(sig)  : __deprecate_method_sig(sig)
      mod.send :define_method, method do |*a, &b|
        callerf = caller[0]
        copy = ::UnboundMethod === copy ? copy.bind(self) : copy
        result = copy.call(*a, &b)
        DEPRECATE_PRYS.each do |pry|
          next if pry.config.print_deprecations != true
          # Remove dead pry's? Otherwise this method will leak like crazy in scenarios
          # where multiple Pry's are common.
          io = pry.output
          io.puts("%s%s\n%s\n" \
                  "Set _pry_.config.deprecate_warnings = false to stop printing this message." %
                  ["DEPRECATED: ", message, ".. Called from #{callerf}"]) if not io.closed?
        end
        result
      end
    end
  end

  def __deprecate_string_sig(s)
    path = s.split('::')
    scope = path[-1].include?('#') ? :instance : :module
    path[-1], method = path[-1].split /[.#]/, 2
    mod = path.inject(Object) { |m,s| m.const_get(s) }
    copy = scope == :instance ? mod.instance_method(method) : mod.method(method)
    target = scope == :instance ? mod : singleton_class
    [mod, method, copy]
  end

  def __deprecate_method_sig(m)
   [m.owner, m.name, m]
  end

  private :__deprecate_string_sig, :__deprecate_method_sig
  extend self
end
