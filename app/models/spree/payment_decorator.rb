
module Spree
  module PaymentDecorator
    def self.prepended(base)
      base.after_create :create_p24_token
    end

    private

    def create_p24_token
      return if not self.payment_method.is_a? Gateway::Przelewy24

      payment_method.register_transaction(self.order, self.id, self.payment_method.id)
    end
  end
end

::Spree::Payment.prepend(Spree::PaymentDecorator)
