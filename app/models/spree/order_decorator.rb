Spree::Order.class_eval do
  remove_checkout_step :address
  remove_checkout_step :delivery

  def confirmation_required?
    false
  end

  private
    def require_email
      return true unless new_record? or ['cart', 'address', 'payment'].include?(state)
    end

end