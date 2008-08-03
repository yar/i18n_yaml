l = File.join(File.dirname(__FILE__), 'lib')
require File.join(l, 'action_controller')
require File.join(l, 'yaml_loader') 
require File.join(l, 'translation_helper')

ActionController::Base.send :include, I18nYaml::ActionController
I18n.extend ::I18nYaml::YamlLoader
ActionView::Base.send :include, I18nYaml::TranslationHelper
