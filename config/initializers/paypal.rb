require 'paypal-sdk-rest'

require "securerandom"

include PayPal::SDK::REST
include PayPal::SDK::Core::Logging

PayPal::SDK::REST.set_config(
                    :mode => "sandbox", # "sandbox" or "live"
                    :client_id => 'Abg_mhCUNxW4qavtKUIKBXc_suOiDl9LelgpCHcBw9zqAI5cAbVHEy2Wg8TzMkyU_kOoOMhxhz2mmC4C',
                    :client_secret => "EI3jZ8wuW12pWwn_XC7NQdBuAbvBTXWGcYWfGAXDIrXtGjvLvg_XJFLSIYdFusqT1oqFcgX4GU6UXF6p")

@webhook = Webhook.new({
    :url => "https://bmarket-rbm4.c9users.io/paypal",
    :event_types => [
        {
            :name => "PAYMENT.AUTHORIZATION.CREATED"
        },
        {
            :name => "PAYMENT.AUTHORIZATION.VOIDED"
        }
    ]
})
begin
@webhooks_list = Webhook.all()
puts 'webhook list'

  logger.info "List Webhooks:"
  @webhooks_list.webhooks.each do |webhook|
    logger.info " -> Webhook Event Name[#{webhook.id}]"
  end

rescue ResourceNotFound => err
  logger.error "Webhooks not found"
ensure
  # Clean up webhooks as not to get into a bad state#
  puts 'teste'
  @webhooks_list.webhooks.each do |webhook|
      webhook.delete
  end
end

begin
  @webhook = @webhook.create
  logger.info "Webhook[#{@webhook.id}] created successfully"
rescue ResourceNotFound => err
  logger.error @webhook.error.inspect
end

