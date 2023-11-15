module Spree
  class Gateway::Przelewy24 < PaymentMethod

    #attr_accessible :preferred_test_mode, :preferred_url, :preferred_url_transakcja, :preferred_test_url, :preferred_crc_key, :preferred_p24_language, :preferred_test_url_transakcja, :preferred_p24_return_url_error, :preferred_p24_return_url_ok, :preferred_p24_id_sprzedawcy

    preference :p24_id_sprzedawcy, :string
    preference :url, :string, :default => "https://secure.przelewy24.pl/index.php"
    preference :url_transakcja, :string, :default => "https://secure.przelewy24.pl/transakcja.php"
    preference :test_url, :string, :default => "https://sandbox.przelewy24.pl/index.php"
    preference :test_url_transakcja, :string, :default => "https://sandbox.przelewy24.pl/transakcja.php"
    preference :p24_language, :string, :default => "pl"
    preference :crc_key, :string
    preference :test_mode, :boolean, :default => false

    has_many :spree_p24_payment_sources, class_name: 'Spree::P24PaymentSource'

    def payment_profiles_supported?
      false
    end

    # Always create a source which references to the selected Mollie payment method.
    def source_required?
      false
    end

    def p24_amount(amount)
      (amount*100.00).to_i.to_s #total amount * 100
    end

    def post_url
      if preferred_test_mode
        preferred_test_url
      else
        preferred_url
      end
    end

    def transakcja_url
      if preferred_test_mode
        preferred_test_url_transakcja
      else
        preferred_url_transakcja
      end
    end

  end
end
