<template>
  <div class="app">
    <b-card class="mt-4">
      <b-row class="mb-3 justify-content-center">
        Have an account?&nbsp;
        <b-link :to="{ name: 'Login' }">Log in</b-link>
      </b-row>
      <div class="line"></div>
      <h2 class="h3 my-4">Sign Up</h2>
      <b-form @submit="onSubmit">
        <b-form-group label="Username">
          <b-form-input v-model="form.userName" type="text" placeholder="Username" required></b-form-input>
          <b-form-invalid-feedback>This username is already taken.</b-form-invalid-feedback>
        </b-form-group>
        <b-form-group label="Twitter account" description="Twitter account to use verification">
          <b-input-group prepend="@">
            <b-form-input v-model="form.twitter" type="text" :readonly="isPost" placeholder="Username" required></b-form-input>
          </b-input-group>
        </b-form-group>
        <b-form-group label="One-time password" description="One-time password to use verification with Twitter">
          <b-input-group>
            <b-form-input class="mr-1" v-model="form.twitterPass" type="password" :readonly="isPost" placeholder="One-time Password" required></b-form-input>
            <b-button v-if="isTwitterFormInput" @click="tweet" variant="primary">Post</b-button>
            <b-button v-else disabled>Post</b-button>
          </b-input-group>
        </b-form-group>
        <b-form-group label="Wallet address" description="Wallet address to use start your project">
          <b-form-input v-model="form.address" type="text" placeholder="Wallet address" required></b-form-input>
        </b-form-group>
        <b-form-group label="Email">
          <b-form-input v-model="form.email" type="email" placeholder="email@example.com" required></b-form-input>
          <b-form-invalid-feedback>This email address is already in use.</b-form-invalid-feedback>
        </b-form-group>
        <b-form-group label="Password">
          <b-form-input v-model="form.password" type="password" placeholder="Password (6 or more characters)" required></b-form-input>
        </b-form-group>
        <b-form-group label="Re-enter password">
          <b-form-input v-model="form.retypedPassword" type="password" :state="isSamePassword" placeholder="Confirm" required></b-form-input>
          <b-form-invalid-feedback>Re-enter password is not correct.</b-form-invalid-feedback>
        </b-form-group>
        <b-alert class="my-2" v-if="errorMessage" show variant="danger">{{ errorMessage }}</b-alert>
        <b-row class="my-2 justify-content-center" v-show="isLoading">
          <atom-spinner :animation-duration="1000" :size="60" :color="'#007bff'" />
        </b-row>
        <div class="mt-4 mb-2" v-if="!isSent">
          <b-button class="w-100" v-if="isSamePassword" @click="registerUser" type="submit" variant="primary">Register</b-button>
          <b-button class="w-100" v-else disabled variant="secondary">Register</b-button>
        </div>
      </b-form>
    </b-card>
    <b-alert class="my-2" style="overflow: hidden; text-overflow: ellipsis;" v-if="isSent" show variant="success">
      We send the mail to {{ form.email }}
    </b-alert>
    <b-alert class="my-2" v-if="isSent" show variant="info">
      <p>If you cannot receive the email, we send it again.</p>
      <b-button @click="reSendEmailVerification" variant="info">Re-send</b-button>
    </b-alert>
    <b-row class="mt-4 justify-content-center" v-if="isSent">
      <b-button :to="{ name: 'MyPage' }" variant="primary">Continue</b-button>
    </b-row>
  </div>
</template>

<script>
/* eslint-disable */
import Web3 from 'web3'
import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
import firebase from 'firebase'
import { db, storage } from '../firebaseInit'
import { sha256 } from 'js-sha256'
import { AtomSpinner } from 'epic-spinners'

var axiosBase = require('axios')
var axios = axiosBase.create({
  baseURL: 'https://auth-for-df.herokuapp.com',
  header: {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  responseType: 'json'
})

var storageRef = storage.ref()

export default {
  name: 'SignUp',
  data () {
    return {
      errorMessage: null,
      form: {
        address: null,
        email: null,
        password: null,
        retypedPassword: null,
        twitter: '',
        twitterPass: '',
        userName: null,
      },
      isDuplicate: false,
      isLoading: false,
      isPost: false,
      isSent: false,
      isVerified: false,
      tweetTime: null
    }
  },
  components: {
    AtomSpinner
  },
  computed: {
    isSamePassword () {
      return this.form.retypedPassword === null ? null : this.form.password === this.form.retypedPassword ? true : false
    },
    isTwitterFormInput () {
      return (this.form.twitter !== '' && this.form.twitterPass !== '') ? true : false
    }
  },
  created () {
    if (typeof web3 !== 'undefined') {
      web3 = new Web3(web3.currentProvider)
    } else {
      console.warn("No web3 detected. Falling back to http://127.0.0.1:7545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask")

      // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
      web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:7545'))
    }

    web3.eth.getAccounts()
      .then((accounts) => this.form.address = accounts[0])
      .catch(console.log)
  },
  methods: {
    onSubmit (event) {
      event.preventDefault()
    },
    registerUser () {
      // Hide previous error message
      this.errorMessage = null
      this.isLoading = true

      try {
        if (!this.isPost) {
          throw new Error('app/have-no-post')
        }

        var user
        var originalImage
        var profileImageRef
        db.collection('users').where('name', '==', this.form.userName).get()
          .then((querySnapshot) => {
            // Check whether username is duplicate or not
            if (!querySnapshot.empty) {
              throw new Error('firestore/username-already-in-use')
            }
            return db.collection('users').where('twitter', '==', this.form.twitter).get()
          })
          .then((querySnapshot) => {
            if (!querySnapshot.empty) {
              this.isPost = false
              throw new Error('firestore/twitter-account-already-registered')
            }
            // Connect the server for authentication
            return axios.get('/tweet?user=' + this.form.twitter)
          })
          .then((response) => {
            // twitter account is not public
            /*
            if (response.data.result) {
              throw new Error('twitter/account-not-public')
            }
            */
            var expectedHash = sha256(this.form.twitter + this.form.twitterPass + this.tweetTime)
            var returnedHash = response.data.result.substring(0, 64)
            // If returned hash and expected hash is equal, return true
            if (expectedHash === returnedHash) {
              return true
            } else {
              throw new Error('app/failed-to-authentication')
            }
          })
          .then((result) => {
            this.isVerified = result
            return axios.get('/image?user=' + this.form.twitter)
          })
          .then((response) => {
            // Get from Twitter
            originalImage = response.data.result
            return firebase.auth().createUserWithEmailAndPassword(this.form.email, this.form.password)
          })
          .then(() => {
            var imageUrl = originalImage.replace('normal', '200x200')
            // Check file extension of profile image
            /*
            var extension
            if (imageUrl.search('\.jpg') !== -1) {
              extension = 'jpg'
            } else if (imageUrl.search('\.jpeg') !== -1) {
              extension = 'jpeg'
            } else if (imageUrl.search('\.png') !== -1) {
              extension = 'png'
            } else if (imageUrl.search('\.gif') !== -1) {
              extension = 'gif'
            } else {
              throw new Error('app/unknown-file-extension')
            }*/
            // Create a reference to user's profile image
            profileImageRef = storageRef.child(`images/users/${this.form.userName}`)
            return fetch(imageUrl)
          })
          .then((response) => {
            return response.blob()
          })
          .then((blob) => {
            return profileImageRef.put(blob)
          })
          .then(() => {
            return profileImageRef.getDownloadURL()
          })
          .then((url) => {
            user = firebase.auth().currentUser
            return user.updateProfile({
              displayName: this.form.userName,
              photoURL: url
            })
          })
          .then(() => {
            return db.collection('users').doc(user.uid).set({
              address: this.form.address,
              lowerCaseAddress: this.form.address.toLowerCase(),
              name: this.form.userName,
              twitter: this.form.twitter,
              twitterVerified: this.isVerified
            })
          })
          .then(() => {
            this.isLoading = false
            return user.sendEmailVerification()
          })
          .then(() => this.isSent = true)
          .catch((error) => {
            this.isLoading = false
            if (error.code !== undefined) {
              switch (error.code) {
                case 'auth/email-already-in-use':
                  this.errorMessage = 'This email address is already in use.'
                  break
                case 'auth/invalid-email':
                  this.errorMessage = 'Email address is invalid.'
                  break
                case 'auth/operation-not-allowed':
                  this.errorMessage = 'This operation is not allowed.'
                  break
                case 'auth/weak-password':
                  this.errorMessage = 'Password is too weak.'
                  break
                default:
                  this.errorMessage = error
                  console.error(error)
              }
            } else {
              switch (error.message) {
                case 'firestore/username-already-in-use':
                  this.errorMessage = 'This username is already taken.'
                  break
                case 'firestore/twitter-account-already-registered':
                  this.errorMessage = 'This twitter account is already registered.'
                  break
                case 'twitter/account-not-public':
                  this.errorMessage = 'Entered twitter account is not public.'
                  break
                default:
                  this.errorMessage = error
                  console.error(error)
              }
            }
          })
      } catch (error) {
        this.isLoading = false
        switch (error.message) {
          case 'app/have-no-post':
            this.errorMessage = 'Post a tweet including hash before registering.'
            break
          case 'app/failed-to-authentication':
            this.errorMessage = 'Failed to authenticate with twitter.'
            break
          default:
            this.errorMessage = error
            console.error(error)
        }
      }
    },
    reSendEmailVerification () {
      firebase.auth().onAuthStateChanged((user) => {
        user.sendEmailVerification()
          .catch(console.error)
      })
    },
    tweet () {
      this.isPost = true
      this.tweetTime = Date.now()
      var message = sha256(this.form.twitter + this.form.twitterPass + this.tweetTime)
      var url = 'https://twitter.com?status=' + message + '%0D%0A%23NextFunding'
      window.open(url)
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.line {
  background-color: #ddd;
  height: 1px;
  text-align: center;
}
</style>
