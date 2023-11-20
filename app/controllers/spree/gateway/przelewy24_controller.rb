require 'digest/md5'
module Spree
  class Gateway::Przelewy24Controller < Spree::BaseController
    skip_before_action :verify_authenticity_token, :only => [:comeback]
    include Spree::Core::ControllerHelpers::Order
    helper 'spree/store'

    # Result from Przelewy24
    def comeback
      payment = Spree::Payment.find_by(number: params[:sessionId])
      if payment&.state == 'checkout' && payment.payment_method.verify_transaction(payment.order, payment, params[:sessionId], params[:amount], params[:currency], params[:orderId])
        head :ok
      else
        head :unprocessable_entity
      end
    end

    private

    # payment cancelled by user (dotpay signals 3 to 5)
    # def przelewy24_payment_cancel(params)
    #   @order.cancel
    # end

    # def przelewy24_payment_new(params)
    #   @order.payment.started_processing
    #   @order.finalize!
    # end
  end
end
