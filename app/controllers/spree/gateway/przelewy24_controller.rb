require 'digest/md5'
module Spree
  class Gateway::Przelewy24Controller < Spree::BaseController
    skip_before_action :verify_authenticity_token, :only => [:comeback, :complete, :error]
    include Spree::Core::ControllerHelpers::Order
    helper 'spree/store'

    # Show form Przelewy24 for pay
    def show
      @order = Order.find(params[:order_id])
      if params[:gateway_id]
        @gateway = @order.available_payment_methods.find{|x| x.id == params[:gateway_id].to_i }
        @order.payments.destroy_all
        payment = @order.payments.create!(:amount => 0, :payment_method_id => @gateway.id)

        @p24_session_id = Time.now.to_f.to_s
        @p24_crc = przelewy24_transaction_crc(@gateway,@order,@p24_session_id)

        if @order.blank? || @gateway.blank?
          flash[:error] = I18n.t("invalid_arguments")
          redirect_to :back
        else
          @bill_address, @ship_address = @order.bill_address, (@order.ship_address || @order.bill_address)
        end
      end
    end

    def error
      @order = Order.find(params[:order_id])
    end


    # Result from Przelewy24
    def comeback
      @order = Order.find(params[:order_id])
      payment = @order && @order.payments.first
      @gateway = payment && payment.payment_method
      @response = przelewy24_verify(@gateway,@order,params)
      @amount = 100.0
      @amount = params[:p24_kwota].to_f/100
      result = @response.split("\r\n")
      if result[1] == "TRUE"
        przelewy24_payment_success(payment, @amount)
        redirect_to gateway_przelewy24_complete_path(:order_id => @order.id, :gateway_id => @gateway.id)
      else
        redirect_to gateway_przelewy24_error_path(:gateway_id => @gateway.id, :order_id => @order.id, :error_code => result[2], :error_descr => result[3])
      end
    end

    # complete the order
    def complete
      @order = Order.find(params[:order_id])

      session[:order_id]=nil
      if @order.state=="complete"
        redirect_to order_url(@order, {:checkout_complete => true, :order_token => @order.token}), :notice => I18n.t("payment_success")
      else
        redirect_to order_url(@order)
      end
    end



    private

    # validating dotpay message
    def przelewy24_transaction_crc(gateway,order,session_id)
      calc_md5 = Digest::MD5.hexdigest(session_id + "|" +
        (@gateway.preferred_p24_id_sprzedawcy.nil? ? "" : @gateway.preferred_p24_id_sprzedawcy) + "|" +
        (@gateway.p24_amount(@order.total).nil? ? "" : @gateway.p24_amount(@order.total)) + "|" +
        (@gateway.preferred_crc_key.nil? ? "" : @gateway.preferred_crc_key))

        return calc_md5

    end

    def przelewy24_verify(gateway,order,params)
      require 'net/https'
      require 'net/http'
      require 'open-uri'
      require 'openssl'

      params_new = {:p24_session_id => params[:p24_session_id], :p24_order_id => params[:p24_order_id], :p24_id_sprzedawcy => gateway.preferred_p24_id_sprzedawcy, :p24_kwota => params[:p24_kwota]}
      params_new[:p24_crc] = Digest::MD5.hexdigest(params[:p24_session_id]+"|"+params[:p24_order_id]+"|"+params[:p24_kwota]+"|"+gateway.preferred_crc_key)
      #params_list = "p24_session_id=#{params_new[:p24_session_id]}&p24_order_id=#{params_new[:p24_session_id]}&p24_id_sprzedawcy=#{params_new[:p24_id_sprzedawcy]}&p24_kwota=#{params_new[:p24_kwota]}&p24_crc=#{params_new[:p24_crc]}"
      url = URI.parse(gateway.transakcja_url)
      req = Net::HTTP::Post.new(url.path,{"User-Agent" => "Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.10) Gecko/20100915 Ubuntu/10.04 (lucid) Firefox/3.6.10"})
      req.form_data = params_new
      #req.basic_auth url.user, url.password if url.user
      con = Net::HTTP.new(url.host, 443)
      con.use_ssl = true
      con.verify_mode = OpenSSL::SSL::VERIFY_NONE
      response = con.start {|http| http.request(req)}
      return response.body
    end

    # Completed payment process
    def przelewy24_payment_success(payment, amount)
      payment.started_processing
      payment.amount = amount
      if @order.total.to_f == amount.to_f
        payment.complete
      end
      @order.update_totals

      @order.finalize!

      @order.next
      @order.next
      @order.save
    end

    # payment cancelled by user (dotpay signals 3 to 5)
    def przelewy24_payment_cancel(params)
      @order.cancel
    end

    def przelewy24_payment_new(params)
      @order.payment.started_processing
      @order.finalize!
    end

  end
end
