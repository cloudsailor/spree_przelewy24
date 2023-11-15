module SpreePrzelewy24
  class Engine < Rails::Engine
    require 'spree/core'
    engine_name 'spree_przelewy24'

    isolate_namespace SpreePrzelewy24Gateway

    config.autoload_paths += %W[#{config.root}/lib]

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      Rails.application.config.after_initialize do
        Rails.application.config.spree.payment_methods << Spree::Gateway::Przelewy24
      end
      # puts Rails.application.config.spree.payment_methods.inspect
      # ::Rails.application.config.spree.payment_methods << Spree::Gateway::Przelewy24
      Spree::PermittedAttributes.source_attributes << :payment_method_name
      Spree::PermittedAttributes.source_attributes << :issuer
      # Spree::Api::ApiHelpers.payment_source_attributes << :payment_method_name
      # Spree::Api::ApiHelpers.payment_source_attributes << :issuer
      # Spree::Api::ApiHelpers.payment_source_attributes << :payment_url

      # Orders should be shippable whenever they're authorized
      Spree::Config[:auto_capture_on_dispatch] = true
    end

    config.to_prepare &method(:activate).to_proc
  end
end
