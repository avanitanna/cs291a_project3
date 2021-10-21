import { Component } from "react";
import "./App.css";
import LoginModal from './LoginModal'
import Users from "./users";
import Messages from "./messages"
import Compose from "./Compose"

class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      message_token: "",
      stream_token: "",
      path: "",
      server: null,
      messages: [],
      connected: false,
      users: [],
      Logged: false
    }


  }

  updateMessageToken = message_token => {
    this.setState({message_token: message_token})
  }

  updateStreamToken = stream_token => {
    this.setState({stream_token: stream_token})
  }

  updateLoggedState = value => {
    this.setState({Logged: value})
    if (value){
      this.startStream()
    }
    console.log("CALLINGG")
  }

  updateServer = server => {
    this.setState({server: server})
  }

  updatePath = path => {
    this.setState({path: path})
  }


  date_format = timestamp => {
    var date = new Date(timestamp * 1000)
    return (
        date.toLocaleDateString('en-US') + ' ' + date.toLocaleTimeString('en-US')
    )
  }

  startStream = () => {
    this.server = new EventSource(
        this.state.path + 'stream/' + this.state.stream_token
    )

    this.server.addEventListener(
        'Users',
        event => {
          console.log("USERS EVEnt")
          let data = JSON.parse(event.data)
          this.setState({
            users: Array.from(new Set (this.state.users.concat(data.users))).map(u => <li>{u}</li>)
          })
        },
        false
    )

    this.server.addEventListener(
        'Join',
        event => {
          console.log("USERS EVEnt")
          let data1 = JSON.parse(event.data)
          //let data = event.data
          let data2 = "Join: " + data1.user + "\n"

          // Update the set of users
          // Show the message in the history
          this.setState({
            users: Array.from(new Set (this.state.users.concat(data1.user))).map(u => u),
            messages: this.state.messages.concat(data2)
          })
        },
        false
    )

    this.server.addEventListener(
        'Part',
        event => {
          console.log("PART EVENT")
          let data = JSON.parse(event.data)
          let message = event.data.message

          // Update the set of users
          // Show the message in the history
          this.setState({
            users: this.state.users.filter(item => item !== data.user).map(u => u),
            messages: this.state.messages.concat(message)
          })
        },
        false
    )

    this.server.addEventListener(
        'Message',
        event => {
          console.log("Message EVENT")
          let message = event.data
            //let message = event.data.user +" : "+ event.data.message
          // Update the set of users
          // Show the message in the history
          this.setState({
            messages: this.state.messages.concat(message)
          })
        },
        false
    )

    this.server.addEventListener(
        'Disconnect',
        event => {
          //TODO
          console.log("Message EVENT")
          let message = event.data

          // Update the set of users
          // Show the message in the history
          this.setState({
            messages: [],
            message_token: "",
            stream_token: "",
            path: "",
            Logged: false
          })
          this.server.close()
        },
        false
    )

    this.server.addEventListener(
        'ServerStatus',
        event => {
          //TODO
          console.log("Message EVENT")
          let message = event.data

          // Update the set of users
          // Show the message in the history
          this.setState({
            messages: this.state.messages.concat(message)
          })
        },
        false
    )
  }




  date_format = timestamp => {
    var date = new Date(timestamp * 1000)
    return (
        date.toLocaleDateString('en-US') + ' ' + date.toLocaleTimeString('en-US')
    )
  }

  render() {
    var toRender = ""
    if(this.state.Logged){
      toRender = <><Users users={this.state.users}></Users>
          <Messages messages={this.state.messages}></Messages>
          <Compose changeToken={this.updateMessageToken} token={this.state.message_token}
                   path={this.state.path}></Compose>
      </>;
    } else {
      toRender =         <LoginModal                     updateMessageToken={this.updateMessageToken}
                                                         updateStreamToken={this.updateStreamToken}
                                                         updateServer={this.updateServer}
                                                         updateLoggedState={this.updateLoggedState}
                                                          updatePath={this.updatePath}>
      </LoginModal>
    }
    return (
      <div className="App">
        {toRender}
      </div>
    );
  }
}
export default App;
