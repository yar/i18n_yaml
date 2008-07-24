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
        puts 'trying locale: ' + x.inspect
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

    # Translates your key or localizes dates
    def t(*args)
      if [Date, DateTime, Time].include?(args.first.class)
        I18n.localize(*args)
      else
        I18n.translate(*args)
      end
    end
    alias_method :l, :t

    # Translates your key, and makes the complete translation string HTML-safe
    def ht(*args)
      h(t(*args))
    end
    alias_method :hl, :ht

    # Translates your key and makes any value-injection HTML-safe, but not the entire translation
    # OPTIMIZE This is ugly.
    def th(*args)
      if args[-1].is_a?(Hash)
        args[-1].each do |k,v|
          args[-1][k] = h(v) if v.is_a?(String)
        end
      end
      t(*args)
    end
    alias_method :lh, :th

  end

end
