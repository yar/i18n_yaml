module I18nYaml
  
  module ActionController
    
    private

    # This is a filter you can use in your controllers.
    # Example:
    #
    #   ApplicationController < ActionController::Base
    #     before_filter :set_locale
    #   end
    #
    # The locale can be set through a parameter locale. 
    # It stores the locale in the session after that.
    #
    # Copy this function to your application.rb if you want to adjust it, to say, recognize subdomains as locale.
    def set_locale
      I18n.select_locale( params[:locale], session[:locale], I18n.from_http_header(request) )
      logger.info "Using language: #{I18n.locale}"
      session[:locale] = I18n.locale
    end

  end

  module YamlLoader

    # Selects and loads the appropriate locale.
    # It selects the first from the arguments which is installed.
    def select_locale(*possible_locales)
      locale = (possible_locales << I18n.default_locale).flatten.select do |x|
        locale_available?(x)
      end.first
      I18n.locale = select_language(locale)
      I18n.load_yaml_locale
    end

    # Splits the http-header for the users favorite language into an array, so it can be prosessed in select_locale.
    def from_http_header(request)
      languages = request.env['HTTP_ACCEPT_LANGUAGE'].split(',')
      languages.collect do |language|
        language.sub(/;.*/,'')
      end
    end

    # Returns the root directory of the locales. This defaults to app/locales
    def locales_dir
      @locales_dir ||= File.join(RAILS_ROOT, 'app', 'locales')
    end

    # Set the path of your locales, if different to app/locales
    def locales_dir=(l)
      raise ArgumentError, "Not a directory: #{l}" unless File.directory?(l)
      @locales_dir = l
    end

    # Returns all locales available, in a hash from locales.yml
    def available_locales
      Rails.cache.fetch('locales') do
        YAML.load_file(File.join(locales_dir, 'locales.yml'))
      end
    end

    # Checks if the locale has been installed
    def locale_available?(locale)
      return nil if locale.nil?
      available_locales.values.flatten.include?(locale.downcase)
    end

    # Selects the proper language, corresponding to the loaddir
    def select_language(locale)
      available_locales.select do |language, locales|
        locales.include?(locale.downcase)
      end.first.first
    end

    # Loads all yaml files in for a certain locale.
    # Normally accessed through the before_filter :set_locale
    # 
    # The options are passed to caching options.
    # It only caches if you specified config.action_controller.perform_caching = true in your environment.
    #   
    #   I18n.load_yaml_locale('nl-NL')                         # Use Rails' caching settings
    #   I18n.load_yaml_locale('nl-NL', :force => true)         # Don't use caching, ignoring Rails' settings
    #   I18n.load_yaml_locale('nl-NL', :force => false)        # Always use caching, ignoring Rails' settings
    #   I18n.load_yaml_locale('nl-NL', :expiry => 1.day.to_i)  # Alternative caching options if your cache_store supports it
    #
    def load_yaml_locale(locale = I18n.locale, options = {})
      caching_options = ( ::ActionController::Base.perform_caching ? {} : { :force => true } ).merge(options)
      loaded_translations = Rails.cache.fetch("locales/#{locale}", caching_options) do
        translations = {}
        Dir.glob(File.join(I18n.locales_dir, locale, "*.yml")).each do |file|
          translations.merge!(YAML.load_file(file))
        end
        translations
      end
      I18n.store_translations(locale, loaded_translations)
    end

  end
  
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
