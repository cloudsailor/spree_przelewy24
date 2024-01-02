class AddButtonToOrderShow
  Deface::Override.new(virtual_path: "spree/shared/_order_details",
                      name: "add_button_to_order_show",
                      insert_after: "div.checkout-confirm-order-details",
                      partial: "shared/button_to_p24")
end
