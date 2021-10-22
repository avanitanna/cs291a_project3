import {Component} from 'react'
import App from "./App";
import styles from './App.css';

class Messages extends Component {
    constructor(props) {
        super(props)
        console.log("messages CONSTRUCTION")
        console.log(this.props.messages)
    }
    render() {
        //var message = this.props.messages.map(u=>u)
        return (

            <div id="chat_box_style">
                <h3> Message List</h3>
                <ul id="messages">
                    {this.props.messages}

                </ul>
            </div>
        )
    }
}

export default Messages;