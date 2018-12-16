<template>
  <div class="app">
    <b-card class="mt-4">
      <h2 class="h3">Log in</h2>
      <b-form inline class="mt-3 mb-3">
        <b-form-input class="my-2" v-model="email" type="email" placeholder="Email" required></b-form-input>
        <b-form-input class="my-2" v-model="password" type="password" placeholder="Password" required></b-form-input>
        <b-link :to="{ name: 'ResetPassword' }">Forgot password?</b-link>
        <b-button class="container my-4" @click="logIn" variant="primary">Log in</b-button>
      </b-form>
      <div class="line"></div>
      <b-row class="mt-4 justify-content-center">
        New to Decentralized Funding?
      </b-row>
      <b-row class="mt-2 mb-4 justify-content-center">
        <b-link :to="{ name: 'SignUp' }">Sign Up!</b-link>
      </b-row>
    </b-card>
    <b-alert v-show="loginErrorMessage" show variant="danger">
      {{ loginErrorMessage }}
    </b-alert>
  </div>
</template>

<script>
/* eslint-disable */
import Web3 from 'web3'
import contract from 'truffle-contract'
import artifacts from '../../build/contracts/DFcore.json'

import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'

import firebase from 'firebase'
import db from '../firebaseInit'

var DFcore = contract(artifacts)

export default {
  name: 'Login',
  data () {
    return {
      email: null,
      password: null,
      loginErrorMessage: null
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

    DFcore.setProvider(web3.currentProvider)

    web3.eth.getCoinbase()
      .then((coinbase) => DFcore.defaults({from: coinbase}))

    web3.eth.getAccounts()
      .then((accounts) => this.account = accounts[0])
      .catch(console.log)

    DFcore.deployed()
      .then((instance) => this.contractAddress = instance.address)
  },
  methods: {
    logIn () {
      firebase.auth().signInWithEmailAndPassword(this.email, this.password)
        .then((info) => this.$router.replace({ name: 'MyPage' }))
        .catch((error) => {
          switch (error.code) {
            case 'auth/invalid-email':
              this.loginErrorMessage = 'メールアドレスが誤っています'
              break
            case 'auth/user-disabled':
              this.loginErrorMessage = 'ユーザーは凍結されています'
              break
            case 'auth/user-not-found':
              this.loginErrorMessage = 'ユーザーが見つかりません'
              break
            case 'auth/wrong-password':
              this.loginErrorMessage = 'パスワードが誤っています'
              break
          }
        })
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
