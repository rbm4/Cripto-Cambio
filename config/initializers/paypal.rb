require 'paypal-sdk-rest'

require "securerandom"

include PayPal::SDK::REST
include PayPal::SDK::Core::Logging

PayPal::SDK::REST.set_config(
                    :mode => "live", # "sandbox" or "live"
                    :client_id => ENV["PAYPAL_ID"],
                    :client_secret => ENV["PAYPAL_SECRET"])

#@webhook = Webhook.new({
#    :url => "https://mkta.herokuapp.com/paypal",
#    :event_types => [
#        {
#            :name => "PAYMENT.AUTHORIZATION.CREATED"
#        },
#        {
#            :name => "PAYMENT.AUTHORIZATION.VOIDED"
#        }
#    ]
#})
#begin
#@webhooks_list = Webhook.all()
#puts 'webhook list'

  #logger.info "List Webhooks:"
  #@webhooks_list.webhooks.each do |webhook|
  #  logger.info " -> Webhook Event Name[#{webhook.id}]"
  #end

#rescue ResourceNotFound => err
#  logger.error "Webhooks not found"
#ensure
  # Clean up webhooks as not to get into a bad state#
#  puts 'teste'
#  @webhooks_list.webhooks.each do |webhook|
#      webhook.delete
#  end
#end

#begin
#  @webhook = @webhook.create
#  logger.info "Webhook[#{@webhook.id}] created successfully"
#rescue ResourceNotFound => err
#  logger.error @webhook.error.inspect
#end

