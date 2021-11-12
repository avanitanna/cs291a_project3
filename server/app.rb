# frozen_string_literal: true

require 'eventmachine'
require 'sinatra'
require 'json'
require 'jwt'


$start_time = Time.now.to_f

SCHEDULE_TIME = 3600
set :server_settings, :timeout => 20

connections = {}

$connected_users = []
$all_users = [] #list of all user objects

$events = Hash.new

$events[0] = {"event": "ServerStatus", "created": $start_time.to_s, "message":"", "users": [], "status": "Up since " + Time.at($start_time).to_s}
$event_counter = 1

# Add options to specify CORS headers
options '/message' do
    headers 'Access-Control-Allow-Origin' => '*'
    headers 'Access-Control-Allow-Credentials' => 'true'
    headers 'Access-Control-Allow-Methods' => 'GET,HEAD,OPTIONS,POST,PUT'
    headers 'Access-Control-Allow-Headers' => 'Access-Control-Expose-Headers, Token, Authorization, Access-Control-Allow-Headers, Origin,Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers'
end

def funcJoin(msg_data)
  return {
    "created": msg_data[:created],
    "user": msg_data[:user]
}.to_json
end

def funcPart(msg_data)
  return {
    "created": msg_data[:created],
    "user": msg_data[:user]
}.to_json
end

def funcServerStatus(msg_data)
  return {
    "created": msg_data[:created],
    "status": msg_data[:status]
}.to_json
end

def funcUsers(msg_data)
  return {
    "created": msg_data[:created],
    "users": msg_data[:users]  
}.to_json
end

def funcMessage(msg_data)
  return {
    "created": msg_data[:created],
    "message": msg_data[:message],
    "user": msg_data[:user]
}.to_json
end

def funcDisconnect(msg_data)
  return {
    "created": msg_data[:created]
}.to_json
end

$secret_message = "my_message_secret"
$secret_stream = "my_stream_secret"

stream_token_username_dict = Hash.new


class Clients 

  #@@events = Hash.new #last 100 messages
  #Added join index
  def initialize(username, password, stream_token, message_token, stream_variable = false, connection_variable=false,  connection_object = nil)
    @username = username
    @password = password
    @stream_token = stream_token
    @message_token = message_token
    @stream_variable = stream_variable
    @connection_variable = connection_variable
    @connection_object = connection_object
  
  end
end



EventMachine.schedule do
    EventMachine.add_periodic_timer(SCHEDULE_TIME) do
      message = "event: ServerStatus\ndata: {\"status\": \"up since\" + #{Time.at($start_time).to_s}, \"created\": #{Time.now.to_f.to_s}}\n\n\n"
      connections.each do |connection, username|
        connection << message
        #$all_messages << [message, true]
      end

    end
  end


def create_event(user_status, event_id)
  event_val = $events[event_id]
  #puts "event_id: " + event_id.to_s + " event_counter: " + $event_counter.to_s
  if event_id == nil
    return "\n\n"
  end
  #print(event_id)
  #print(event_val)
  if event_val[:event] == "Join" and user_status != "new_user"
    return "data: "+funcJoin(event_val).to_s+"\n"+"event: "+event_val[:event]+"\n"+"id: "+event_id.to_s+"\n\n" #TO do - verify how to return these three fields
  end
  if event_val[:event] == "Part" and user_status != "new_user"
    return "data: "+funcPart(event_val).to_s+"\n"+"event: "+event_val[:event]+"\n"+"id: "+event_id.to_s+"\n\n"
  end
  if event_val[:event] == "Message"
    return "data: "+funcMessage(event_val).to_s+"\n"+"event: "+event_val[:event]+"\n"+"id: "+event_id.to_s+"\n\n"
  end
  if event_val[:event] == "ServerStatus"
    return "data: "+funcServerStatus(event_val).to_s+"\n"+"event: "+event_val[:event]+"\n"+"id: "+event_id.to_s+"\n\n"
  end
  #puts "here"
  if event_val[:event] == "Users" and user_status == "never send"
    return "data: "+funcUsers(event_val).to_s+"\n"+"event: "+event_val[:event]+"\n"+"id: "+event_id.to_s+"\n\n"
  end
  #puts "before disconnect"
  #puts $events
  if event_val[:event] == "Disconnect" and user_status == "never send"
    return "data: "+funcDisconnect(event_val).to_s+"\n"+"event: "+event_val[:event]+"\n"+"id: "+event_id.to_s+"\n\n"
  end
end

def check_last_eventid(last_event_id)
    flag = 0
    if last_event_id.is_a? Integer
        return last_event_id
    else
        if last_event_id.to_i
            return last_event_id.to_i
        else
            return flag
        end
    end

end


get '/stream/:token', provides: 'text/event-stream' do
    headers 'Access-Control-Allow-Origin' => '*'
    if not params.key?('token') or params['token'] ==""
        status 403
        return
    end
    current_stream_token = params['token']
    
    token_found = 0
    username = ""
    
    for user in $all_users
        if user.instance_variable_get(:@stream_token) == current_stream_token
            username = user.instance_variable_get(:@username)
            if user.instance_variable_get(:@connection_variable) == true
                status 409
                return
            end
        end
    end
    if username == ""
        status 403
        return
    end

    stream(:keep_open) do |connection|
        for user in $all_users
            if user.instance_variable_get(:@username) == username
                user.instance_variable_set(:@connection_object, connection)
                user.instance_variable_set(:@connection_variable, true)
                connections[connection] = username
                connections.each do |connection, user|
                    time_stamp = Time.now.to_f.to_s
                    event = {"event": "Join", "created": time_stamp, "message": "", "users": [], "user": username, "status": ""}
                    $events[$event_counter] = event
                    connection << create_event("False", $event_counter)
                    $event_counter +=1 
                end

                lasteventid = request.env['HTTP_LAST_EVENT_ID']
                #puts "last event id : " + lasteventid.to_s
                lasteventid_new = check_last_eventid(lasteventid)
                if lasteventid_new !=0 and $events.include? lasteventid_new
                    lasteventid = lasteventid.to_i+1
                    for eventid in lasteventid+1..$event_counter-1 do 
                        connection << create_event("new_user", eventid)
                    end
                    

                else
                    #puts "Last event id is 0\n"
                    time_stamp = Time.now.to_f.to_s
                    active_users = []
                    for usr in $all_users
                        if usr.instance_variable_get(:@connection_variable) == true
                            usr_name = usr.instance_variable_get(:@username)
                            active_users.append(usr_name) 
                        end
                    end

                    # message = "event: ServerStatus\ndata: {\"status\": \"I am alive!\", \"created\": #{Time.now.to_f}}\n\n\n"
                    # connection << message
                    event = {"event": "Users", "created": time_stamp, "message":"", "users": active_users, "status": ""}
                    #event_id = $event_counter + 10000
                    $events[$event_counter] = event

                    message = "data: "+funcUsers(event).to_s+"\n"+"event: "+event[:event]+"\n"+"id: "+ $event_counter.to_s+"\n\n"
                    $event_counter += 1
                    #puts "\nUsers message: " + message + "\n\n"
                    connection << message
                    lasteventid = 0
                    for eventid in lasteventid..$event_counter -1 do
                        connection << create_event("new_user", eventid)
                    end
                end
            end
        end   
        
        connection.callback do
            username = connections[connection]
            connections.delete(connection)
            for user in $all_users
                if user.instance_variable_get(:@username) == username
                    user.instance_variable_set(:@connection_object, nil)
                end
            end
        end
    end
      
    status 200
    return 
end
    



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

    #Token payload and token creation
    payload = {'data': username+"\n"+Time.now.to_f.to_s}
    message_token = JWT.encode payload, $secret_message, 'HS256'
    stream_token = JWT.encode payload, $secret_stream, 'HS256'
    for user in $all_users
      if user.instance_variable_get(:@username) == username
        #if the stream is already open
        if user.instance_variable_get(:@connection_variable) == true
            status 409
            return
        end

        #if the username matches but the password does not
        if user.instance_variable_get(:@password) != password
          status 403
          return 
        else
          #setting token
          user.instance_variable_set(:@stream_token, stream_token) 
          user.instance_variable_set(:@message_token, message_token)
          
          return [201, {"message_token": message_token, "stream_token":stream_token}.to_json]
        end

      end
    end

    #When the username does not match
    user = Clients.new(username, password, stream_token, message_token)
    $all_users.append(user)
    time_stamp = Time.now.to_f.to_s
    return [201,{"message_token": message_token, "stream_token":stream_token}.to_json]
  else
    status 422
    return
  end
end

post '/message' do 
    headers 'Access-Control-Allow-Origin' => '*'
    #headers 'Access-Control-Allow-Headers' => 'Access-Control-Expose-Headers, Token, Authorization, Access-Control-Allow-Headers, Origin,Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers'
    headers 'Access-Control-Expose-Headers' => 'Token'
    if not request.env.filter { |x| x.start_with?('HTTP_AUTHORIZATION') } 
        status 422
        return 
    end

    #this needs update
    if not params.key?('message') or params['message']=="" or params.keys.length()!=1
        status 422
        return 
    end

    authorization_header = request.env['HTTP_AUTHORIZATION']
    if not authorization_header 
    #if not message_bearer == "Bearer"
        status 403
        return
    end
    message_bearer = authorization_header.split(' ')[0]
    message_token = authorization_header.split(' ')[1]
    if not authorization_header.split(' ')[0] == "Bearer"
        status 403
        return
    end
    username = ""
    stream_value = false
    for user in $all_users
        if user.instance_variable_get(:@message_token) == message_token
          username = user.instance_variable_get(:@username)
          stream_value = user.instance_variable_get(:@connection_variable)
        end
    end
    
    if username == ""
        status 403
        return
    end

    if stream_value == false
        status 409
        return
    end

    payload = {'data': username+"\n"+Time.now.to_f.to_s}
    message_token_new = JWT.encode payload, $secret_message, 'HS256'

    message = params['message']
    if message == "/reconnect" or message == "/quit" or message.include? "/kick "
        
        if message == "/quit"
            for user in $all_users
                if user.instance_variable_get(:@username) == username
                    connection_object = user.instance_variable_get(:@connection_object)
                    user.instance_variable_set(:@connection_object, nil)
                    user.instance_variable_set(:@connection_variable, false)
                end
            end
    
            time_stamp = Time.now.to_f.to_s
            event = {"event": "Part", "created": time_stamp, "message": "", "users": [], "user": username, "status": ""}
            $events[$event_counter] = event
            puts "Part event created\n"
            $event_counter += 1

            connections.each do |connection, user|
                if connections[connection] == username
                    time_stamp = Time.now.to_f.to_s
                    disconnect_event = {"event": "Disconnect", "created": time_stamp, "message": "", "users": [], "user": username, "status": ""}
                    $events[$event_counter] = disconnect_event
                    connection << "data: "+funcDisconnect(disconnect_event).to_s+"\n"+"event: "+disconnect_event[:event]+"\n"+"id: "+$event_counter.to_s+"\n\n"
                    #puts "sent disconnect event : " + "data: "+funcDisconnect(disconnect_event).to_s+"\n"+"event: "+disconnect_event[:event]+"\n"+"id: "+$event_counter.to_s+"\n\n"
                    #$event_counter += 1
                    connection.close
                    connections.delete(connection)
                    #puts "Deleted conenction for " + username + "\n\n"
                    
    
                else
                    #puts "Part message: " + create_event("False", $event_counter)
                    connection << create_event("False", $event_counter-1)
                end
            end
            $event_counter += 1
            for user in $all_users
                if user.instance_variable_get(:@username) == username
                    user.instance_variable_set(:@message_token, message_token_new)
                end
            end
            status 201
            response.headers['Token'] = message_token_new.to_s
            return
        elsif message == "/reconnect"

            time_stamp = Time.now.to_f.to_s
            event = {"event": "Part", "created": time_stamp, "message": "", "users": [], "user": username, "status": ""}
            $events[$event_counter] = event
            puts "Part event created\n"
            connections.each do |connection, user|
                #puts "Part message: " + create_event("False", $event_counter)
                connection << create_event("False", $event_counter)
                if connections[connection] == username
                    connection.close
                    connections.delete(connection)
                end
            end
            for user in $all_users
                if user.instance_variable_get(:@username) == username
                    user.instance_variable_set(:@connection_variable, false)
                    user.instance_variable_set(:@connection_object, nil)
                end
            end
            $event_counter += 1
            for user in $all_users
                if user.instance_variable_get(:@username) == username
                    user.instance_variable_set(:@message_token, message_token_new)
                end
            end
            status 201
            response.headers['Token'] = message_token_new.to_s
            return
        else
            kick_message = message.split(" ")
            if kick_message.length != 2
                status 409
                response.headers['Token'] = message_token_new.to_s
                for user in $all_users
                    if user.instance_variable_get(:@username) == username
                        user.instance_variable_set(:@message_token, message_token_new)
                    end
                end
                return
            end
            kick_username = kick_message[1]

            puts "User asked to kick " + kick_username
            if kick_username == username
                status 409
                response.headers['Token'] = message_token_new.to_s
                for user in $all_users
                    if user.instance_variable_get(:@username) == username
                        user.instance_variable_set(:@message_token, message_token_new)
                    end
                end
                return
            end

            flag = 0
                
            for user in $all_users
                if user.instance_variable_get(:@username) == kick_username
                    flag = 1
                end
            end
            #username not found
            if flag == 0
                status 409
                response.headers['Token'] = message_token_new.to_s
                for user in $all_users
                    if user.instance_variable_get(:@username) == username
                        user.instance_variable_set(:@message_token, message_token_new)
                    end
                end
                return
            end

                
            time_stamp = Time.now.to_f.to_s
            event = {"event": "Part", "created": time_stamp, "message": "", "users": [], "user": kick_username, "status": ""}
            $events[$event_counter] = event
            puts "Part event created\n"
            
            connections.each do |connection, user|
                puts "Part message: " + create_event("False", $event_counter)
                connection << create_event("False", $event_counter)
                if connections[connection] == kick_username
                    connection.close
                    connections.delete(connection)

                end
            end

            for user in $all_users
                if user.instance_variable_get(:@username) == kick_username
                    user.instance_variable_set(:@connection_variable, false)
                    user.instance_variable_set(:@connection_object, nil)
                end
            end
            
            $event_counter += 1
            for user in $all_users
                if user.instance_variable_get(:@username) == username
                    user.instance_variable_set(:@message_token, message_token_new)
                end
            end
            status 201
            response.headers['Token'] = message_token_new.to_s
            return
        end
        
    else
        time_stamp = Time.now.to_f.to_s
        event = {"event": "Message", "created": time_stamp, "message": message, "users": [], "user": username, "status": ""}
        $events[$event_counter] = event
    
        connections.each do |connection, user|
            puts "Message event created for broadcast: " + create_event("False", $event_counter).to_s
            connection << create_event("False", $event_counter)
        end

        $event_counter +=1 
        for user in $all_users
            if user.instance_variable_get(:@username) == username
                user.instance_variable_set(:@message_token, message_token_new)
            end
        end
    end    
    status 201
    response.headers['Token'] = message_token_new.to_s
    return
    #[201, {"message_token": message_token, "stream_token":stream_token}.to_json]

end
