class OrdersController < ApplicationController
    def show
    end
    def destroy
        current_order.destroy
        session[:order_id] = nil
        redirect_to '/store', @messages => "Basket emptied successfully."
    end
    def checkout
        @order = Shoppe::Order.find(current_order.id)
        if request.patch?
             if @order.proceed_to_confirm(params[:order].permit(:first_name, :billing_address1, :billing_address2, :billing_address3, :billing_address4, :billing_postcode, :email_address))
                  redirect_to checkout_payment_path
             end
        end
    end
    def payment
        if request.post?
            redirect_to checkout_confirmation_path
        end
    end
    def checkoutpgseguro
        @order = Shoppe::Order.find(current_order.id)
        if request.patch?
            if @order.proceed_to_confirm(params[:order].permit(:first_name, :billing_address1, :billing_address2, :billing_address3, :billing_address4, :billing_postcode, :email_address))
                redirect_to '/'
            end
        end
    end
end
