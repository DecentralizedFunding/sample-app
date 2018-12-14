<template>
  <div class="app">
    <h2>My page</h2>
    <b-img :src="`${db.image}`" width="96" height="96" blank-color="#bbb" fluid alt="Icon" />
    <p>user: {{ db.userName }}</p>
    <b-button v-show="!isEmailVerified" @click="reSendEmailVerification" variant="warning">Resend verification Email</b-button>
    <div class="project-box" v-for="project in projects" :key="project.id">
      <b-card tag="article">
        <h4>{{ project.title }}</h4>
        <b-progress :value="project.funded" :max="project.goal" show-progress animated></b-progress>
        <p>GOAL {{ project.goal }} ETH</p>
        <p v-if="project.left.days > 1">{{ project.left.days }} days left</p>
        <p v-else-if="project.left.hours > 1">{{ project.left.hours }} hours left</p>
        <p v-else-if="project.left.mitunes >= 0">{{ project.left.mitunes }} minutes left</p>
        <p v-else-if="project.left.minutes < 0">Ended</p>
        <div v-show="project.left.minutes < 0">
          <b-button v-if="isSuccess(project)" @click="withdraw(project.id)">Withdraw</b-button>
          <b-button v-else @click="refund(project.id)">Refund</b-button>
        </div>
      </b-card>
    </div>
  </div>
</template>

<script>
/* eslint-disable */
import Web3 from 'web3'
import contract from 'truffle-contract'
import artifacts from '../../build/contracts/DFcore.json'

import firebase from 'firebase'
import { db, storage } from '../firebaseInit'

var DFcore = contract(artifacts)

var storageRef = storage.ref()

export default {
  name: 'User',
  data () {
    return {
      isEmailVerified: true,
      projects: [],
      user: null,
      db: {
        image: null,
        userName: null
      }
    }
  },
  beforeCreate () {
    firebase.auth().onAuthStateChanged((user) => {
      if (!user) {
        this.$router.replace({ name: 'Login' })
      }
    })
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

    new Promise((resolve, reject) => {
      firebase.auth().onAuthStateChanged((user) => {
        this.user = user
        resolve(user.emailVerified)
      })
    })
    .then((isVerified) => {
      this.isEmailVerified = isVerified
      this.db.image = this.user.photoURL
      return db.collection('users').where('name', '==', this.user.displayName).get()
    })
    .then((querySnapshot) => {
      if (!querySnapshot.empty) {
        querySnapshot.forEach((doc) => {
          this.db.userName = doc.data().name
        })
      } else {
        throw new Error('No such document.')
      }
    })
    .catch(console.error)
  },
  beforeMount () {
    var contract
    var projectLength
    DFcore.deployed()
      .then((instance) => {
        contract = instance
        return contract.getPJByOwner(this.account)
      })
      .then((list) => {
        var promises = []
        list.forEach((id) => {
          promises.push(contract.getPJInfo(id.toNumber()))
        })
        projectLength = promises.length
        return Promise.all(promises)
      })
      .then((projects) => {
        for (var i = 0; i < projectLength; i++) {
          // 1e21 対策
          var goal = web3.utils.fromWei(web3.utils.toBN(projects[i][2]), 'ether')
          var funded = web3.utils.fromWei(web3.utils.toBN(projects[i][3]), 'ether')
          var unixTime = projects[i][4].toNumber()
          var date = new Date(unixTime)
          var left = unixTime - Date.now()

          this.projects.unshift({
            'id': projects[i][0].toNumber(),
            'title': projects[i][1],
            'goal': Number(goal),
            'funded': Number(funded),
            'limitTime': date.toLocaleDateString('ja-JP'),
            'supporters': projects[i][5],
            'left': {
              'days': Math.floor(left / (24 * 60 * 60 * 1000)),
              'hours': Math.floor(left / (60 * 60 * 1000)),
              'minutes': Math.floor(left / (60 * 1000))
            }
          })
        }
      })
  },
  methods: {
    isSuccess (project) {
      return project.funded >= project.goal ? true : false
    },
    refund (id) {
      DFcore.deployed()
        .then((instance) => {
          instance.failure_withdraw(id)
        })
    },
    reSendEmailVerification () {
      firebase.auth().onAuthStateChanged((user) => {
        user.sendEmailVerification()
          .catch(console.error)
      })
    },
    withdraw (id) {
      DFcore.deployed()
        .then((instance) => {
          instance.success_withdraw(id)
        })
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
