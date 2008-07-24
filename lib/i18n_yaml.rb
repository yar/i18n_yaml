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
    def set_locale
      locale = params[:locale] || session[:locale]
      locale = (I18n.locale_dir(locale) ? locale : nil) || I18n.default_locale
      logger.info "Using locale: #{locale}"
      I18n.locale = locale
      I18n.load_yaml_locale(locale)
      session[:locale] = locale
    end

  end

  module YamlLoader

    # Returns the root directory of the locales. This is app/locales
    def locales_dir
      "#{RAILS_ROOT}/app/locales"
    end

    # Returns the directory in which the given locale is located.
    # Returns nil if this locale directory doesn't exist.
    def locale_dir(locale)
      return nil if locale.nil?
      dir = "#{locales_dir}/#{locale}"
      File.directory?(dir) ? dir : nil
    end
    
    # Returns all available locales, i.e. the subdirectories of app/locales
    def all_available_locales
      Dir.entries(locales_dir).select { |i| File.directory?("#{locales_dir}/#{i}") && i != '.' && i != '..' }
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
    def load_yaml_locale(locale, options = {})
      caching_options = ( ::ActionController::Base.perform_caching ? {} : { :force => true } ).merge(options)
      loaded_translations = Rails.cache.fetch("locales/#{locale}", caching_options) do
        translations = {}
        Dir.glob(File.join("#{I18n.locale_dir(locale)}/**", "*.yml")).each do |file|
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
