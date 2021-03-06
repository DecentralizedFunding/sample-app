<template>
  <div class="app">
    <b-container class="profile py-3">
      <b-row class="justify-content-center mt-5 mb-3">
        <b-img rounded="circle" :src="`${db.image}`" width="96" height="96" alt="Icon" />
      </b-row>
      <b-row class="justify-content-center">
        @{{ db.userName }}
      </b-row>
      <b-row class="justify-content-center">
        <span class="address" id="address">
          {{ db.address }}
        </span>
        <b-link class="text-dark" @click="copyAddress" v-b-popover="'Copy!'">
          <i class="fas fa-copy"></i>
        </b-link>
      </b-row>
      <b-badge variant="light" :href="`https://twitter.com/${ db.twitter }`">
        <span style="color: #1da1f2;"><i class="fab fa-twitter"></i></span>&nbsp;{{ db.twitter }}
      </b-badge>
    </b-container>
    <b-alert class="my-2" v-show="!isEmailVerified" show variant="warning">
      Please verify your Email address first.
      <b-button class="mt-1" @click="reSendEmailVerification" variant="warning">Resend verification Email</b-button>
    </b-alert>
    <h2 class="h4 pt-4 pb-2">Your projects</h2>
    <p v-if="projects.length === 0">No Project</p>
    <div v-else class="project-box" v-for="project in projects" :key="project.id">
      <b-card class="my-2" tag="article">
        <b-link :to="{ name: 'Project', params: {projectId: project.id }}">
          <h3 class="h4">{{ project.title }}</h3>
          <b-row v-show="project.active" align-v="center">
            <b-col>
              <b-progress class="mb-1" :value="project.funded" :max="project.goal"></b-progress>
            </b-col>
            <b-col class="percent pl-0" cols="auto">{{ project.percent }}%</b-col>
          </b-row>
          <b-row align-h="between">
            <b-col>
              <i class="fas fa-flag-checkered"></i>
              {{ project.goal }} ETH
            </b-col>
            <b-col cols="auto" v-if="project.left.days > 1">
              <i class="far fa-clock"></i>
              {{ project.left.days }} days left
            </b-col>
            <b-col cols="auto" v-else-if="project.left.hours > 1">
              <i class="far fa-clock"></i>
              {{ project.left.hours }} hours left
            </b-col>
            <b-col cols="auto" v-else-if="project.left.mitunes >= 0">
              <i class="far fa-clock"></i>
              {{ project.left.mitunes }} mitunes left
            </b-col>
            <b-col cols="auto" v-else-if="project.left.minutes < 0">Ended</b-col>
          </b-row>
        </b-link>
        <b-button class="mt-2 w-100" v-show="isSuccess(project)" @click="withdraw(project.id)" variant="outline-success">Withdraw</b-button>
        <b-button class="mt-2 w-100" v-show="project.left.minutes < 0 && !isSuccess(project)" @click="refund(project.id)" variant="outline-warning">Refund</b-button>
      </b-card>
    </div>
    <b-row class="mt-4 justify-content-center">
      <b-button @click="signOut" class="btn-outline-secondary">Log Out</b-button>
    </b-row>
    <b-link class="create-button bg-primary text-white d-flex justify-content-center align-items-center fixed-bottom mr-3 mb-3" :to="{ name: 'StartProject' }">
      <i class="fas fa-plus fa-lg"></i>
    </b-link>
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
        address: null,
        image: require('../assets/user.jpg'),
        twitter: null,
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
          this.db.twitter = doc.data().twitter
          this.db.address = doc.data().address
        })
      } else {
        throw new Error('No such document.')
      }

      this.getCreatedProject()
    })
    .catch(console.error)
  },
  methods: {
    copyAddress () {
      var tmpArea = document.createElement('textarea')
      tmpArea.value = this.db.address
      document.body.appendChild(tmpArea)
      tmpArea.select()
      document.execCommand('copy')
      tmpArea.remove()
    },
    getCreatedProject () {
      var contract
      var projectLength
      var projects
      DFcore.deployed()
        .then((instance) => {
          contract = instance
          return contract.getPJByOwner(this.db.address)
        })
        .then((list) => {
          var promises = []
          list.forEach((id) => {
            promises.push(contract.getPJInfo(id.toNumber()))
          })
          projectLength = promises.length
          return Promise.all(promises)
        })
        .then((results) => {
          projects = results
          var promises = []
          for (var i = 0; i < projectLength; i++) {
            promises.push(contract.isPJActive(i))
          }
          return Promise.all(promises)
        })
        .then((statuses) => {
          for (var i = 0; i < projectLength; i++) {
            // 1e21 対策
            var goal = web3.utils.fromWei(web3.utils.toBN(projects[i][2]), 'ether')
            var funded = web3.utils.fromWei(web3.utils.toBN(projects[i][3]), 'ether')
            var unixTime = projects[i][4].toNumber()
            var date = new Date(unixTime * 1000)
            var left = unixTime * 1000 - Date.now()

            this.projects.unshift({
              'id': projects[i][0].toNumber(),
              'title': projects[i][1],
              'goal': Number(goal),
              'funded': Number(funded),
              'percent': Math.floor(Number(funded) / Number(goal) * 100),
              'limitTime': date.toLocaleDateString('ja-JP'),
              'supporters': projects[i][5],
              'active': statuses[i],
              'left': {
                'days': Math.floor(left / (24 * 60 * 60 * 1000)),
                'hours': Math.floor(left / (60 * 60 * 1000)),
                'minutes': Math.floor(left / (60 * 1000))
              }
            })
          }
        })
        .catch(console.error)
    },
    isSuccess (project) {
      return project.funded >= project.goal ? true : false
    },
    refund (id) {
      DFcore.deployed()
        .then((instance) => {
          instance.failure_withdraw(id, {gas: 300000})
        })
    },
    reSendEmailVerification () {
      firebase.auth().onAuthStateChanged((user) => {
        user.sendEmailVerification()
          .catch(console.error)
      })
    },
    signOut () {
      firebase.auth().signOut()
        .then(() => window.location.replace('http://localhost:8080'))
    },
    withdraw (id) {
      DFcore.deployed()
        .then((instance) => {
          instance.success_withdraw(id, {gas: 300000})
        })
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.address {
  overflow: hidden;
  text-overflow: ellipsis;
  width: 192px;
  white-space: nowrap;
}

.create-button {
  border-radius: 50%;
  height: 48px;
  left:inherit;
  width: 48px;
}

.create-button:hover {
  text-decoration: none;
}

.percent {
  font-size: 0.9rem;
  width: 68px;
}

.profile {
  background-color: #ccc;
  height: 256px;
  margin-left: -15px;
  margin-right: -15px;
  width: initial;
}

.project-box a, .project-box *:hover {
  color: inherit;
  text-decoration: none;
}

.progress {
  height: 0.5rem;
}
</style>
