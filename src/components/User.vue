<template>
  <div class="app">
    <h2>User Page</h2>
    <b-link :href="`https://twitter.com/${twitter}`">@{{ twitter }}</b-link>
    <p>user: {{ userName }}</p>
    <div class="project-box" v-for="project in projects" :key="project.id">
      <router-link :to="{ name: 'Project', params: { projectId: project.id }}">
        <b-card tag="article">
          <h4>{{ project.title }}</h4>
          <p>目標金額 {{ project.goal }} ETH</p>
          <b-progress :value="project.funded" :max="project.goal" show-progress animated></b-progress>
          <p v-if="project.left.days > 0">残り {{ project.left.days }} 日</p>
          <p v-else-if="project.left.hours > 0">残り {{ project.left.hours }} 時間</p>
          <p v-else-if="project.left.mitunes >= 0">残り {{ project.left.mitunes }} 分</p>
          <p v-else-if="project.left.minutes < 0">終了</p>
        </b-card>
      </router-link>
    </div>
    <div>
      <p>ここでERC721参照テストをしたい</p>
    </div>
    <b-link :to="{ name: 'TopPage' }">トップへ戻る</b-link>
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
      projects: [],
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

    db.collection('users').where('address', '==', this.$route.params.address)
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
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
article, .project-box {
  width: 320px;
}

article:hover {
  box-shadow: 0 0 2px 0 #007bff;
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
