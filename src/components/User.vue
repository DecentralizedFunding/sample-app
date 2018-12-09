<template>
  <div class="app">
    <h2>User page</h2>
    <b-link :href="`https://twitter.com/${twitter}`">@{{ twitter }}</b-link>
    <p>user: {{ userName }}</p>
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
import { db, storage } from '../firebaseInit'

var DFcore = contract(artifacts)

export default {
  name: 'User',
  data () {
    return {
      twitter: null,
      userName: null
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


    return db.collection('users').where('name', '==', this.$route.path.split('/').pop())
      .get()
      .then((querySnapshot) => {
        if (!querySnapshot.empty) {
          querySnapshot.forEach((doc) => {
            var data = doc.data()
            this.twitter = data.twitter
            this.userName = data.name
          })
        } else {
          throw new Error('No such document.')
        }
      })
      .catch(console.error)
  },
  methods: {
    reSendEmailVerification () {
      firebase.auth().onAuthStateChanged((user) => {
        user.sendEmailVerification()
          .catch(console.error)
      })
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
