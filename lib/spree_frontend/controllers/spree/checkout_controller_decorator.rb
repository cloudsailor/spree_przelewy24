module Spree
  module CheckoutControllerDecorator
    def payment_method_id_param
      params[:order][:payments_attributes].first[:payment_method_id]
    end

    def paying_with_p24?
      payment_method = PaymentMethod.find(payment_method_id_param)
      payment_method.is_a? Gateway::Przelewy24
    end

    def payment_params_valid?
      (params[:state] === 'payment') && params[:order][:payments_attributes]
    end
  end

  module CheckoutWithP24
    # If we're currently in the checkout
    def update
      if payment_params_valid? && paying_with_p24?
        if @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)
          payment = @order.payments.last
          payment.process!
          p24_payment_url = gateway_przelewy24_path(gateway_id: payment_method_id_param, order_id: @order.id)

          Rails.logger.debug("For order #{@order.number} redirect user to payment URL: #{p24_payment_url}")

          # redirect_to p24_payment_url
          # render :edit
          super
        else
          render :edit
        end
      else
        super
      end
    end
  end

  CheckoutController.prepend(CheckoutWithP24)
  CheckoutController.prepend(CheckoutControllerDecorator)
end
::Spree::CheckoutController.prepend Spree::CheckoutWithP24
::Spree::CheckoutController.prepend Spree::CheckoutControllerDecorator
