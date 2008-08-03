module I18nYaml
  
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
    # TODO use the http_accept_language plugin for this.
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
        locales.include?(locale)
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
    # TODO push this into a custom backend and use I18n#populate
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
  
end
