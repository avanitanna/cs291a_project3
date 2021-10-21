import {Component} from 'react'
import App from "./App";


class Messages extends Component {
    constructor(props) {
        super(props)
        console.log("messages CONSTRUCTION")
    }
    render() {


        return (
            <div id="message_list_style">
                <ul>
                    {[this.props.messages]}
                </ul>
            </div>
        )
    }
}

export default Messages;