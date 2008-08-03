module I18nYaml
  
  module TranslationHelper

    class HashWithAccessors

      def initialize(defaults = {})
        @hash = defaults
      end

      def to_hash
        @hash
      end

      def [](key)
        @hash[key]
      end

      def method_missing(name, *attributes)
        if name.to_s =~ /=$/
          puts "accepted " + name.inspect
          @hash[name.to_s.sub(/=$/,'').intern] = attributes.first
        end
      end
    end

    # Translates your key or localizes dates
    # You can add a block to set all your options, like count, format and injection values. 
    # You can even nest that into neat multiple lines.
    #
    #   t(:it_is_today) do |i|
    #     i.today = l(Date.today) do |j|
    #       j.format = :short
    #     end
    #   end
    #
    def t(key, options = {}, &block)
      options.merge!(block_to_hash(options, &block)) if block_given?
      translate_or_localize(key, options)
    end
    alias_method :l, :t

    # Translates your key, and makes the complete translation string HTML-safe
    # See also t.
    def ht(key, options = {}, &block)
      options.merge!(block_to_hash(options, &block)) if block_given?
      h(translate_or_localize(key, options))
    end
    alias_method :hl, :ht

    # Translates your key and makes any value-injection HTML-safe, but not the entire translation
    # See also t.
    def th(key, options = {}, &block)
      options.merge!(block_to_hash(options, &block)) if block_given?
      options.each {|k,v| options[k] = h(v) if v.is_a?(String) }
      translate_or_localize(key, options)
    end
    alias_method :lh, :th

    # Performs either a translate function or a localize function, depending on what's needed.
    def translate_or_localize(key, options = {})
      [Date, DateTime, Time].include?(key.class) ? I18n.localize(key, options) : I18n.translate(key, options)
    end

    # If a block is given it turns attributes set to it into an array.
    def block_to_hash(default = {}, &block)
      default.merge((yield HashWithAccessors.new(default)).to_hash) if block_given?
    end

  end

end
