import {Component} from 'react'
import App from "./App";


class Componse extends Component {
    constructor(props) {
        super(props)
        console.log("COMPOSE CONSTRUCTION")
        console.log(this.props.message_token)

        this._updateToken = this.props.changeToken.bind(this)
    }

    _updateToken = (token) => {
        this.props.updateMessageToken(token)
    }

    sendMessage = message => {
        console.log(message)
        if (!message) return
        var xhr = new XMLHttpRequest();
        xhr.open("POST", this.props.path+'/message', true);
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        xhr.setRequestHeader('Authorization', "Bearer "+this.props.token)
        xhr.send("message="+this.message)

        xhr.onload = function () {
            if (xhr.status ===201){
                let _newToken = xhr.getResponseHeader('Token')
                this._updateToken(_newToken)
            } else {
                console.log("Somethign wrong while sending message")
            }
        }.bind(this)
    }
    render() {
        return (
            <div>
                <label>
                    New message to send:
                    <input type="text" name="compose"
                           onChange={(e) => this.message = e.target.value}
                           onKeyUp={(e) => {
                               if (e.key === 'Enter' || e.keyCode === 13) {
                                   this.sendMessage(this.message)

                               }
                           }}
                    />
                </label>
            </div>
        )
    }
}

export default Componse;