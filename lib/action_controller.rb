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

end
