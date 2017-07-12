class PaymentsController < ApplicationController

  layout 'authorize_net'
  helper :authorize_net
  protect_from_forgery :except => :relay_response

  # GET
  # Displays a payment form.
  def payment
    # Sets up form
    @amount = 10.00
    @sim_transaction = AuthorizeNet::SIM::Transaction.new('8e9bG3YDG843', '7aV3ru72Wp9rn5Xc', @amount, :relay_url => payments_relay_response_url(:only_path => false))
    # puts "======"
    # puts @sim_transaction.fingerprint
    # fail
  end

  # POST
  # Returns relay response when Authorize.Net POSTs to us.
  def relay_response
    sim_response = AuthorizeNet::SIM::Response.new(params)
    if sim_response.success?('9CPC3p3r8J', 'Pbdg01350')
      render :text => sim_response.direct_post_reply(payments_receipt_url(:only_path => false), :include => true)
    else
      render
    end
  end

  # GET
  # Displays a receipt.
  def receipt
    @auth_code = params[:x_auth_code]
    # redirect_to 'http://www.google.com'
  end

  def accept
  end

# Doc sample code below, just run without rails to simulate a successful transaction
require 'rubygems'
  require 'yaml'
  require 'authorizenet' 

 require 'securerandom'

  include AuthorizeNet::API

  def get_an_accept_payment_page()
    # config = YAML.load_file(File.dirname(__FILE__) + "/../credentials.yml")

    transaction = Transaction.new('8e9bG3YDG843', '7aV3ru72Wp9rn5Xc', :gateway => :sandbox)
    # !!!important Switch gateway to production in live mode !!!important

    transactionRequest = TransactionRequestType.new
    transactionRequest.amount = 12.12
    transactionRequest.transactionType = TransactionTypeEnum::AuthCaptureTransaction
    
    setting1 = SettingType.new
    setting1.settingName = SettingNameEnum::HostedPaymentButtonOptions
    setting1.settingValue = "{\"text\": \"Pay\"}"

    setting2 = SettingType.new
    setting2.settingName = SettingNameEnum::HostedPaymentOrderOptions
    setting2.settingValue = "{\"show\": false}"

    setting3 = SettingType.new
    setting3.settingName= SettingNameEnum::HostedPaymentPaymentOptions
    setting3.settingValue = "{\"cardCodeRequired\": true}"
    
    setting3 = SettingType.new
    setting3.settingName= SettingNameEnum::hostedPaymentIFrameCommunicatorUrl
    setting3.settingValue = "{\"url\": https://google.com}"

    settings = Settings.new([ setting1, setting2, setting3])
    
    request = GetHostedPaymentPageRequest.new
    request.transactionRequest = transactionRequest
    request.hostedPaymentSettings = settings
    
    response = transaction.get_hosted_payment_page(request)
    if response.messages.resultCode == MessageTypeEnum::Ok
      puts "#{response.messages.messages[0].code}"
      puts "#{response.messages.messages[0].text}"
      puts "#{response.token}"
      @token = response.token
    else
      puts "#{response.messages.messages[0].code}"
      puts "#{response.messages.messages[0].text}"
      # raise "Failed to get hosted payment page"
    end
    # return response
  end
  
if __FILE__ == $0
  get_an_accept_payment_page()
end

# Creates a subscription
  def create_Subscription
    # config = YAML.load_file(File.dirname(__FILE__) + "/../credentials.yml")
  
    transaction = Transaction.new('8e9bG3YDG843', '7aV3ru72Wp9rn5Xc', :gateway => :sandbox)
    #subscription = Subscription.new(config['api_login_id'], config['api_subscription_key'], :gateway => :sandbox)
  
    request = ARBCreateSubscriptionRequest.new
    request.refId = DateTime.now.to_s[-8]
    request.subscription = ARBSubscriptionType.new
    request.subscription.name = "Jane Doe"
    request.subscription.paymentSchedule = PaymentScheduleType.new
    request.subscription.paymentSchedule.interval = PaymentScheduleType::Interval.new("3","months")
    request.subscription.paymentSchedule.startDate = (DateTime.now).to_s[0...10]
    request.subscription.paymentSchedule.totalOccurrences ='12'
    request.subscription.paymentSchedule.trialOccurrences ='1'

    random_amount = ((SecureRandom.random_number + 1 ) * 150 ).round(2)
    request.subscription.amount = random_amount
    request.subscription.trialAmount = 0.00
    request.subscription.payment = PaymentType.new
    request.subscription.payment.creditCard = CreditCardType.new('4111111111111111','0120','123')

    request.subscription.order = OrderType.new('invoiceNumber123','description123')
    request.subscription.customer =  CustomerDataType.new(CustomerTypeEnum::Individual,'custId1','a@a.com')
    request.subscription.billTo = NameAndAddressType.new('John','Doe','xyt','10800 Blue St','New York','NY','10010','USA')
    request.subscription.shipTo = NameAndAddressType.new('John','Doe','xyt','10800 Blue St','New York','NY','10010','USA')

    response = transaction.create_subscription(request)
     
    if response != nil
      if response.messages.resultCode == MessageTypeEnum::Ok
        puts "Successfully created a subscription #{response.subscriptionId}"
    
      else
        #puts response.transactionResponse.errors.errors[0].errorCode
        #puts response.transactionResponse.errors.errors[0].errorText
        puts response.messages.messages[0].code
        puts response.messages.messages[0].text
        raise "Failed to create a subscription"
      end
    end
    return response
  end

  def create_customer_profile()
    # config = YAML.load_file(File.dirname(__FILE__) + "/../credentials.yml")

    transaction = Transaction.new(config['api_login_id'], config['api_transaction_key'], :gateway => :sandbox)

    
    request = CreateCustomerProfileRequest.new
    payment = PaymentType.new(CreditCardType.new('4111111111111111','2020-05'))
    profile = CustomerPaymentProfileType.new(nil,nil,payment,nil,nil)

    request.profile = CustomerProfileType.new('jdoe'+rand(10000).to_s,'John2 Doe',rand(10000).to_s + '@mail.com', [profile], nil)

    response = transaction.create_customer_profile(request)


    if response.messages.resultCode == MessageTypeEnum::Ok
      puts "Successfully created aX customer profile with id:  #{response.customerProfileId}"
      puts "Customer Payment Profile Id List:"
      response.customerPaymentProfileIdList.numericString.each do |id|
        puts id
      end
      puts "Customer Shipping Address Id List:"
      response.customerShippingAddressIdList.numericString.each do |id|
        puts id
      end
    else
      puts response.messages.messages[0].text
      raise "Failed to create a new customer profile."
    end
    return response
  end


  def create_subscription_from_customer_profile(profileId = "123213", paymentProfileId = "123213", addressId = "123213")
    # config = YAML.load_file(File.dirname(__FILE__) + "/../credentials.yml")
  
    transaction = Transaction.new(config['api_login_id'], config['api_transaction_key'], :gateway => :sandbox)
    #subscription = Subscription.new(config['api_login_id'], config['api_subscription_key'], :gateway => :sandbox)
  
    request = ARBCreateSubscriptionRequest.new
    request.refId = DateTime.now.to_s[-8]
    request.subscription = ARBSubscriptionType.new
    request.subscription.name = "Jane Doe"
    request.subscription.paymentSchedule = PaymentScheduleType.new
    request.subscription.paymentSchedule.interval = PaymentScheduleType::Interval.new("3","months")
    request.subscription.paymentSchedule.startDate = (DateTime.now).to_s[0...10]
    request.subscription.paymentSchedule.totalOccurrences ='12'
    request.subscription.paymentSchedule.trialOccurrences ='1'

    random_amount = ((SecureRandom.random_number + 1 ) * 150 ).round(2)
    request.subscription.amount = random_amount
    request.subscription.trialAmount = 0.00

  request.subscription.profile = CustomerProfileIdType.new
  request.subscription.profile.customerProfileId = profileId
    request.subscription.profile.customerPaymentProfileId = paymentProfileId
    request.subscription.profile.customerAddressId = addressId
  
    response = transaction.create_subscription(request)

  puts response.messages.to_yaml()
  
    if response != nil
      if response.messages.resultCode == MessageTypeEnum::Ok
        puts "Successfully created a subscription #{response.subscriptionId}"
      else
        #puts response.transactionResponse.errors.errors[0].errorCode
        #puts response.transactionResponse.errors.errors[0].errorText
        puts response.messages.messages[0].code
        puts response.messages.messages[0].text
        raise "Failed to create a subscription"
      end
    end
    return response
  end

if __FILE__ == $0
  create_Subscription_from_customer_profile()
end



if __FILE__ == $0
  create_Subscription()
end

end