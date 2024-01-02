require 'openssl'
require 'faraday'

module Spree
  class Gateway::Przelewy24 < PaymentMethod
    preference :p24_merchant_id, :string
    preference :p24_pos_id, :string
    preference :p24_crc_key, :string
    preference :p24_report_key, :string
    preference :p24_channel, :integer, default: 16
    preference :p24_time_limit, :integer, default: 0
    preference :test_mode, :boolean, default: false
    preference :wait_for_result, :boolean, default: true
    preference :regulation_accept, :boolean, default: false
    preference :p24_return_url, :string, default: "http://localhost:3000"
    preference :p24_return_status_url, :string, default: "http://localhost:3000"
    preference :url, :string, default: 'https://secure.przelewy24.pl/trnRequest/'
    preference :url_transaction, :string, default: 'https://secure.przelewy24.pl/api/v1/transaction/register'
    preference :test_url, :string, default: 'https://sandbox.przelewy24.pl/trnRequest/'
    preference :test_url_transaction, :string, default: 'https://sandbox.przelewy24.pl/api/v1/transaction/register'
    preference :url_verify, :string, default: 'https://secure.przelewy24.pl/api/v1/transaction/verify'
    preference :test_url_verify, :string, default: 'https://sandbox.przelewy24.pl/api/v1/transaction/verify'

    has_many :spree_p24_payment_sources, class_name: 'Spree::P24PaymentSource'

    def payment_profiles_supported?
      false
    end

    def source_required?
      false
    end

    def cancel(order_id)
      Rails.logger.debug("Starting cancellation for #{order_id}")

      MollieLogger.debug("Spree order #{order_id} has been canceled.")
      ActiveMerchant::Billing::Response.new(true, 'Spree order has been canceled.')
    end

    def p24_amount(amount)
      (amount*100.00).to_i.to_s #total amount * 100
    end

    def post_url(token)
      if preferred_test_mode
        preferred_test_url + token
      else
        preferred_url + token
      end
    end

    def transaction_url
      if preferred_test_mode
        preferred_test_url_transaction
      else
        preferred_url_transaction
      end
    end

    def verify_url
      if preferred_test_mode
        preferred_test_url_verify
      else
        preferred_url_verify
      end
    end

    def register_transaction(order, payment_id, gateway_id)
      return if order.blank? || payment_id.blank? || gateway_id.blank?

      payment = order.payments.find payment_id

      conn = Faraday.new(url: transaction_url) do |faraday|
        faraday.adapter Faraday.default_adapter
        faraday.request :authorization, :basic, preferred_p24_pos_id, preferred_p24_report_key
      end

      response = conn.post do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = register_transaction_payload(order, gateway_id, payment).to_json
      end

      if response.success?
        response_body = JSON.parse(response.body)
        payment.update(public_metadata: { p24_token: response_body['data']['token'], p24_payment_url: post_url(response_body['data']['token']) })
        response.body['data']['token']
      else
        nil
      end
    end

    def verify_transaction(order, payment, session_id, amount, currency, p24_order_id, p24_statement)
      return false if order.blank? || payment.blank? || session_id.blank? || amount.blank? || currency.blank? || p24_order_id.blank?

      float_amount = (amount / 100)&.to_f
      conn = Faraday.new(url: verify_url) do |faraday|
        faraday.adapter Faraday.default_adapter
        faraday.request :authorization, :basic, preferred_p24_pos_id, preferred_p24_report_key
      end

      response = conn.put do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = verify_transaction_payload(session_id, amount, currency, p24_order_id).to_json
      end

      if response.success?
        payment.amount = float_amount
        payment.complete
        private_metadata = payment.private_metadata
        private_metadata[:p24_order_id] = p24_order_id
        private_metadata[:p24_statement] = p24_statement
        private_metadata[:p24_currency] = currency
        private_metadata[:p24_amount] = amount
        payment.update(private_metadata: private_metadata)
        true
      else
        false
      end
    end

    def verify_transaction_payload(session_id, amount, currency, p24_order_id)
      {
        merchantId: preferred_p24_merchant_id,
        posId: preferred_p24_pos_id,
        sessionId: session_id,
        amount: amount,
        currency: currency,
        orderId: p24_order_id,
        sign: calculate_verify_sign(session_id,p24_order_id,amount,currency)
      }
    end


    def register_transaction_payload(order, gateway_id, payment)
      session_id = payment.number

      {
        merchantId: preferred_p24_merchant_id,
        posId: preferred_p24_pos_id,
        sessionId: session_id,
        amount: p24_amount(order.total),
        currency: order.currency,
        description: order.number,
        email: order.email,
        client: order.name,
        address: order.billing_address.address1,
        zip: order.billing_address.zipcode,
        city: order.billing_address.city,
        country: order.billing_address.country.iso,
        phone: order.billing_address.phone,
        language: p24_language(order.billing_address.country.iso),
        method: 0,
        urlReturn: preferred_p24_return_url,
        urlStatus: "#{preferred_p24_return_status_url}/gateway/przelewy24/comeback/#{gateway_id}/#{order.id}",
        timeLimit: preferred_p24_time_limit,
        channel: preferred_p24_channel,
        waitForResult: preferred_wait_for_result,
        regulationAccept: preferred_regulation_accept,
        shipping: order.shipment_total,
        transferLabel: order.number,
        sign: calculate_register_sign(session_id,preferred_p24_merchant_id,p24_amount(order.total),order.currency),
        encoding: 'UTF-8',
        methodRefId: '',
        # cart: [{}],
        # additional: {
        #   shipping: {}
        # }
      }
    end

    def p24_language(country_iso)
      allowed_languages = %w[bg cs de en es fr hr hu it nl pl pt se sk]
      country_iso = country_iso&.downcase

      allowed_languages.include?(country_iso) ? country_iso : 'en'
    end

    def calculate_register_sign(session,merchant,amount,currency)
      string_to_hash = "{\"sessionId\":\"#{session}\",\"merchantId\":#{merchant},\"amount\":#{amount},\"currency\":\"#{currency}\",\"crc\":\"#{preferred_p24_crc_key}\"}"
      OpenSSL::Digest::SHA384.hexdigest(string_to_hash)
    end

    def calculate_verify_sign(session, order_id, amount, currency)
      string_to_hash = "{\"sessionId\":\"#{session}\",\"orderId\":#{order_id},\"amount\":#{amount},\"currency\":\"#{currency}\",\"crc\":\"#{preferred_p24_crc_key}\"}"
      OpenSSL::Digest::SHA384.hexdigest(string_to_hash)
    end
  end
end
