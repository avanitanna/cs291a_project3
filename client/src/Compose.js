import React , {Component} from 'react'

import App from "./App";
import styles from './App.css';

class Componse extends Component {
    constructor(props) {
        super(props)
        console.log("COMPOSE CONSTRUCTION")
        console.log(this.props.message_token)

        this._updateToken = this.props.changeToken.bind(this)
        this.inputReference = React.createRef()
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
                console.log(this.inputReference.current)
                // this.inputReference.current = ''
            } else {
                console.log("Something wrong while sending message")
            }
        }.bind(this)
    }
    render() {
        return (
            <div id="chat_compose_style">
                <label>
                    Send :
                    <input type="text" name="compose" ref ={this.inputReference}
                           onChange={(e) => this.message = e.target.value}
                           onKeyUp={(e) => {
                               if (e.key === 'Enter' || e.keyCode === 13) {
                                   this.sendMessage(this.message)
                                   e.target.value = ''
                               }
                           }}
                    />
                </label>
            </div>
        )
    }
}

export default Componse;