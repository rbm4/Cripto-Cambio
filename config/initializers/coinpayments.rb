Coinpayments.configure do |config|
  config.merchant_id     = "#{ENV["COINPAY_ID"]}"
  config.public_api_key  = "#{ENV["COINPAY_PUBK"]}"
  config.private_api_key = "#{ENV["COINPAY_PRIVK"]}"
end
