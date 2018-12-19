<template>
  <div class="app">
    <b-container class="profile py-3">
      <b-row class="justify-content-center mt-5 mb-3">
        <b-img rounded="circle" :src="`${db.image}`" width="96" height="96" alt="Icon" />
      </b-row>
      <b-row class="justify-content-center" align-v="center">
        @{{ userName }}
      </b-row>
      <b-row class="justify-content-center">
        <span class="address">
          {{ this.$route.params.address }}
        </span>
      </b-row>
    </b-container>
    <b-alert class="my-2" show variant="primary">
      <p class="font-weight-bold mb-0">Authenticated Account.</p>
      Twitter: <b-link :href="`https://twitter.com/${twitter}`">@{{ twitter }}</b-link>
    </b-alert>
    <h2 class="h4 pt-4 pb-2">Projects</h2>
    <div class="project-box" v-for="project in projects" :key="project.id">
      <b-link :to="{ name: 'Project', params: { projectId: project.id }}">
        <b-card class="my-2" tag="article">
          <h3 class="h4">{{ project.title }}</h3>
          <b-row align-v="center">
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
        </b-card>
      </b-link>
    </div>
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

var storageRef = storage.ref()

export default {
  name: 'User',
  data () {
    return {
      projects: [],
      twitter: null,
      userName: null,
      credientialinfo: [],
      db: {
        address: null,
        image: require('../assets/user.jpg'),
        userName: null
      }
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

    db.collection('users').where('lowerCaseAddress', '==', this.$route.params.address)
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
        return storageRef.child(`images/users/${this.userName}`).getDownloadURL()
      })
      .then((url) => {
        this.db.image = url
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
            'percent': Math.floor(Number(funded) / Number(goal) * 100),
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
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
article:hover {
  box-shadow: 0 0 2px 0 #007bff;
}

.address {
  overflow: hidden;
  text-overflow: ellipsis;
  width: 192px;
  white-space: nowrap;
}

.profile {
  background-color: #ccc;
  height: 256px;
  margin-left: -15px;
  margin-right: -15px;
  width: initial;
}

.profile_image {
  border-radius: 50%;
}

.project-box {
  border: none;
}

.project-box a, .project-box *:hover {
  color: inherit;
  text-decoration: none;
}

.project-box #title {
  font-weight: bold;
}
</style>
