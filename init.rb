ActionController::Base.send :include, I18nYaml::ActionController
I18n.extend I18nYaml::YamlLoader
ActionView::Base.send :include, I18nYaml::TranslationHelper
