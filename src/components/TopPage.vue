<template>
  <div class="app">
    <div class="carousel mb-2">
      <b-carousel id="carousel" background="#bbb" v-model="slide" @sliding-start="onSlideStart" @sliding-end="onSlideEnd">
        <b-carousel-slide caption="Decentralized" text="on Ethereum Network" img-src="https://placeimg.com/420/280/arch"></b-carousel-slide>
        <b-carousel-slide caption="Funding" text="on Ethereum Network" img-src="https://placeimg.com/420/280/nature"></b-carousel-slide>
      </b-carousel>
    </div>
    <div class="project-box" v-for="project in projects" :key="project.id">
      <b-link :to="{ name: 'Project', params: { projectId: project.id }}">
        <b-card class="my-3" :img-src="`${project.image}`" img-alt="Image" img-top tag="article">
          <h2 class="h4">{{ project.title }}</h2>
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

import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'

import firebase from 'firebase'
import { db, storage } from '../firebaseInit'

var DFcore = contract(artifacts)

var storageRef = storage.ref()

export default {
  name: 'TopPage',
  data () {
    return {
      contractAddress: null,
      projects: [],
      isLoggedIn: false,
      slide: 0,
      sliding: null
    }
  },
  beforeCreate () {
    firebase.auth().onAuthStateChanged((user) => {
      if (user) {
        this.isLoggedIn = true
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

/*
    web3.eth.getAccounts()
      .then((accounts) => this.account = accounts[0])
      .catch(console.log)

    web3.currentProvider.publicConfigStore.on('update', (info) => {
      this.account = info.selectedAddress
    })

    DFcore.deployed()
      .then((instance) => this.contractAddress = instance.address)*/
  },
  beforeMount () {
    var contract
    var projectLength
    var urls
    DFcore.deployed()
      .then((instance) => {
        contract = instance
        return contract.getPJCount()
      })
      .then((count) => {
        projectLength = count.toNumber()
        var promises = []
        for (var i = 0; i < projectLength; i++) {
          promises.push(storageRef.child(`images/projects/${i}`).getDownloadURL())
        }
        return Promise.all(promises)
      })
      .then((response) => {
        urls = response
      })
      .then((count) => {
        var promises = []
        for (var i = 0; i < projectLength; i++) {
          promises.push(contract.getPJInfo(i))
        }
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
            'image': urls[i],
            'title': projects[i][1],
            'goal': Number(goal),
            'funded': Number(funded),
            'percent': Number(funded) / Number(goal) * 100,
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
    onSlideStart (slide) {
      this.sliding = true
    },
    onSlideEnd (slide) {
      this.sliding = false
    },
    signOut () {
      firebase.auth().signOut()
        .then(() => location.reload())
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.address {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.carousel {
  margin-left: -8px;
  margin-right: -8px;
  text-shadow: 1px 1px 2px #333;
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
  font-size: 1rem;
}

.progress {
  height: 0.5rem;
}

.project-box a, .project-box *:hover {
  color: inherit;
  text-decoration: none;
}

ul {
  padding-left: 0;
}
</style>
