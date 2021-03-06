get '/admin' do
  redirect '/login' unless current_user

  @orders = Order.all

  erb :'order/all'
end

get '/admin/order/:id' do |id|
  redirect '/login' unless current_user

  @order = Order.find(id)

  erb :'order/admin_show'
end

post '/admin/order/:id/process' do |id|
  order = Order.find(id)
  order.processed = ! order.processed
  order.save

  redirect '/admin'
end

post '/order' do
  @order = Order.create

  params[:photos].each do |index, photo_data|
    @order.photos << Photo.create(photo_data)
  end

  erb :'order/show', layout: false
end

post '/order/:id/paid' do |id|
  order = Order.find(id)
  useful_params = {}
  %w(stripeToken stripeEmail stripeShippingName stripeShippingAddressLine1 stripeShippingAddressApt stripeShippingAddressZip stripeShippingAddressCity stripeShippingAddressState stripeShippingAddressCountry stripeShippingAddressCountryCode).each do |attr|
    useful_params[attr] = params[attr]
  end
  order.update_attributes(useful_params)

  token = params[:stripeToken]

  begin
    charge = Stripe::Charge.create(
      :amount => 1000, # amount in cents, again
      :currency => "usd",
      :source => token,
      :description => "Instant Tattoos"
    )
  rescue Stripe::CardError => e
    # The card has been declined
    redirect "/order/#{order.id}?error=card%20declined"
  end 

  order.paid = true
  order.save

  erb :'order/paid'
end

get '/order/:id' do |id|
  @order = Order.find(id)
  @error = params[:error]
  erb :'order/show'
end