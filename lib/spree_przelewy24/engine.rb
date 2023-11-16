module SpreePrzelewy24
  class Engine < Rails::Engine
    require 'spree/core'
    engine_name 'spree_przelewy24'

    isolate_namespace SpreePrzelewy24Gateway

    config.autoload_paths += %W[#{config.root}/lib]

    config.after_initialize do |app|
      app.config.spree.payment_methods << Spree::Gateway::Przelewy24
    end

    def self.activate
      if self.frontend_available?
        Dir.glob(File.join(File.dirname(__FILE__), '../../lib/spree_frontend/controllers/spree/*_decorator*.rb')) do |c|
          Rails.application.config.cache_classes ? require(c) : load(c)
        end
      end

      Spree::PermittedAttributes.source_attributes << :payment_method_name
      Spree::PermittedAttributes.source_attributes << :issuer

      # Orders should be shippable whenever they're authorized
      Spree::Config[:auto_capture_on_dispatch] = true
    end

    def self.frontend_available?
      @@frontend_available ||= ::Rails::Engine.subclasses.map(&:instance).map{ |e| e.class.to_s }.include?('Spree::Frontend::Engine')
    end

    paths['app/controllers'] << 'lib/controllers'

    if self.frontend_available?
      paths["app/controllers"] << "lib/spree_frontend/controllers"
      paths["app/views"] << "lib/views/frontend"
    end

    config.to_prepare &method(:activate).to_proc
  end

end
