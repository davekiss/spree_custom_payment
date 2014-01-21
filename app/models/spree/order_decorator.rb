Spree::Order.class_eval do
  remove_checkout_step :address
  remove_checkout_step :delivery

  set_callback :updating_from_params, :before, :maybe_apply_il_tax

  def maybe_apply_il_tax
    if has_checkout_step?("payment") && self.payment?
      if illinois_zip_code? and self.tax_zone.nil?
        create_tax_charge!
        flash.keep
        redirect_to checkout_state_path("payment")
      end
    end
  end

  private

    def illinois_zip_code?
      url = 'http://production.shippingapis.com?API=CityStateLookup'
      xml = '&XML=<CityStateLookupRequest USERID="932GREYS0655"><ZipCode ID="0"><Zip5>' + @updating_params["order"]["bill_address_attributes"]["zipcode"] + '</Zip5></ZipCode></CityStateLookupRequest>'
      request = url + URI::encode(xml)
      req = HTTParty.get(request)
      response = req.parsed_response["CityStateLookupResponse"]["ZipCode"]

      if response["State"] == "IL"
        bill_address = self.build_bill_address({
          city:      response["City"].titleize, 
          state:     Spree::State.find_by!(abbr: "IL"),
          zipcode:   response["Zip5"], 
          country:   Spree::Country.find_by!(iso: "US"),
          firstname: @updating_params["order"]["bill_address_attributes"]["firstname"],
          lastname:  @updating_params["order"]["bill_address_attributes"]["lastname"],
          address1:  @updating_params["order"]["bill_address_attributes"]["address1"],
          phone: "1234567890"
        })

        #flash["notice"] = "Illinois Tax has been applied to your order."
        #do in controller, get rid of phone requirement

        # properties of self include tax_zone, all_adjustments, tax_address
      else
        false
      end
    end

    def require_email
      return true unless new_record? or ['cart', 'address', 'payment'].include?(state)
    end

end