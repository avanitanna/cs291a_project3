# frozen_string_literal: true

require 'eventmachine'
require 'sinatra'
require 'json'
require 'jwt'

SCHEDULE_TIME = 32
connections = []


$connected_users = []
$all_users = [] #list of all user objects
#$users_pwds = Hash.new 
#$events = [] #check for join/part events
#$join_messages = []
#$part_messages = []
#$messages = []
# {"event": "JOIN"/"PART"/"Message/ServerStatus/Users/Disconnect", "created/timeStamp:", "id": counter/sequential}
# {id: {event_name, created, message, users, user,status}}
$events = Hash.new
$event_counter = 1

#As per the requirements First event should be server status therefore, 
$events[0] = {"event": "ServerStatus", "created": Time.now.to_f.to_s, "message": "", "users": [],
         "user": "", "status": "Server start"}

# Add options to specify CORS headers
options '/message' do
  headers 'Access-Control-Allow-Origin' => '*'
  headers 'Access-Control-Allow-Credentials' => 'true'
  headers 'Access-Control-Allow-Methods' => 'GET,HEAD,OPTIONS,POST,PUT'
  headers 'Access-Control-Allow-Headers' => 'Access-Control-Expose-Headers, Token, Authorization, Access-Control-Allow-Headers, Origin,Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers'
end

def funcJoin(msg_data)
  return {
    "created": msg_data["created"],
    "user": msg_data["user"]
}

end

def funcPart(msg_data)
  return {
    "created": msg_data["created"],
    "user": msg_data["user"]
}

end

def funcServerStatus(msg_data)
  return {
    "created": msg_data["created"],
    "status": msg_data["status"]
}

end

def funcUsers(msg_data)
  return {
    "created": msg_data["created"],
    "users": $active_users
    
}

end

def funcMessage(msg_data)
  return {
    "created": msg_data["created"],
    "message": msg_data["message"],
    "user": msg_data["user"]
}

end

def funcDisconnect(msg_data)
  return {
    "created": msg_data["created"]
}

end

$secret_message = "my_message_secret"
$secret_stream = "my_stream_secret"

class Clients 

  #@@events = Hash.new #last 100 messages
  def initialize(username, password, stream_token, message_token, user_stream = FALSE, user_lasteventid = 0)
    @username = username
    @password = password
    @stream_token = stream_token
    @message_token = message_token
    @user_stream = user_stream
    @user_lasteventid = user_lasteventid
    #@last_message_user = last_message_user#last message broadcasted to a user?
  
  end


end


EventMachine.schedule do
  EventMachine.add_periodic_timer(SCHEDULE_TIME) do
    # Change this for any timed events you need to schedule.
    puts "This message will be output to the server console every #{SCHEDULE_TIME} seconds"
  end
end

get '/stream/:token', provides: 'text/event-stream' do
  headers 'Access-Control-Allow-Origin' => '*'

  #TO DO Bearer match - dont have to as the stream token is in the URL
  #puts params
  username = ""
  stream_exists = FALSE
  if params.key?('token') and params['token']!=""
    user_match = FALSE
    for user in $all_users
      if user.instance_variable_get(:@stream_token) == params['token']
        username = user.instance_variable_get(:@username)
        stream_exists = user.instance_variable_get(:@user_stream)
        #user_match = TRUE

        if stream_exists == TRUE ## are we sending messages in this case? - no 
          status 409
          return
        else
          user.instance_variable_set(:@user_stream,TRUE)
          stream(:keep_open) do |connection|
            connections << connection
            
            #update class variable user_stream 

            # for user in $all_users
            #   if user.instance_variable_get(:username) == username
            #     user.instance_variable_set(:user_stream) = TRUE
            #     break
            #   end
            # end

            ## when you open the stream, you broadcast join. post message broadcast messages
            connection << "data: Welcome!\n\n"
            #when any event is created, we add a timestamp time.now.to_f.to_s...
            idx = request.env.filter { |x| x.start_with?('HTTP_Last-Event-Id') } 
            user_status = ""
            if idx == nil or not $events.key? idx
              idx = 0 #this will be considered as a new connection 
              user_status = "new_user"
            end

            ### CHECK?? if the stream of the user is open, increment the last event id counter by 1 for that user. We are assuming that if the stream is open, the user would have received the above message
            #active_users can be used to for getting the list of connected users for Users event
            $active_users = []
            for usr in $all_users
              if usr.instance_variable_get(:@user_stream) == TRUE
                active_users.append(usr.instance_variable_get(:@username))
                usr.instance_variable_set(:@user_lasteventid, $event_counter)
              end
            end
            
            ## send join to that user himself - store join id in the class and send/broadcast it to the user here as now his stream is open 
            #Send users event here
            
            for event_id in idx..$events.length()-1 do
              event_val = $events[event_id] 
              if event_val["event"] == "JOIN" and user_status != "new_user"
                connection << "data: "+funcJoin(event_val).to_s+"\n"+"event: "+event_val["event"]+"\n"+"id: "+event_id.to_s+"\n\n" #TO do - verify how to return these three fields
              elsif event_val["event"] == "PART" and user_status != "new_user"
                connection << "data: "+funcPart(event_val).to_s+"\n"+"event: "+event_val["event"]+"\n"+"id: "+event_id.to_s+"\n\n"
              elsif event_val["event"] == "ServerStatus"
                connection << "data: "+funcServerStatus(event_val).to_s+"\n"+"event: "+event_val["event"]+"\n"+"id: "+event_id.to_s+"\n\n"
              elsif event_val["event"] == "Users"
                connection << "data: "+funcUsers(event_val).to_s+"\n"+"event: "+event_val["event"]+"\n"+"id: "+event_id.to_s+"\n\n"
              ### TO DO - Disconnect only to be sent to the user who quits. Not to be broadcasted. Also this is not broadcasting.
              #elsif event_val["event"] == "Disconnect"
                #connection << "data: "+funcDisconnect(event_val).to_s+"\n"+"event: "+event_val["event"]+"\n"+"id: "+event_id.to_s+"\n\n"
              else 
                connection << "data: "+funcMessage(event_val).to_s+"\n"+"event: "+event_val["event"]+"\n"+"id: "+event_id.to_s+"\n\n"
              end
            end
            ## req.env HTTP_last_event_id... check this header and check the index msg idx == last event id , send messages after that index 
            ## if nil, send everything 
            ## open stream, server status, user list and all our history - message id 
            ### TO DO - add last event id to check which ones are to be sent to a user 
            # if $connected_users.include?(username) #decode token to get username JWT decode !! is in connected_users
            #   connection << $events
            # else
            #   $events.each{|event| connection << event if event.include?("event: Join") or event.include?("event: part")}
            #   #connection << $events #without join and part 
            # end
            connection.callback do
              puts 'callback'
              connections.delete(connection)
            end
          end
        end

        # TO DO create body with 'users' and 'created' - check specifications!!
        status 200
        return
        #break
      end
      
    end
    status 403
    return 
    # if user_match == FALSE
    #   status 403
    #   return 
      #username = JWT.decode(params['token'], $secret_stream, true).split(\n)[0].to_s
      #for user in $all_users
        #if user.instance_variable_get(:@username) == username
          #if user.instance_variable_get(:@user_stream) == True #user.connection is not False, that is connection exists
      
    # end
  else
    status 403
    return
  end
end
  # stream(:keep_open) do |connection|
  #   connections << connection

  #   connection << "data: Welcome!\n\n"

  #   connection.callback do
  #     puts 'callback'
  #     connections.delete(connection)
  #   end
  # end


# get '/stream/:token', provides: 'text/event-stream' do
#   headers 'Access-Control-Allow-Origin' => '*'
#   stream(:keep_open) do |connection|
#     connections << connection

#     connection << "data: Welcome!\n\n"

#     connection.callback do
#       puts 'callback'
#       connections.delete(connection)
#     end
#   end
# end

# post '/login' do
#   [422, 'POST /login\n']
# end

## To do - increment last event id by 1 for every user and broadcast join message, i.e. open stream for every user
post '/login' do
  headers 'Access-Control-Allow-Origin' => '*'
  # if username and password fields are provided by the client
  if params.key?('username') and params.key?('password') and params.keys.length() == 2
    username = params['username']
    password = params['password']

    #provided two fields do not match the expected two fields
    if username == "" or password == ""
      status 422
      return 
    end

    #if the stream is already open for username (Could be an issue) I dont think we need connection
    # if $connected_users.include?(username)
    #   status 409
    #   return 
    # end

    payload = {'data': username+"\n"+Time.now.to_f.to_s} #what if username has an underscore or any other character including a space
    message_token = JWT.encode payload, $secret_message, 'HS256'
    stream_token = JWT.encode payload, $secret_stream, 'HS256'
    for user in $all_users
      if user.instance_variable_get(:@username) == username
        #if the stream is already open
        if user.instace_variable_get(:@user_stream) == TRUE
            status 409
            return
        #if the username matches but the password does not
        if user.instance_variable_get(:@password) != password
          status 403
          return 
        else
          user.instance_variable_set(:@stream_token, stream_token) 
          user.instance_variable_set(:@message_token, message_token)
          #Setting Stream instance variable as true
          user.instace_variable_set(:@user_stream, TRUE)
          
          #$connected_users.append(username)

          ### BROADCAST JOIN - check????
          time_stamp = Time.now.to_f.to_s
          $events[$event_counter] = {"event": "JOIN", "created": time_stamp, 
                              "message": "", "users": [], "user": username, "status": ""}
          connections.each do |connection|  ## create msg templates, create event, then broadcast it
            # time_stamp = Time.now.to_f.to_s
            # $events[$event_counter] = {"event": "JOIN", "created": time_stamp, 
            #                   "message": "", "users": [], "user": username, "status": ""}
            connection << "data: "+funcJoin($events[$event_counter]).to_s+"\n"+"event: "+$events[$event_counter]["event"]+"\n"+"id: "+$event_counter.to_s+"\n\n" ### CHECK???? #TO DO- how do we check ids of each of the messages? #"data: Goodbye!\n\n" #TO DO - is it broadcasting the message?
            connection.close  # This call will trigger connection.callback
          end
          ### CHECK?? if the stream of the user is open, increment the last event id counter by 1 for that user. We are assuming that if the stream is open, the user would have received the above message
          
          #Changing the event id of all the users connected to stream
          for usr in $all_users
            if usr.instance_variable_get(:@user_stream) == TRUE
              usr.instance_variable_set(:@user_lasteventid, $event_counter)
            end
          end

          #increment global event counter
          $event_counter+=1
          return [201,{"message_token": message_token, "stream_token":stream_token}.to_json]
          #status 201
          #return
        end
      end
    end
    
    #user = Clients.new(username, password, stream_token, message_token)
    #$connected_users.append(username)
    #We are also opening the stream at this point
    user = Clients.new(username, passwod, stream_token, message_token, TRUE)
    $all_users.append(user)
    ### BROADCAST JOIN - check????
    time_stamp = Time.now.to_f.to_s
    $events[$event_counter] = {"event": "JOIN", "created": time_stamp, 
                        "message": "", "users": [], "user": username, "status": ""}
    connections.each do |connection|  ## create msg templates, create event, then broadcast it
      # time_stamp = Time.now.to_f.to_s
      # $events[$event_counter] = {"event": "JOIN", "created": time_stamp, 
      #                   "message": "", "users": [], "user": username, "status": ""}
      connection << "data: "+funcJoin($events[$event_counter]).to_s+"\n"+"event: "+$events[$event_counter]["event"]+"\n"+"id: "+$event_counter.to_s+"\n\n" ### CHECK???? #TO DO- how do we check ids of each of the messages? #"data: Goodbye!\n\n" #TO DO - is it broadcasting the message?
      connection.close  # This call will trigger connection.callback
    end

    #increment global event counter
    $event_counter+=1
    #puts $events 
    return [201,{"message_token": message_token, "stream_token":stream_token}.to_json]
    #{"message_token": message_token, "stream_token":stream_token}.to_json
    #status 201
    return
  else
    status 422
    return
  end
    #[422, 'POST /login\n']
end


post '/message' do
  headers 'Access-Control-Allow-Origin' => '*'
  require 'pp'
  if not request.env.filter { |x| x.start_with?('HTTP_AUTHORIZATION') } 
    status 422
    return 
  end
  if not params.key?('message') or params['message']=="" or params.keys.length()!=1
    status 422
    return 
  end 
  ## TO DO - check if HTTP_AUTHORIZATION and Bearer are case sensitive checks 
  message_token = request.env.filter { |x| x.start_with?('HTTP_AUTHORIZATION') }['HTTP_AUTHORIZATION'].to_s
  message_bearer = message_token.split(' ')[0]
  message_token = message_token.split(' ')[1]
  if not message_bearer == "Bearer"
    status 403
    return 
  end 
  for user in $all_users
    if user.instance_variable_get(:@message_token) == message_token
      username = user.instance_variable_get(:@username)
      payload = {'data': username+"\n"+Time.now.to_f.to_s}
      message_token_new = JWT.encode payload, $secret_message, 'HS256'
      user.instance_variable_set(:@message_token, message_token_new)
      if user.instance_variable_get(:@user_stream) == FALSE
        status 409
        return 
      else
        # connections.each do |connection|  ## create msg templates, create event, then broadcast it 
        #   connection << params['message'].to_s #TO DO- how do we check ids of each of the messages? #"data: Goodbye!\n\n" #TO DO - is it broadcasting the message?
        #   connection.close  # This call will trigger connection.callback
        ## BROADCAST - check????
        time_stamp = Time.now.to_f.to_s
        $events[$event_counter] = {"event": "Message", "created": time_stamp, 
                            "message": params["message"].to_s, "users": [], "user": username, "status": ""}
        connections.each do |connection|  ## create msg templates, create event, then broadcast it
          # time_stamp = Time.now.to_f.to_s
          # $events[$event_counter] = {"event": "Message", "created": time_stamp, 
          #                   "message": params["message"].to_s, "users": [], "user": username, "status": ""}
          connection << "data: "+funcMessage($events[$event_counter]).to_s+"\n"+"event: "+$events[$event_counter]["event"]+"\n"+"id: "+$event_counter.to_s+"\n\n" ### CHECK???? #TO DO- how do we check ids of each of the messages? #"data: Goodbye!\n\n" #TO DO - is it broadcasting the message?
          connection.close  # This call will trigger connection.callback
        end
        ### CHECK?? if the stream of the user is open, increment the last event id counter by 1 for that user. We are assuming that if the stream is open, the user would have received the above message
        for usr in $all_users
          if usr.instance_variable_get(:@user_stream) == TRUE
            usr.instance_variable_set(:@user_lasteventid, $event_counter)
          end
        end

        # increment global event counter
        $event_counter+=1
        puts $events
        [201,{"Token": message_token_new}.to_json] #TO /do broadcast message to allusers??
        return 
      end
    end
  end
  status 403
  return 
end


#Code added or modified:
#1. Created first event and changed the initial value of event counter to 1
#2. removed connected_users array and added support for looping to check if the stream is open in Post /login
#3. Created a template for sending Users event whenever a new user is logs in
#4. created template for reconnect, quit and kick (see below) 





#Additional code for /post message
# if params.has_key?"reconnect"
#     #Send part to everyone
#   if params.has_key?"quit"
#     #Send disconnect to sending user
#     #bradcast part for that user
#   if params.has_key?"kick"
#     kick_username = params[:kick]
#     #check if the username is current user or the username does not exist
#     for user in $all_users
#       if user.instance_variable_get(:@message_token) == message_token
#         username = user.instance_variable_get(:@username) 
#         if kick_username == username
#           status 409
#           return
#         else
#           #Part message to everyone
#           status 201
#         end
#       end
#     end
#     #username does not exist in the database
#     status 409

# post '/message' do
#   require 'pp'
#   #PP.pp(request.env.filter { |x| x.start_with?('HTTP_AUTHORIZATION') })
#   connections.each do |connection|
#     connection << "data: Goodbye!\n\n"
#     connection.close  # This call will trigger connection.callback
#   end

#   puts 'Headers'
#   PP.pp(request.env.filter { |x| x.start_with?('HTTP_') })
#   puts

#   puts 'request.params:'
#   PP.pp request.params
#   puts

#   [403, "POST /message\n"]
# end
