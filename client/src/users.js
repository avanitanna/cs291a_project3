import {Component} from 'react'
import App from "./App";
import styles from './App.css';

class Users extends Component {
    constructor(props) {
        super(props)
        console.log("USERS CONSTRUCTION")
    }
    render() {
        var messages = this.props.users.map(u=>u)


        return (
            <div id="user_list_style">
                <h3> User List</h3>
                <ul>
                    {messages}
                </ul>
            </div>
        )
    }
}

export default Users;