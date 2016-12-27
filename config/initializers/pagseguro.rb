PagSeguro.configure do |config|
  config.token       = "00A92577FCAF42E094AC514713498B5F" #"CEB2E4B937F8426A8BE9DB80D6DCCA8A"# <- sandbox # "00A92577FCAF42E094AC514713498B5F" #<- original
  config.email       = "ricardo.malafaia1994@gmail.com"
  config.environment = :production #:production # ou :sandbox. O padrão é production.
  config.encoding    = "UTF-8" # ou ISO-8859-1. O padrão é UTF-8.
end