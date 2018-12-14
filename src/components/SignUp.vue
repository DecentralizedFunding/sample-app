<template>
  <div class="app">
    <h2>Login page</h2>
    <b-form class="mx-auto" style="width: 320px;" @submit="onSubmit">
      <b-form-group label="ユーザー名">
        <b-form-input v-model="form.userName" type="text" placeholder="半角英数字" required></b-form-input>
        <b-form-invalid-feedback>このユーザー名はすでに使われています</b-form-invalid-feedback>
      </b-form-group>
      <b-form-group label="Twitterアカウント" description="アカウント認証に使うTwitterアカウントのユーザー名">
        <b-input-group prepend="@">
          <b-form-input v-model="form.twitter" type="text" :readonly="isPost" placeholder="Twitterアカウント" required></b-form-input>
        </b-input-group>
      </b-form-group>
      <b-form-group label="認証用パスワード" description="アカウント認証に使うパスワード">
        <b-input-group>
          <b-form-input class="mr-1" v-model="form.twitterPass" type="password" :readonly="isPost" placeholder="認証用パスワード" required></b-form-input>
          <b-button v-if="isTwitterFormInput" @click="tweet" variant="primary">投稿</b-button>
          <b-button v-else disabled>投稿</b-button>
        </b-input-group>
      </b-form-group>
      <b-form-group label="ウォレットアドレス" description="プロジェクト作成用に登録するウォレットアドレス">
        <b-form-input v-model="form.address" type="text" placeholder="ウォレットアドレス" required></b-form-input>
      </b-form-group>
      <b-form-group label="メールアドレス">
        <b-form-input v-model="form.email" type="email" placeholder="email@example.com" required></b-form-input>
        <b-form-invalid-feedback>このメールアドレスはすでに使われています</b-form-invalid-feedback>
      </b-form-group>
      <b-form-group label="パスワード">
        <b-form-input v-model="form.password" type="password" placeholder="半角英数字6文字以上" required></b-form-input>
      </b-form-group>
      <b-form-group label="パスワード (確認)">
        <b-form-input v-model="form.retypedPassword" type="password" :state="isSamePassword" placeholder="パスワード (確認)" required></b-form-input>
        <b-form-invalid-feedback>パスワードが一致しません</b-form-invalid-feedback>
      </b-form-group>
      <b-alert v-if="errorMessage" show variant="danger">{{ errorMessage }}</b-alert>
      <div v-if="!isSent">
        <b-button v-if="isSamePassword" @click="registerUser" type="submit" variant="primary">登録</b-button>
        <b-button v-else disabled variant="secondary">登録</b-button>
      </div>
    </b-form>
    <b-alert v-if="isSent" show variant="success">
      <p>{{ form.email }} に確認メールを送信しました。</p>
      <p>確認メールのリンクを開いてメールアドレスが有効になったら登録完了です。</p>
    </b-alert>
    <div class="mx-auto" v-if="isSent">
      <b-button @click="reSendEmailVerification">再送信</b-button>
    </div>
    <div class="mx-auto" v-if="isSent">
      <b-link :to="{ name: 'User', params: { address: form.address }}">進む</b-link>
    </div>
  </div>
</template>

<script>
import Web3 from 'web3'

import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
/* eslint-disable */
import firebase from 'firebase'
import { db, storage } from '../firebaseInit'

import { sha256 } from 'js-sha256'

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
      isPost: false,
      isSent: false,
      isVerified: false,
      tweetTime: null
    }
  },
  beforeCreate () {
    // If the user already logged in, redirect user page
    firebase.auth().onAuthStateChanged((user) => {
      if (user) {
        this.$router.replace({ name: 'User', params: {'userId': user.displayName}})
      }
    })
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

      try {
        if (!this.isPost) {
          throw new Error('app/have-no-post')
        }

        var user
        var profileImageRef
        db.collection('users').where('name', '==', this.form.userName)
          .get()
          .then((querySnapshot) => {
            // Check whether username is duplicate or not
            if (!querySnapshot.empty) {
              throw new Error('firestore/username-already-in-use')
            }
            // Connect the server for authentication
            return axios.get('/tweet?user=' + this.form.twitter)
          })
          .then((response) => {
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
            return firebase.auth().createUserWithEmailAndPassword(this.form.email, this.form.password)
          })
          .then(() => {
            user = firebase.auth().currentUser
            return axios.get('/image?user=' + this.form.twitter)
          })
          .then((response) => {
            // Get from Twitter
            var imageUrl = response.data.result.replace('normal', '200x200')
            // Check file extension of profile image
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
            }
            // Create a reference to user's profile image
            profileImageRef = storageRef.child(`images/users/${this.form.userName}.${extension}`)
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
            return user.updateProfile({
              displayName: this.form.userName,
              photoURL: url
            })
          })
          .then(() => {
            return db.collection('users').doc(user.uid).set({
              address: this.form.address,
              name: this.form.userName,
              twitter: this.form.twitter,
              twitterVerified: this.isVerified
            })
          })
          .then(() => {
            return user.sendEmailVerification()
          })
          .then(() => this.isSent = true)
          .catch((error) => {
            if (error.code !== undefined) {
              switch (error.code) {
                case 'auth/email-already-in-use':
                  this.errorMessage = 'このメールアドレスはすでに使われています'
                  break
                case 'auth/invalid-email':
                  this.errorMessage = 'メールアドレスが正しくありません'
                  break
                case 'auth/operation-not-allowed':
                  this.errorMessage = 'この操作は許可されていません'
                  break
                case 'auth/weak-password':
                  this.errorMessage = 'パスワードが弱すぎます'
                  break
                default:
                  this.errorMessage = error
              }
            } else {
              switch (error.message) {
                case 'firestore/username-already-in-use':
                  this.errorMessage = 'このユーザー名はすでに使われています'
                  break
                default:
                  this.errorMessage = error
              }
            }
          })
      } catch (error) {
        switch (error.message) {
          case 'app/have-no-post':
            this.errorMessage = '登録前にTwitterに認証用ツイートを投稿してください'
            break
          case 'app/failed-to-authentication':
            this.errorMessage = 'Twitter認証に失敗しました'
            break
          default:
            this.errorMessage = error
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
      var url = 'https://twitter.com?status=' + message + '%0D%0A%23DecentralizedFunding'
      window.open(url)
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
