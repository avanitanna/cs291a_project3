import {Component} from 'react'
import App from "./App";


class LoginModal extends Component {
    constructor(props) {
        super(props)
        this.state = {
            username: '',
            password: ''
        }
        console.log("Constrcutor LoginModal")
        this.server = ''
        this.username = ''
        this.password = ''

        this.updateMToken = this.props.updateMessageToken.bind(this)
        this.updateSToken = this.props.updateStreamToken.bind(this)
        this.updateLState = this.props.updateLoggedState.bind(this)
        this._updatePath = this.props.updatePath.bind(this)
    }

    _updatePath = (path) => {
        this.props.updatePath()
    }

    updateMToken = (mtoken) => {
        console.log("updateMToken")
        this.props.updateMessageToken(mtoken)
    }

    updateSToken = (stoken) => {
        console.log("updateSToken")
        this.props.updateMessageToken(stoken)
    }

    updateLState = (logged) => {
        console.log("updateLState")
        this.props.updateLoggedState(logged)
    }



    submit = (path, username, password) => {
        if (
            path === null ||
            path === undefined ||
            path.length < 1 ||
            username === null ||
            username === undefined ||
            username.length < 1 ||
            password === null ||
            password === undefined ||
            password.length < 1
        ) {this.updateLState(false)}

        var xhr = new XMLHttpRequest();
        xhr.open("POST", path+'/login', true);

        //Send the proper header information along with the request
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

        xhr.onreadystatechange = (e) =>{ // Call a function when the state changes.
            if (e.currentTarget.readyState != 4) return;
            if (e.currentTarget.status === 201) {
                // Request finished. Do processing here.
                const data = JSON.parse(e.currentTarget.responseText);
                let messageToken = data.message_token;
                let streamToken = data.stream_token;
                console.log("Looking good")
                this._updatePath(path)
                this.updateSToken(streamToken)
                this.updateMToken(messageToken)
                this.updateLState(true)
            }
        }//.bind(this)
        xhr.send("username="+username+"&password="+password);
        console.log(this.server,this.username,this.password)

    }

    render() {
        return (
            <div>
                    <label>
                        Server:
                        <input type="text" name="server" onChange={(e) => this.server = e.target.value}/>
                    </label>

                    <label>
                        username:
                        <input type="text" name="username"onChange={(e) => this.username = e.target.value} />
                    </label>

                    <label>
                        password:
                        <input type="text" name="password" onChange={(e) => this.password = e.target.value} />
                    </label>
                    <input type="submit" value="Submit" onClick={(e)=>this.submit(this.server, this.username, this.password)}/>
            </div>
        )
    }
}

export default LoginModal;