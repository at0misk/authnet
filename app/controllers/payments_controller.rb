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

  def success
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
    setting3.settingName = SettingNameEnum::HostedPaymentPaymentOptions
    setting3.settingValue = "{\"cardCodeRequired\": true}"
    
    setting3 = SettingType.new
    setting3.settingName = SettingNameEnum::HostedPaymentIFrameCommunicatorUrl
    setting3.settingValue = "{\"url\": \"https://stark-fjord-22096.herokuapp.com/sign_success\"}"

    setting4 = SettingType.new
    setting4.settingName = SettingNameEnum::HostedPaymentReturnOptions
    setting4.settingValue = "{\"showReceipt\": false}"

    setting5 = SettingType.new
    setting5.settingName = SettingNameEnum::HostedPaymentCustomerOptions
    setting5.settingValue = "{\"showEmail\": true, \"requiredEmail\": true,}"

    settings = Settings.new([ setting1, setting2, setting3, setting4, setting5])
    
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

def create_profile()
    transaction = Transaction.new('8e9bG3YDG843', '7aV3ru72Wp9rn5Xc', :gateway => :sandbox)

    
    request = CreateCustomerProfileFromTransactionRequest.new
    request.transId = params['id']
  
    response = transaction.create_customer_profile_from_transaction(request)
    puts response.customerProfileId
    @paymentId = response.customerPaymentProfileIdList.numericString[0]
    puts @paymentId
    # fail


    if response.messages.resultCode == MessageTypeEnum::Ok
      puts "Successfully created a customer profile from the transaction id #{response.customerProfileId}"
      redirect_to "/create_subscription/#{response.customerProfileId}/#{@paymentId}"
    else
      puts response.messages.messages[0].text
      raise "Failed to create a customer profile from an existing transaction."
    end
    # return response
  end

  def get_list_of_subscriptions()
    transaction = Transaction.new('8e9bG3YDG843', '7aV3ru72Wp9rn5Xc', :gateway => :sandbox)
    request = ARBGetSubscriptionListRequest.new
    request.refId = '1'
    
    request.searchType = ARBGetSubscriptionListSearchTypeEnum::SubscriptionActive
    request.sorting = ARBGetSubscriptionListSorting.new
    request.sorting.orderBy = 'id'
    request.sorting.orderDescending = 'false'
    
    request.paging = Paging.new
    request.paging.limit = '1000'
    request.paging.offset = '1'
  
  
    response = transaction.get_subscription_list(request)
    
  
    if response != nil
      if response.subscriptionDetails.length > 0 
        puts 'found'
        fail
      end
      if response.messages.resultCode == MessageTypeEnum::Ok
        puts "Successfully got the list of subscriptions"
        puts response.messages.messages[0].code
        puts response.messages.messages[0].text

        response.subscriptionDetails.subscriptionDetail.each do |sub|
          puts "Subscription #{sub.id} #{sub.name}  Status : #{sub.status}"
          
        end
    
      else
    
        puts response.messages.messages[0].code
        puts response.messages.messages[0].text
        raise "Failed to get the list of subscriptions"
      end
    end
    redirect_to '/'
 end


  def create_subscription()
    transaction = Transaction.new('8e9bG3YDG843', '7aV3ru72Wp9rn5Xc', :gateway => :sandbox)
  
    request = ARBCreateSubscriptionRequest.new
    request.subscription = ARBSubscriptionType.new
    request.subscription.name = "CUSTOMER NAME:"
    request.subscription.paymentSchedule = PaymentScheduleType.new
    request.subscription.paymentSchedule.interval = PaymentScheduleType::Interval.new("3","months")
    request.subscription.paymentSchedule.startDate = (DateTime.now).to_s[0...10]
    request.subscription.paymentSchedule.totalOccurrences ='12'
    request.subscription.paymentSchedule.trialOccurrences ='1'

    random_amount = ((SecureRandom.random_number + 1 ) * 150 ).round(2)
    request.subscription.amount = random_amount
    request.subscription.trialAmount = 0.00

  request.subscription.profile = CustomerProfileIdType.new
  puts params['customerId']
  request.subscription.profile.customerProfileId = params['customerId']
    request.subscription.profile.customerPaymentProfileId = params['paymentId']
    # request.subscription.profile.customerAddressId = addressId
  
    response = transaction.create_subscription(request)

  puts response.messages.to_yaml()
  
    if response != nil
      if response.messages.resultCode == MessageTypeEnum::Ok
        puts "Successfully created a subscription #{response.subscriptionId}"
      else
        puts response.messages.messages[0].code
        puts response.messages.messages[0].text
        raise "Failed to create a subscription"
      end
    end
    flash[:success] = "Subscription Created"
    redirect_to '/'
  end

end